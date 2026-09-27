const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { clearFirestoreCollections } = require('./test_environment');

const projectId = 'demo-lanske-rules';
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
  });
});

beforeEach(async () => {
  await clearFirestoreCollections(testEnv);
});

after(async () => {
  if (testEnv != null) {
    await testEnv.cleanup();
  }
});

function anonymousDb(uid) {
  return testEnv
    .authenticatedContext(uid, {
      provider_id: 'anonymous',
      firebase: {
        sign_in_provider: 'anonymous',
        identities: {},
      },
    })
    .firestore();
}

function registeredDb(uid, customClaims = {}) {
  const email = `${uid}@example.test`;
  return testEnv
    .authenticatedContext(uid, {
      ...customClaims,
      email,
      email_verified: true,
      firebase: {
        sign_in_provider: 'password',
        identities: { email: [email] },
      },
    })
    .firestore();
}

function writeOrigin(tag = 'initial') {
  return {
    environment: 'local',
    host: `${tag}.example.test`,
    firebaseProjectId: projectId,
    appVersion: '0.2.0',
  };
}

function createdProvenance() {
  const origin = writeOrigin();
  return {
    createdFrom: { ...origin },
    lastWrittenFrom: { ...origin },
  };
}

function eventData(publicId, ownerUid) {
  const now = '2026-09-27T00:00:00.000Z';
  const eventId = `event-${publicId}`;
  return {
    schemaVersion: 2,
    event: {
      id: eventId,
      publicId,
      ownerUid,
      title: 'Event',
      memo: '',
      eventDate: null,
      startTime: null,
      endTime: null,
      location: null,
      courtCount: 1,
      sourceType: 'manual',
      sourceUrl: null,
      status: 'draft',
      currentGeneratedScheduleId: null,
      adoptedGeneratedScheduleId: null,
      adoptedAt: null,
      visibility: 'unlisted',
      visibleUntilRoundNo: null,
      expiresAt: '2026-10-07T00:00:00.000Z',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    },
    players: [
      {
        id: 'player-1',
        eventId,
        initialDisplayName: 'Player 1',
        displayName: 'Player 1',
        orderNo: 1,
        status: 'active',
        sourceText: null,
        createdAt: now,
        updatedAt: now,
      },
    ],
    share: {
      publicId,
      eventId,
      createdAt: now,
      updatedAt: now,
    },
    importRecord: null,
    revisions: {
      display: 1,
      courtSettings: 1,
    },
    courtSettings: [
      {
        courtNumber: 1,
        displayLabel: '1',
      },
    ],
    provenance: createdProvenance(),
  };
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function setUpdatedProvenance(data, tag) {
  const previous = data.provenance;
  data.provenance = previous == null
    ? { lastWrittenFrom: writeOrigin(tag) }
    : {
        ...previous,
        lastWrittenFrom: writeOrigin(tag),
      };
}

function displayUpdate(current, title = 'Updated Event') {
  const next = clone(current);
  next.event.title = title;
  next.event.memo = 'Updated memo';
  next.event.revision += 1;
  next.event.updatedAt = '2026-09-27T00:01:00.000Z';
  next.players[0].displayName = 'Updated Player';
  next.players[0].updatedAt = next.event.updatedAt;
  next.revisions.display += 1;
  setUpdatedProvenance(next, 'display');
  return next;
}

function courtUpdate(current, label = 'A') {
  const next = clone(current);
  next.event.revision += 1;
  next.event.updatedAt = '2026-09-27T00:02:00.000Z';
  next.revisions.courtSettings += 1;
  next.courtSettings[0].displayLabel = label;
  setUpdatedProvenance(next, 'court');
  return next;
}

function promoteOperationalMetadata(next, current) {
  next.schemaVersion = 2;
  if (current.revisions == null) {
    next.revisions = {
      display: current.event.revision,
      courtSettings: current.event.revision,
    };
  }
}

function generateUpdate(current, generatedScheduleId = 'generated-1') {
  const next = clone(current);
  promoteOperationalMetadata(next, current);
  next.event.status = 'generated';
  next.event.currentGeneratedScheduleId = generatedScheduleId;
  next.event.revision = current.event.revision + 1;
  next.event.updatedAt = '2026-09-27T00:03:00.000Z';
  setUpdatedProvenance(next, 'generate');
  return next;
}

function adoptUpdate(current) {
  const next = clone(current);
  promoteOperationalMetadata(next, current);
  const generatedScheduleId = current.event.currentGeneratedScheduleId;
  next.event.status = 'adopted';
  next.event.currentGeneratedScheduleId = generatedScheduleId;
  next.event.adoptedGeneratedScheduleId = generatedScheduleId;
  next.event.adoptedAt = '2026-09-27T00:04:00.000Z';
  next.event.revision = current.event.revision + 1;
  next.event.updatedAt = next.event.adoptedAt;
  setUpdatedProvenance(next, 'adopt');
  return next;
}

async function seedWithoutRules(path, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(path).set(data);
  });
}

