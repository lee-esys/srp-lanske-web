const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');

const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { clearFirestoreCollections } = require('./test_environment');

const projectId = 'demo-lanske-rules';
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({ projectId });
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

function timestampFromNow({ minutes = 0, hours = 0 }) {
  const millis = Date.now() + (hours * 60 + minutes) * 60 * 1000;
  return firebase.firestore.Timestamp.fromMillis(millis);
}

function serverTimestamp() {
  return firebase.firestore.FieldValue.serverTimestamp();
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
  const now = '2026-09-28T00:00:00.000Z';
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
      expiresAt: '2026-10-08T00:00:00.000Z',
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

function pendingTransferData(sourceUid, handoffSecret = 'A'.repeat(43)) {
  return {
    schemaVersion: 1,
    sourceUid,
    handoffSecret,
    state: 'pending',
    createdAt: serverTimestamp(),
    expiresAt: timestampFromNow({ hours: 1 }),
    updatedAt: serverTimestamp(),
  };
}

async function createPendingTransfer({
  sourceUid = 'source-anon',
  handoffSecret = 'A'.repeat(43),
} = {}) {
  const source = anonymousDb(sourceUid);
  await assertSucceeds(
    source
      .doc(`eventOwnershipTransfers/${sourceUid}`)
      .set(pendingTransferData(sourceUid, handoffSecret)),
  );
  return { sourceUid, handoffSecret };
}

async function acceptTransfer({
  sourceUid,
  handoffSecret,
  targetUid = 'target-account',
}) {
  const target = registeredDb(targetUid);
  await assertSucceeds(
    target.doc(`eventOwnershipTransfers/${sourceUid}`).update({
      state: 'accepted',
      targetUid,
      handoffSecretProof: handoffSecret,
      acceptedAt: serverTimestamp(),
      acceptedExpiresAt: timestampFromNow({ hours: 1 }),
      updatedAt: serverTimestamp(),
    }),
  );
  return target;
}

function transferredEvent(current, targetUid) {
  const next = JSON.parse(JSON.stringify(current));
  next.event.ownerUid = targetUid;
  next.event.revision += 1;
  next.event.updatedAt = '2026-09-28T00:01:00.000Z';
  next.provenance.lastWrittenFrom = writeOrigin('transfer');
  return next;
}

test('only the authenticated anonymous source can prepare a transfer', async () => {
  const source = anonymousDb('source-anon');
  await assertSucceeds(
    source
      .doc('eventOwnershipTransfers/source-anon')
      .set(pendingTransferData('source-anon')),
  );

  await assertFails(
    source.doc('eventOwnershipTransfers/source-anon').get(),
  );

  await assertFails(
    anonymousDb('other-anon')
      .doc('eventOwnershipTransfers/source-anon')
      .set(pendingTransferData('source-anon')),
  );

  await assertFails(
    registeredDb('source-anon')
      .doc('eventOwnershipTransfers/source-anon')
      .set(pendingTransferData('source-anon')),
  );

  await assertFails(
    testEnv
      .unauthenticatedContext()
      .firestore()
      .doc('eventOwnershipTransfers/source-anon')
      .set(pendingTransferData('source-anon')),
  );
});

test('anonymous source can safely replace its pending handoff secret', async () => {
  const source = anonymousDb('source-anon');
  await assertSucceeds(
    source
      .doc('eventOwnershipTransfers/source-anon')
      .set(pendingTransferData('source-anon')),
  );

  await assertSucceeds(
    source
      .doc('eventOwnershipTransfers/source-anon')
      .set(pendingTransferData('source-anon', 'B'.repeat(43))),
  );
});

test('target account must know the source handoff secret to accept', async () => {
  const { sourceUid, handoffSecret } = await createPendingTransfer();
  const target = registeredDb('target-account');
  const ref = target.doc(`eventOwnershipTransfers/${sourceUid}`);

  await assertFails(
    ref.update({
      state: 'accepted',
      targetUid: 'target-account',
      handoffSecretProof: 'Z'.repeat(43),
      acceptedAt: serverTimestamp(),
      acceptedExpiresAt: timestampFromNow({ hours: 1 }),
      updatedAt: serverTimestamp(),
    }),
  );

  await assertFails(
    anonymousDb('target-anon')
      .doc(`eventOwnershipTransfers/${sourceUid}`)
      .update({
        state: 'accepted',
        targetUid: 'target-anon',
        handoffSecretProof: handoffSecret,
        acceptedAt: serverTimestamp(),
        acceptedExpiresAt: timestampFromNow({ hours: 1 }),
        updatedAt: serverTimestamp(),
      }),
  );

  await assertSucceeds(
    ref.update({
      state: 'accepted',
      targetUid: 'target-account',
      handoffSecretProof: handoffSecret,
      acceptedAt: serverTimestamp(),
      acceptedExpiresAt: timestampFromNow({ hours: 1 }),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('admin role alone cannot inspect or use another source transfer', async () => {
  const { sourceUid } = await createPendingTransfer();
  const admin = registeredDb('admin-account', { admin: true });

  await assertFails(
    admin.doc(`eventOwnershipTransfers/${sourceUid}`).get(),
  );

  await assertFails(
    admin
      .collection('events')
      .where('event.ownerUid', '==', sourceUid)
      .get(),
  );
});

test('accepted target can query only the accepted source owner events', async () => {
  const sourceUid = 'source-anon';
  const targetUid = 'target-account';
  const source = anonymousDb(sourceUid);

  await assertSucceeds(
    source.doc('events/SOURCE01').set(eventData('SOURCE01', sourceUid)),
  );
  await assertSucceeds(
    anonymousDb('other-anon')
      .doc('events/OTHER001')
      .set(eventData('OTHER001', 'other-anon')),
  );

  const prepared = await createPendingTransfer({ sourceUid });
  const target = await acceptTransfer({
    ...prepared,
    targetUid,
  });

  const sourceEvents = await assertSucceeds(
    target
      .collection('events')
      .where('event.ownerUid', '==', sourceUid)
      .get(),
  );
  assert.equal(sourceEvents.docs.length, 1);
  assert.equal(sourceEvents.docs[0].id, 'SOURCE01');

  await assertFails(
    target
      .collection('events')
      .where('event.ownerUid', '==', 'other-anon')
      .get(),
  );
  await assertFails(target.collection('events').get());
});

test('accepted target can change only ownerUid and event revision metadata', async () => {
  const sourceUid = 'source-anon';
  const targetUid = 'target-account';
  const source = anonymousDb(sourceUid);
  const eventRef = source.doc('events/SOURCE01');
  await assertSucceeds(
    eventRef.set(eventData('SOURCE01', sourceUid)),
  );

  const prepared = await createPendingTransfer({ sourceUid });
  const target = await acceptTransfer({
    ...prepared,
    targetUid,
  });

  const targetEventRef = target.doc('events/SOURCE01');
  const current = (await targetEventRef.get()).data();
  await assertSucceeds(
    targetEventRef.set(transferredEvent(current, targetUid)),
  );

  const transferred = (await targetEventRef.get()).data();
  assert.equal(transferred.event.ownerUid, targetUid);
  assert.equal(transferred.event.revision, 2);

  const forged = transferredEvent(
    eventData('SOURCE02', sourceUid),
    targetUid,
  );
  forged.event.title = 'Forged title';
  await seedEventWithoutRules('SOURCE02', sourceUid);
  await assertFails(target.doc('events/SOURCE02').set(forged));
});

test('legacy ownerless event cannot be claimed through a transfer', async () => {
  const sourceUid = 'source-anon';
  const targetUid = 'target-account';
  const legacy = eventData('LEGACY01', sourceUid);
  delete legacy.event.ownerUid;
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('events/LEGACY01').set(legacy);
  });

  const prepared = await createPendingTransfer({ sourceUid });
  const target = await acceptTransfer({
    ...prepared,
    targetUid,
  });

  const forged = JSON.parse(JSON.stringify(legacy));
  forged.event.ownerUid = targetUid;
  forged.event.revision += 1;
  forged.event.updatedAt = '2026-09-28T00:02:00.000Z';
  forged.provenance.lastWrittenFrom = writeOrigin('legacy-claim');

  await assertFails(target.doc('events/LEGACY01').set(forged));
});

test('target can refresh accepted authorization and complete it', async () => {
  const prepared = await createPendingTransfer();
  const target = await acceptTransfer(prepared);

  await assertSucceeds(
    target.doc(`eventOwnershipTransfers/${prepared.sourceUid}`).update({
      state: 'accepted',
      targetUid: 'target-account',
      handoffSecretProof: prepared.handoffSecret,
      acceptedAt: serverTimestamp(),
      acceptedExpiresAt: timestampFromNow({ hours: 1 }),
      updatedAt: serverTimestamp(),
    }),
  );

  await assertSucceeds(
    target.doc(`eventOwnershipTransfers/${prepared.sourceUid}`).update({
      state: 'completed',
      targetUid: 'target-account',
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  const completed = await target
    .doc(`eventOwnershipTransfers/${prepared.sourceUid}`)
    .get();
  assert.equal(completed.data().state, 'completed');

  await assertSucceeds(
    target.doc(`eventOwnershipTransfers/${prepared.sourceUid}`).update({
      state: 'accepted',
      targetUid: 'target-account',
      handoffSecretProof: prepared.handoffSecret,
      acceptedAt: serverTimestamp(),
      acceptedExpiresAt: timestampFromNow({ hours: 1 }),
      updatedAt: serverTimestamp(),
    }),
  );

  await assertSucceeds(
    target.doc(`eventOwnershipTransfers/${prepared.sourceUid}`).update({
      state: 'completed',
      targetUid: 'target-account',
      completedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

async function seedEventWithoutRules(publicId, ownerUid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context
      .firestore()
      .doc(`events/${publicId}`)
      .set(eventData(publicId, ownerUid));
  });
}
