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