function legacyEventData(publicId) {
  const data = eventData(publicId, 'legacy-owner-placeholder');
  data.schemaVersion = 1;
  delete data.event.ownerUid;
  delete data.revisions;
  delete data.provenance;
  return data;
}

function progressData(generatedScheduleId) {
  return {
    schema_version: 1,
    schedule_type: 'doubles',
    generated_schedule_id: generatedScheduleId,
    total_match_count: 10,
    completed_match_count: 0,
    in_progress_match_count: 0,
    created_at: '2026-09-27T00:10:00.000Z',
    updated_at: '2026-09-27T00:10:00.000Z',
    revision: 1,
    provenance: createdProvenance(),
  };
}

function matchData(generatedScheduleId) {
  return {
    schema_version: 1,
    schedule_type: 'doubles',
    generated_schedule_id: generatedScheduleId,
    round_no: 1,
    court_no: 1,
    match_no: 1,
    status: 'scheduled',
    result: null,
    note: '',
    started_at: null,
    finished_at: null,
    created_at: '2026-09-27T00:10:00.000Z',
    updated_at: '2026-09-27T00:10:00.000Z',
    revision: 1,
    provenance: createdProvenance(),
  };
}

test('event create requires authenticated UID to match ownerUid', async () => {
  const alice = anonymousDb('alice');
  await assertSucceeds(
    alice.doc('events/PUBLIC01').set(eventData('PUBLIC01', 'alice')),
  );

  const unauthenticated = testEnv.unauthenticatedContext().firestore();
  await assertFails(
    unauthenticated
      .doc('events/PUBLIC02')
      .set(eventData('PUBLIC02', 'alice')),
  );

  await assertFails(
    alice.doc('events/PUBLIC03').set(eventData('PUBLIC03', 'bob')),
  );
});

test('known public ID is readable while collection queries are owner-scoped', async () => {
  const alice = anonymousDb('alice');
  const bob = anonymousDb('bob');
  await assertSucceeds(
    alice.doc('events/ALICE001').set(eventData('ALICE001', 'alice')),
  );
  await assertSucceeds(
    bob.doc('events/BOB00001').set(eventData('BOB00001', 'bob')),
  );

  const unauthenticated = testEnv.unauthenticatedContext().firestore();
  await assertSucceeds(unauthenticated.doc('events/ALICE001').get());
  await assertFails(unauthenticated.collection('events').get());

  const owned = await assertSucceeds(
    alice
      .collection('events')
      .where('event.ownerUid', '==', 'alice')
      .get(),
  );
  assert.equal(owned.docs.length, 1);
  assert.equal(owned.docs[0].id, 'ALICE001');

  await assertFails(alice.collection('events').get());
  await assertFails(
    alice
      .collection('events')
      .where('event.ownerUid', '==', 'bob')
      .get(),
  );

  const admin = registeredDb('admin-user', { admin: true });
  await assertSucceeds(admin.doc('events/ALICE001').get());
  await assertFails(
    admin
      .collection('events')
      .where('event.ownerUid', '==', 'alice')
      .get(),
  );
});

test('only owner can update display and court settings', async () => {
  const alice = anonymousDb('alice');
  const bob = anonymousDb('bob');
  const eventRef = alice.doc('events/PUBLIC01');
  await assertSucceeds(eventRef.set(eventData('PUBLIC01', 'alice')));

  const created = (await eventRef.get()).data();
  const displayed = displayUpdate(created);
  await assertSucceeds(eventRef.set(displayed));

  const afterDisplay = (await eventRef.get()).data();
  await assertFails(
    bob.doc('events/PUBLIC01').set(displayUpdate(afterDisplay, 'Bob edit')),
  );

  const admin = registeredDb('admin-user', { admin: true });
  await assertFails(
    admin.doc('events/PUBLIC01').set(displayUpdate(afterDisplay, 'Admin edit')),
  );

  const courted = courtUpdate(afterDisplay);
  await assertSucceeds(eventRef.set(courted));

  const afterCourt = (await eventRef.get()).data();
  await assertFails(
    bob.doc('events/PUBLIC01').set(courtUpdate(afterCourt, 'B')),
  );
});

