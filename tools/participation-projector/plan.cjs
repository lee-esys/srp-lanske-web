'use strict';

// Pure, independently testable validation and projection planning.
// All raw event fields are untrusted, including externalIdentity and sourceUrl.
const EVENT_PATH_PATTERN = /^\/event\/(\d+)\/info\/?$/;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const ID_PATTERN = /^\d{1,20}$/;

function sourceEventId(url) {
  if (typeof url !== 'string' || url.trim() !== url) return null;

  // The shared/calendar URL may include query parameters such as
  // openExternalBrowser=1. They are not part of the event identity.
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }
  if (parsed.protocol !== 'https:' ||
      !['www.tennisbear.net', 'tennisbear.net'].includes(parsed.host) ||
      parsed.username || parsed.password) return null;
  return EVENT_PATH_PATTERN.exec(parsed.pathname)?.[1] ?? null;
}

function eventIdentity(aggregate) {
  const event = aggregate?.event;
  if (!event || typeof event !== 'object' ||
      !UUID_PATTERN.test(event.id ?? '') ||
      event.sourceType !== 'tennisbear') return null;
  const sourceId = sourceEventId(event.sourceUrl);
  if (!sourceId || sourceId !== sourceEventId(aggregate?.importRecord?.sourceUrl) ||
      aggregate.importRecord?.sourceType !== 'tennisbear') return null;
  return { eventId: event.id, sourceId };
}

function verifiedParticipants(preview, expectedEventId) {
  if (!preview || preview.source_type !== 'tennisbear' ||
      String(preview.source_event_id) !== expectedEventId ||
      !Array.isArray(preview.participant_candidates)) {
    throw new Error('Unverified TennisBear event response');
  }
  const warningCodes = (preview.warnings ?? []).map((warning) => warning.code);
  if (warningCodes.includes('participant_display_names_missing')) {
    throw new Error('Incomplete TennisBear participants');
  }

  const verified = new Map();
  const duplicateIds = new Set();
  for (const candidate of preview.participant_candidates) {
    const sourceUserId = String(candidate.user_id ?? '');
    if (!ID_PATTERN.test(sourceUserId)) continue;
    if (verified.has(sourceUserId)) {
      duplicateIds.add(sourceUserId);
      continue;
    }
    verified.set(sourceUserId, candidate);
  }
  for (const id of duplicateIds) verified.delete(id);
  return verified;
}

function parseEventDate(sourceDate) {
  if (typeof sourceDate !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(sourceDate)) {
    return null;
  }
  // 12:00 JST keeps the calendar day stable across browser time zones.
  const date = new Date(sourceDate + 'T12:00:00+09:00');
  return Number.isFinite(date.getTime()) &&
    new Date(date.getTime() + 9 * 3600 * 1000).toISOString().slice(0, 10) === sourceDate
    ? date : null;
}

function buildProjectionPlan(aggregate, preview) {
  const identity = eventIdentity(aggregate);
  if (!identity) return { eventId: aggregate?.event?.id ?? null, entries: [], reason: 'unverifiable_event' };

  const verified = verifiedParticipants(preview, identity.sourceId);
  const players = Array.isArray(aggregate.players) ? aggregate.players : [];
  const occurrences = new Map();
  for (const player of players) {
    const id = player?.externalIdentity?.sourceUserId;
    if (player?.externalIdentity?.sourceType === 'tennisbear' &&
        typeof id === 'string' && ID_PATTERN.test(id)) {
      occurrences.set(id, (occurrences.get(id) ?? 0) + 1);
    }
  }

  const participantCount = players.filter((player) =>
    player?.eventId === identity.eventId && player?.status === 'active').length;
  const isConfirmed = aggregate.event.status === 'adopted';
  const entries = [];
  for (const player of players) {
    const external = player?.externalIdentity;
    const id = external?.sourceUserId;
    if (player?.status !== 'active' || player?.eventId !== identity.eventId ||
        external?.sourceType !== 'tennisbear' ||
        typeof id !== 'string' || occurrences.get(id) !== 1) continue;
    const source = verified.get(id);
    if (!source) continue; // Never rely on owner-controlled display names.
    const name = source.display_name;
    if (typeof name !== 'string' || name.trim().length === 0) continue;

    entries.push({
      mappingId: 'tennisbear_' + id,
      eventId: identity.eventId,
      data: {
        schemaVersion: 1,
        eventId: identity.eventId,
        sourceType: 'tennisbear',
        sourceUserId: id,
        eventDate: parseEventDate(preview.event_candidate?.event_date),
        selfSnapshot: {
          sourceDisplayName: name,
          levelId: Number.isInteger(source.level_id) ? source.level_id : null,
          levelName: typeof source.level_name === 'string' ? source.level_name : null,
          observedAt: new Date(),
        },
        statisticsEligible: aggregate.event.statisticsEligible === true,
        isConfirmed,
        participantCount,
        updatedAt: new Date(),
      },
    });
  }
  return { eventId: identity.eventId, entries, reason: null };
}

module.exports = { sourceEventId, eventIdentity, verifiedParticipants, parseEventDate, buildProjectionPlan };
