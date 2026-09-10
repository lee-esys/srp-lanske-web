const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');

const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-lanske-rules';
const sourceType = 'tennisbear';
const sourceUserId = '899212';
const mappingId = `${sourceType}_${sourceUserId}`;
const profileUrl = `https://www.tennisbear.net/user/${sourceUserId}/info`;
const confirmationCodeHash = 'a'.repeat(64);

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '../../firestore.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

function registeredDb(uid) {
  const email = `${uid}@example.test`;
  return testEnv
    .authenticatedContext(uid, {
      email,
      email_verified: true,
      firebase: {
        sign_in_provider: 'password',
        identities: { email: [email] },
      },
    })
    .firestore();
}

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

function serverTimestamp() {
  return firebase.firestore.FieldValue.serverTimestamp();
}

function deleteField() {
  return firebase.firestore.FieldValue.delete();
}

function timestampFromNow({ days = 0, hours = 0 }) {
  const millis = Date.now() + (days * 24 + hours) * 60 * 60 * 1000;
  return firebase.firestore.Timestamp.fromMillis(millis);
}

function timestampAgo({ minutes = 1 } = {}) {
  return firebase.firestore.Timestamp.fromMillis(
    Date.now() - minutes * 60 * 1000,
  );
}

function requestData(uid, requestSourceUserId = sourceUserId, overrides = {}) {
  const requestMappingId = `${sourceType}_${requestSourceUserId}`;
  return {
    schemaVersion: 1,
    lanskeUserId: uid,
    sourceType,
    sourceUserId: requestSourceUserId,
    mappingId: requestMappingId,
    profileUrl: `https://www.tennisbear.net/user/${requestSourceUserId}/info`,
    state: 'pending',
    confirmationCodeHash,
    confirmationCodeExpiresAt: timestampFromNow({ days: 6 }),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function lockData(uid, requestId) {
  return {
    schemaVersion: 1,
    lanskeUserId: uid,
    sourceType,
    requestId,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
}

async function seedUser(uid, externalIdentityIds) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const data = {
      schemaVersion: 1,
      createdAt: timestampAgo(),
    };
    if (externalIdentityIds != null) {
      data.externalIdentityIds = externalIdentityIds;
    }
    await context.firestore().doc(`users/${uid}`).set(data);
  });
}

async function seedActiveMapping({
  uid,
  requestId = 'approved-request',
  requestSourceUserId = sourceUserId,
}) {
  const activeMappingId = `${sourceType}_${requestSourceUserId}`;
  const activeProfileUrl =
    `https://www.tennisbear.net/user/${requestSourceUserId}/info`;

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const batch = db.batch();
    batch.set(db.doc(`users/${uid}`), {
      schemaVersion: 1,
      createdAt: timestampAgo(),
      externalIdentityIds: { [sourceType]: activeMappingId },
    });
    batch.set(db.doc(`externalIdentityLinkRequests/${requestId}`), {
      schemaVersion: 1,
      lanskeUserId: uid,
      sourceType,
      sourceUserId: requestSourceUserId,
      mappingId: activeMappingId,
      profileUrl: activeProfileUrl,
      state: 'approved',
      confirmationCodeHash,
      confirmationCodeExpiresAt: timestampFromNow({ days: 6 }),
      createdAt: timestampAgo({ minutes: 10 }),
      updatedAt: timestampAgo(),
      approvedAt: timestampAgo({ minutes: 5 }),
    });
    batch.set(db.doc(`externalIdentityMappings/${activeMappingId}`), {
      schemaVersion: 1,
      sourceType,
      sourceUserId: requestSourceUserId,
      lanskeUserId: uid,
      profileUrl: activeProfileUrl,
      approvedAt: timestampAgo({ minutes: 5 }),
      requestId,
      createdAt: timestampAgo({ minutes: 5 }),
      updatedAt: timestampAgo({ minutes: 5 }),
    });
    await batch.commit();
  });
}

async function createPendingRequest(
  db,
  uid,
  requestId = 'request-1',
  requestSourceUserId = sourceUserId,
  requestOverrides = {},
) {
  const batch = db.batch();
  batch.set(
    db.doc(`externalIdentityLinkRequests/${requestId}`),
    requestData(uid, requestSourceUserId, requestOverrides),
  );
  batch.set(
    db.doc(`externalIdentityLinkRequestLocks/${uid}_${sourceType}`),
    lockData(uid, requestId),
  );
  return batch.commit();
}