test('ownerUid and provenance createdFrom remain immutable', async () => {
  const alice = anonymousDb('alice');
  const eventRef = alice.doc('events/PUBLIC01');
  await assertSucceeds(eventRef.set(eventData('PUBLIC01', 'alice')));

  const created = (await eventRef.get()).data();

  const ownerChanged = displayUpdate(created);
  ownerChanged.event.ownerUid = 'bob';
  await assertFails(eventRef.set(ownerChanged));

  const provenanceChanged = displayUpdate(created);
  provenanceChanged.provenance.createdFrom = writeOrigin('forged');
  await assertFails(eventRef.set(provenanceChanged));
});

test('shared user can regenerate and adopt without structural edit permission', async () => {
  const alice = anonymousDb('alice');
  const eventRef = alice.doc('events/PUBLIC01');
  await assertSucceeds(eventRef.set(eventData('PUBLIC01', 'alice')));

  const shared = testEnv.unauthenticatedContext().firestore();
  const sharedRef = shared.doc('events/PUBLIC01');
  const created = (await sharedRef.get()).data();

  const generated = generateUpdate(created);
  await assertSucceeds(sharedRef.set(generated));

  const afterGenerate = (await sharedRef.get()).data();
  const forgedDisplay = generateUpdate(afterGenerate, 'generated-2');
  forgedDisplay.event.title = 'Shared structural edit';
  await assertFails(sharedRef.set(forgedDisplay));

  const forgedOwner = generateUpdate(afterGenerate, 'generated-2');
  forgedOwner.event.ownerUid = 'shared-user';
  await assertFails(sharedRef.set(forgedOwner));

  const adopted = adoptUpdate(afterGenerate);
  await assertSucceeds(sharedRef.set(adopted));
});

test('legacy event keeps shared operations but cannot gain owner edits', async () => {
  const publicId = 'LEGACY01';
  await seedWithoutRules(
    `events/${publicId}`,
    legacyEventData(publicId),
  );

  const shared = testEnv.unauthenticatedContext().firestore();
  const sharedRef = shared.doc(`events/${publicId}`);
  const legacy = (await sharedRef.get()).data();

  await assertFails(
    anonymousDb('alice')
      .doc(`events/${publicId}`)
      .set(displayUpdate(legacy)),
  );

  await assertSucceeds(sharedRef.set(generateUpdate(legacy)));

  const promoted = (await sharedRef.get()).data();
  assert.equal(promoted.schemaVersion, 2);
  assert.equal(promoted.event.ownerUid, undefined);
  assert.deepEqual(promoted.revisions, {
    display: 1,
    courtSettings: 1,
  });
});

test('shared progress and match writes preserve identity fields', async () => {
  const alice = anonymousDb('alice');
  await assertSucceeds(
    alice.doc('events/PUBLIC01').set(eventData('PUBLIC01', 'alice')),
  );

  const shared = testEnv.unauthenticatedContext().firestore();
  const progressRef = shared.doc(
    'events/PUBLIC01/schedule_progress/generated-1',
  );
  await assertSucceeds(progressRef.set(progressData('generated-1')));

  const invalidProgress = progressData('wrong-generated-id');
  await assertFails(
    shared
      .doc('events/PUBLIC01/schedule_progress/generated-2')
      .set(invalidProgress),
  );

  const progress = (await progressRef.get()).data();
  const nextProgress = clone(progress);
  nextProgress.in_progress_match_count = 1;
  nextProgress.updated_at = '2026-09-27T00:11:00.000Z';
  nextProgress.revision += 1;
  setUpdatedProvenance(nextProgress, 'progress');
  await assertSucceeds(progressRef.set(nextProgress));

  const changedTotal = clone(nextProgress);
  changedTotal.total_match_count = 11;
  changedTotal.revision += 1;
  changedTotal.updated_at = '2026-09-27T00:12:00.000Z';
  setUpdatedProvenance(changedTotal, 'progress-total');
  await assertFails(progressRef.set(changedTotal));

  const matchRef = shared.doc(
    'events/PUBLIC01/schedule_progress/generated-1/matches/r1_c1',
  );
  await assertSucceeds(matchRef.set(matchData('generated-1')));

  const match = (await matchRef.get()).data();
  const nextMatch = clone(match);
  nextMatch.status = 'in_progress';
  nextMatch.note = 'playing';
  nextMatch.started_at = '2026-09-27T00:13:00.000Z';
  nextMatch.updated_at = nextMatch.started_at;
  nextMatch.revision += 1;
  setUpdatedProvenance(nextMatch, 'match');
  await assertSucceeds(matchRef.set(nextMatch));

  const forgedIdentity = clone(nextMatch);
  forgedIdentity.round_no = 2;
  forgedIdentity.revision += 1;
  forgedIdentity.updated_at = '2026-09-27T00:14:00.000Z';
  setUpdatedProvenance(forgedIdentity, 'match-forged');
  await assertFails(matchRef.set(forgedIdentity));
});
