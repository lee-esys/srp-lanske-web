'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { buildProjectionPlan, eventIdentity, parseEventDate } = require('./plan.cjs');
const id = '123e4567-e89b-42d3-a456-426614174000';
const url = 'https://www.tennisbear.net/event/123/info';
const event = () => ({
  event: { id, sourceType: 'tennisbear', sourceUrl: url, statisticsEligible: true },
  importRecord: { sourceType: 'tennisbear', sourceUrl: url },
  players: [{ eventId: id, status: 'active', displayName: 'spoofed',
    externalIdentity: { sourceType: 'tennisbear', sourceUserId: '77' } }],
});
const preview = () => ({
  source_type: 'tennisbear', source_event_id: '123',
  event_candidate: { event_date: '2026-10-08' },
  participant_candidates: [{ user_id: '77', display_name: 'Verified B', level_id: 5 }],
  warnings: [],
});
test('source ID and participant are independently verified; owner display name is ignored', () => {
  const result = buildProjectionPlan(event(), preview());
  assert.equal(result.entries.length, 1);
  assert.equal(result.entries[0].mappingId, 'tennisbear_77');
  assert.equal(result.entries[0].data.selfSnapshot.sourceDisplayName, 'Verified B');
  assert.equal(result.entries[0].data.eventDate.toISOString(), '2026-10-08T03:00:00.000Z');
  assert.deepEqual(Object.keys(result.entries[0].data).sort(), [
    'eventDate','eventId','schemaVersion','selfSnapshot','sourceType',
    'sourceUserId','statisticsEligible','updatedAt',
  ]);
});
test('unverifiable source, missing participation and mismatched event ID fail closed', () => {
  const wrong = event(); wrong.importRecord.sourceUrl = 'https://www.tennisbear.net/event/4/info';
  assert.equal(eventIdentity(wrong), null);
  assert.equal(buildProjectionPlan(wrong, preview()).entries.length, 0);
  const no = preview(); no.participant_candidates = [];
  assert.equal(buildProjectionPlan(event(), no).entries.length, 0);
  const mismatch = preview(); mismatch.source_event_id = '999';
  assert.throws(() => buildProjectionPlan(event(), mismatch), /Unverified/);
});
test('duplicate claimed identities and duplicate source identities do not project', () => {
  const a = event();
  a.players.push({ ...a.players[0] });
  assert.equal(buildProjectionPlan(a, preview()).entries.length, 0);
  const p = preview(); p.participant_candidates.push({ ...p.participant_candidates[0] });
  assert.equal(buildProjectionPlan(event(), p).entries.length, 0);
});
test('missing dates and malformed dates are represented by null', () => {
  assert.equal(parseEventDate(undefined), null);
  assert.equal(parseEventDate('2026-02-30'), null);
  assert.equal(parseEventDate('2026-10-08')?.toISOString(), '2026-10-08T03:00:00.000Z');
});