test('registered user with users/{uid} can create own pending request and lock', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');

  await assertSucceeds(createPendingRequest(db, 'alice'));

  const request = await db.doc('externalIdentityLinkRequests/request-1').get();
  const lock = await db
    .doc('externalIdentityLinkRequestLocks/alice_tennisbear')
    .get();
  assert.equal(request.data().state, 'pending');
  assert.equal(lock.data().requestId, 'request-1');
});

test('unauthenticated and anonymous users cannot create a link request', async () => {
  await seedUser('alice');

  const unauthenticated = testEnv.unauthenticatedContext().firestore();
  await assertFails(createPendingRequest(unauthenticated, 'alice', 'unauth'));

  const anonymous = anonymousDb('alice');
  await assertFails(createPendingRequest(anonymous, 'alice', 'anonymous'));
});

test('registered user without users/{uid} cannot create a link request', async () => {
  const db = registeredDb('alice');
  await assertFails(createPendingRequest(db, 'alice'));
});

test('request validation rejects mismatched profile URL and overlong expiry', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');

  await assertFails(
    createPendingRequest(db, 'alice', 'bad-url', sourceUserId, {
      profileUrl: 'https://www.tennisbear.net/user/123456/info',
    }),
  );

  await assertFails(
    createPendingRequest(db, 'alice', 'bad-expiry', sourceUserId, {
      confirmationCodeExpiresAt: timestampFromNow({ days: 8 }),
    }),
  );
});

test('existing mapping blocks a new request without exposing the mapping to another user', async () => {
  await seedActiveMapping({ uid: 'bob' });
  await seedUser('alice');
  const alice = registeredDb('alice');

  await assertFails(createPendingRequest(alice, 'alice'));
  await assertFails(alice.doc(`externalIdentityMappings/${mappingId}`).get());
});

test('one Lanske user cannot create another active identity for the same source', async () => {
  await seedUser('alice', { tennisbear: 'tennisbear_123456' });
  const db = registeredDb('alice');

  await assertFails(createPendingRequest(db, 'alice'));
});

test('reissue succeeds only when old request, new request, and lock change atomically', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');
  await assertSucceeds(createPendingRequest(db, 'alice', 'old-request'));

  const batch = db.batch();
  batch.set(
    db.doc('externalIdentityLinkRequests/new-request'),
    requestData('alice'),
  );
  batch.update(db.doc('externalIdentityLinkRequests/old-request'), {
    state: 'superseded',
    supersededByRequestId: 'new-request',
    updatedAt: serverTimestamp(),
  });
  batch.update(db.doc('externalIdentityLinkRequestLocks/alice_tennisbear'), {
    requestId: 'new-request',
    updatedAt: serverTimestamp(),
  });

  await assertSucceeds(batch.commit());

  const oldRequest = await db
    .doc('externalIdentityLinkRequests/old-request')
    .get();
  const newRequest = await db
    .doc('externalIdentityLinkRequests/new-request')
    .get();
  const lock = await db
    .doc('externalIdentityLinkRequestLocks/alice_tennisbear')
    .get();
  assert.equal(oldRequest.data().state, 'superseded');
  assert.equal(newRequest.data().state, 'pending');
  assert.equal(lock.data().requestId, 'new-request');
});

test('incomplete reissue is rejected', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');
  await assertSucceeds(createPendingRequest(db, 'alice', 'old-request'));

  const batch = db.batch();
  batch.set(
    db.doc('externalIdentityLinkRequests/new-request'),
    requestData('alice'),
  );
  batch.update(db.doc('externalIdentityLinkRequests/old-request'), {
    state: 'superseded',
    supersededByRequestId: 'new-request',
    updatedAt: serverTimestamp(),
  });

  await assertFails(batch.commit());
});

