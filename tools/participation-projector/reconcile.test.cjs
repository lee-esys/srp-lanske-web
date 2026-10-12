'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { reconcileEvent, synchronize } = require('./reconcile.cjs');

class FakeFirestore {
  constructor() { this.items = new Map(); this.commits = 0; }
  collection(path) { return { doc: (id) => this.doc(path + '/' + id) }; }
  doc(path) {
    return {
      path,
      collection: (child) => this.collection(path + '/' + child),
      get: async () => ({ data: () => this.items.get(path) }),
    };
  }
  batch() {
    const ops = [];
    return {
      set: (ref, value) => ops.push(() => this.items.set(ref.path, value)),
      delete: (ref) => ops.push(() => this.items.delete(ref.path)),
      commit: async () => { this.commits++; ops.forEach((op) => op()); },
    };
  }
}
const id = '123e4567-e89b-42d3-a456-426614174000';
function plan(mappings) {
  return {
    eventId: id,
    entries: mappings.map((mappingId) => ({
      mappingId, eventId: id,
      data: {
        schemaVersion: 1, eventId: id,
        sourceType: 'tennisbear', sourceUserId: mappingId.split('_')[1],
        eventDate: null,
        selfSnapshot: { sourceDisplayName: 'B', levelId: null, levelName: null },
        statisticsEligible: true, updatedAt: new Date(),
      },
    })),
  };
}
test('dry run does not write data; repeated apply skips unchanged writes', async () => {
  const db = new FakeFirestore();
  const value = plan(['tennisbear_77']);
  await reconcileEvent(db, id, value, false);
  assert.equal(db.items.size, 0);
  assert.equal((await reconcileEvent(db, id, value, true)).written, 1);
  assert.equal(db.commits, 1);
  assert.equal((await reconcileEvent(db, id, value, true)).outcome, 'unchanged');
  assert.equal(db.commits, 1);
});
test('changed participants remove old mapping and write the new mapping', async () => {
  const db = new FakeFirestore();
  await reconcileEvent(db, id, plan(['tennisbear_77']), true);
  const result = await reconcileEvent(db, id, plan(['tennisbear_88']), true);
  assert.equal(result.removed, 1);
  assert.equal(db.items.has('externalIdentityParticipationHistories/tennisbear_77/events/' + id), false);
  assert.equal(db.items.has('externalIdentityParticipationHistories/tennisbear_88/events/' + id), true);
  await reconcileEvent(db, id, plan([]), true);
  assert.equal(db.items.has('externalIdentityParticipationHistories/tennisbear_88/events/' + id), false);
});

test('diagnostics distinguish skipped events from verified candidates', async () => {
  const db = new FakeFirestore();
  const documents = [
    { id: 'MANUAL01', data: () => ({ event: { id: 'manual-01', sourceType: 'manual' } }) },
    { id: 'LEGACY01', data: () => ({
      event: { id: 'legacy-01', sourceType: 'tennisbear', sourceUrl: null },
      players: [{ externalIdentity: null }],
    }) },
  ];
  const originalCollection = db.collection.bind(db);
  db.collection = (path) => path === 'events'
    ? { get: async () => ({ docs: documents }) }
    : path === 'participationProjectionStates'
      ? { ...originalCollection(path), get: async () => ({ docs: [] }) }
      : originalCollection(path);
  const result = await synchronize(db, 'https://unused.example.test', false, {
    log() {}, error() {},
  });
  assert.equal(result.failed, 0);
  assert.equal(result.processed, 2);
  assert.equal(result.diagnostics.scanned, 2);
  assert.equal(result.diagnostics.tennisbearEvents, 1);
  assert.equal(result.diagnostics.nonTennisbearEvents, 1);
  assert.equal(result.diagnostics.invalidSourceEvents, 1);
  assert.equal(result.diagnostics.missingExternalIdentity, 1);
  assert.equal(result.diagnostics.projectionCandidates, 0);
  assert.equal(db.commits, 0);
});

test('single event only is read and no global stale-state sweep runs', async () => {
  const db = new FakeFirestore();
  const selected = {
    id: 'XTR1HOMN',
    exists: true,
    data: () => ({
      event: { id: 'selected-01', sourceType: 'manual' },
      provenance: { lastWrittenFrom: { environment: 'local', appVersion: '0.2.0' } },
    }),
  };
  let globalReads = 0;
  let staleReads = 0;
  const originalCollection = db.collection.bind(db);
  db.collection = (path) => {
    if (path === 'events') return {
      get: async () => { globalReads++; throw new Error('must not scan all events'); },
      doc: (id) => {
        assert.equal(id, 'XTR1HOMN');
        return { get: async () => selected };
      },
    };
    if (path === 'participationProjectionStates') return {
      ...originalCollection(path),
      get: async () => { staleReads++; throw new Error('must not sweep state'); },
    };
    return originalCollection(path);
  };
  const logs = [];
  const result = await synchronize(db, 'https://unused.example.test', false, {
    log: (...args) => logs.push(args.join(' ')),
    error: () => {},
  }, { eventId: 'XTR1HOMN' });
  assert.equal(result.processed, 1);
  assert.equal(result.selectedEventId, 'XTR1HOMN');
  assert.equal(globalReads, 0);
  assert.equal(staleReads, 0);
  assert.equal(db.commits, 0);
  assert.match(logs[0], /environment: local appVersion: 0.2.0/);
});

test('unknown selected event fails rather than silently scanning or deleting', async () => {
  const db = new FakeFirestore();
  const originalCollection = db.collection.bind(db);
  db.collection = (path) => path === 'events' ? {
    doc: () => ({ get: async () => ({ exists: false }) }),
  } : originalCollection(path);
  await assert.rejects(
    synchronize(db, 'https://unused.example.test', false,
      { log() {}, error() {} }, { eventId: 'NOTFOUND' }),
    /Event not found/,
  );
});
