'use strict';

// Operator-run trusted reconciler. DRY RUN by default; never called by web clients.
const { createHash } = require('node:crypto');
const { buildProjectionPlan, eventIdentity } = require('./plan.cjs');

const stateCollection = 'participationProjectionStates';
const historyCollection = 'externalIdentityParticipationHistories';

function sourceUrl(aggregate) {
  return eventIdentity(aggregate) ? aggregate.event.sourceUrl : null;
}

async function previewEvent(apiUrl, url) {
  const response = await fetch(apiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ source_url: url }),
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw new Error('TennisBear preview HTTP ' + response.status);
  return response.json();
}

function fingerprint(plan) {
  const canonical = plan.entries.map(({ mappingId, data }) => ({
    mappingId,
    eventId: data.eventId,
    sourceType: data.sourceType,
    sourceUserId: data.sourceUserId,
    eventDate: data.eventDate?.toISOString() ?? null,
    selfSnapshot: {
      sourceDisplayName: data.selfSnapshot.sourceDisplayName,
      levelId: data.selfSnapshot.levelId,
      levelName: data.selfSnapshot.levelName,
    },
    statisticsEligible: data.statisticsEligible,
  })).sort((a, b) => a.mappingId.localeCompare(b.mappingId));
  return createHash('sha256').update(JSON.stringify(canonical)).digest('hex');
}

async function reconcileEvent(db, eventId, plan, apply) {
  const stateRef = db.collection(stateCollection).doc(eventId);
  const oldState = (await stateRef.get()).data() ?? {};
  const prior = Array.isArray(oldState.mappingIds) ? oldState.mappingIds : [];
  const desired = plan.entries.map((entry) => entry.mappingId);
  const digest = fingerprint(plan);
  if (oldState.fingerprint === digest &&
      prior.length === desired.length &&
      prior.every((mappingId) => desired.includes(mappingId))) {
    return { outcome: 'unchanged', written: 0, removed: 0 };
  }
  if (prior.length + desired.length + 1 > 450) {
    throw new Error('Too many projection writes for one event');
  }

  const batch = db.batch();
  const desiredSet = new Set(desired);
  for (const mappingId of prior) {
    if (desiredSet.has(mappingId)) continue;
    batch.delete(db.collection(historyCollection).doc(mappingId).collection('events').doc(eventId));
  }
  for (const { mappingId, data } of plan.entries) {
    const document = db.collection(historyCollection).doc(mappingId).collection('events').doc(eventId);
    batch.set(document, data);
  }
  batch.set(stateRef, {
    mappingIds: desired, fingerprint: digest, syncedAt: new Date(),
  });
  if (apply) await batch.commit();
  return { outcome: apply ? 'synced' : 'dry-run', written: desired.length,
    removed: prior.filter((id) => !desiredSet.has(id)).length };
}

async function synchronize(db, apiUrl, apply, logger = console) {
  const seen = new Set();
  let processed = 0;
  let failed = 0;
  let published = 0;
  let removed = 0;
  const events = await db.collection('events').get();
  const eventIdCounts = new Map();
  for (const eventDoc of events.docs) {
    const id = eventDoc.data()?.event?.id;
    if (typeof id === 'string') {
      eventIdCounts.set(id, (eventIdCounts.get(id) ?? 0) + 1);
    }
  }
  for (const eventDoc of events.docs) {
    const aggregate = eventDoc.data();
    const eventId = aggregate?.event?.id;
    if (typeof eventId !== 'string' || !/^[a-zA-Z0-9-]{8,64}$/.test(eventId)) {
      failed++;
      logger.error('Skipped invalid event ID', eventDoc.id);
      continue;
    }
    if (seen.has(eventId)) continue;
    seen.add(eventId);
    if (eventIdCounts.get(eventId) !== 1) {
      failed++;
      logger.error('Duplicate event identity', eventId);
      try {
        const outcome = await reconcileEvent(db, eventId, { eventId, entries: [] }, apply);
        removed += outcome.removed;
      } catch (cleanupError) {
        logger.error('Duplicate identity cleanup failed', eventId, cleanupError.message);
      }
      continue;
    }
    let plan = { eventId, entries: [] };
    try {
      const url = sourceUrl(aggregate);
      if (url) {
        const preview = await previewEvent(apiUrl, url);
        plan = buildProjectionPlan(aggregate, preview);
      }
      const result = await reconcileEvent(db, eventId, plan, apply);
      processed++;
      published += result.written;
      removed += result.removed;
      logger.log(eventDoc.id, result.outcome, 'write:', result.written, 'delete:', result.removed);
    } catch (err) {
      // An unavailable external source must not lead to a positive verification.
      // Delete previously published event projections as a fail-closed policy.
      failed++;
      logger.error('Verification failed', eventDoc.id, err.message);
      try {
        const outcome = await reconcileEvent(db, eventId, { eventId, entries: [] }, apply);
        removed += outcome.removed;
      } catch (cleanupError) {
        logger.error('Cleanup failed', eventDoc.id, cleanupError.message);
      }
    }
  }
  const oldStates = await db.collection(stateCollection).get();
  for (const state of oldStates.docs) {
    if (seen.has(state.id)) continue;
    try {
      const result = await reconcileEvent(db, state.id, { eventId: state.id, entries: [] }, apply);
      removed += result.removed;
      if (apply) await state.ref.delete();
      logger.log('deleted event', state.id, result.outcome);
    } catch (err) {
      failed++;
      logger.error('Deleted event cleanup failed', state.id, err.message);
    }
  }
  return { processed, failed, published, removed, mode: apply ? 'apply' : 'dry-run' };
}

module.exports = { sourceUrl, previewEvent, fingerprint, reconcileEvent, synchronize };