test('cancel succeeds only when pending request update and lock deletion are atomic', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');
  await assertSucceeds(createPendingRequest(db, 'alice'));

  const batch = db.batch();
  batch.update(db.doc('externalIdentityLinkRequests/request-1'), {
    state: 'canceled',
    canceledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.delete(db.doc('externalIdentityLinkRequestLocks/alice_tennisbear'));
  await assertSucceeds(batch.commit());

  const request = await db.doc('externalIdentityLinkRequests/request-1').get();
  assert.equal(request.data().state, 'canceled');
});

test('cancel without deleting the active request lock is rejected', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');
  await assertSucceeds(createPendingRequest(db, 'alice'));

  await assertFails(
    db.doc('externalIdentityLinkRequests/request-1').update({
      state: 'canceled',
      canceledAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );
});

test('user cannot add or replace externalIdentityIds directly', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');

  await assertFails(
    db.doc('users/alice').update({
      'externalIdentityIds.tennisbear': mappingId,
    }),
  );

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('users/alice').update({
      externalIdentityIds: { tennisbear: 'tennisbear_123456' },
    });
  });

  await assertFails(
    db.doc('users/alice').update({
      'externalIdentityIds.tennisbear': mappingId,
    }),
  );
});

test('unlink succeeds only as mapping delete, pointer removal, and history update together', async () => {
  await seedActiveMapping({ uid: 'alice' });
  const db = registeredDb('alice');

  const batch = db.batch();
  batch.update(db.doc('users/alice'), {
    'externalIdentityIds.tennisbear': deleteField(),
  });
  batch.update(db.doc('externalIdentityLinkRequests/approved-request'), {
    unlinkedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  batch.delete(db.doc(`externalIdentityMappings/${mappingId}`));

  await assertSucceeds(batch.commit());

  const user = await db.doc('users/alice').get();
  const request = await db
    .doc('externalIdentityLinkRequests/approved-request')
    .get();
  assert.equal(user.data().externalIdentityIds?.tennisbear, undefined);
  assert.equal(request.data().state, 'approved');
  assert.ok(request.data().unlinkedAt != null);

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const mapping = await context
      .firestore()
      .doc(`externalIdentityMappings/${mappingId}`)
      .get();
    assert.equal(mapping.exists, false);
  });
});

test('incomplete unlink is rejected', async () => {
  await seedActiveMapping({ uid: 'alice' });
  const db = registeredDb('alice');

  await assertFails(db.doc(`externalIdentityMappings/${mappingId}`).delete());
});

test('ordinary users cannot approve, reject, create mappings, or access admin audit', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');
  await assertSucceeds(createPendingRequest(db, 'alice'));

  await assertFails(
    db.doc('externalIdentityLinkRequests/request-1').update({
      state: 'approved',
      approvedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  await assertFails(
    db.doc(`externalIdentityMappings/${mappingId}`).set({
      schemaVersion: 1,
      sourceType,
      sourceUserId,
      lanskeUserId: 'alice',
      profileUrl,
      approvedAt: serverTimestamp(),
      requestId: 'request-1',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }),
  );

  await assertFails(
    db.doc('externalIdentityLinkRequestAudits/request-1').set({
      schemaVersion: 1,
      requestId: 'request-1',
      action: 'approved',
      actorUserId: 'alice',
      createdAt: serverTimestamp(),
    }),
  );
  await assertFails(
    db.doc('externalIdentityLinkRequestAudits/request-1').get(),
  );
});

test('another registered user cannot read request, lock, or mapping data', async () => {
  await seedActiveMapping({ uid: 'alice' });
  const bob = registeredDb('bob');

  await assertFails(
    bob.doc('externalIdentityLinkRequests/approved-request').get(),
  );
  await assertFails(
    bob.doc('externalIdentityLinkRequestLocks/alice_tennisbear').get(),
  );
  await assertFails(bob.doc(`externalIdentityMappings/${mappingId}`).get());
});

test('existing event, team schedule, and core read behavior remains unchanged', async () => {
  const unauthenticated = testEnv.unauthenticatedContext().firestore();

  await assertSucceeds(
    unauthenticated.doc('events/event-1').set({ title: 'event' }),
  );
  await assertSucceeds(unauthenticated.doc('events/event-1').get());

  await assertSucceeds(
    unauthenticated.doc('team_schedules/team-1').set({ title: 'team' }),
  );
  await assertSucceeds(unauthenticated.doc('team_schedules/team-1').get());

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('core_example/doc-1').set({ value: 1 });
  });
  await assertSucceeds(unauthenticated.doc('core_example/doc-1').get());
  await assertFails(
    unauthenticated.doc('core_example/doc-2').set({ value: 2 }),
  );
});
