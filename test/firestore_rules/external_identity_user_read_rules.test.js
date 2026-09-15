const { after, before, beforeEach, test } = require('node:test');

const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-lanske-rules';
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  if (testEnv != null) {
    await testEnv.cleanup();
  }
});

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

function timestamp(minutesAgo = 0) {
  return firebase.firestore.Timestamp.fromMillis(
    Date.now() - minutesAgo * 60 * 1000,
  );
}

async function seedRequest({ uid, requestId, sourceUserId, minutesAgo }) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`externalIdentityLinkRequests/${requestId}`).set({
      schemaVersion: 1,
      lanskeUserId: uid,
      sourceType: 'tennisbear',
      sourceUserId,
      mappingId: `tennisbear_${sourceUserId}`,
      profileUrl: `https://www.tennisbear.net/user/${sourceUserId}/info`,
      state: 'canceled',
      confirmationCodeHash: 'a'.repeat(64),
      confirmationCodeExpiresAt: timestamp(-60),
      createdAt: timestamp(minutesAgo + 1),
      updatedAt: timestamp(minutesAgo),
      canceledAt: timestamp(minutesAgo),
    });
  });
}

test('registered user can query only own request history', async () => {
  await seedRequest({
    uid: 'alice',
    requestId: 'alice-1',
    sourceUserId: '899212',
    minutesAgo: 10,
  });
  await seedRequest({
    uid: 'alice',
    requestId: 'alice-2',
    sourceUserId: '899213',
    minutesAgo: 5,
  });
  await seedRequest({
    uid: 'bob',
    requestId: 'bob-1',
    sourceUserId: '999999',
    minutesAgo: 1,
  });

  const alice = registeredDb('alice');
  const snapshot = await assertSucceeds(
    alice
      .collection('externalIdentityLinkRequests')
      .where('lanskeUserId', '==', 'alice')
      .get(),
  );

  if (snapshot.docs.length !== 2) {
    throw new Error(`Expected 2 own requests, got ${snapshot.docs.length}`);
  }
});

test('request history cannot be listed without an owner constraint', async () => {
  await seedRequest({
    uid: 'alice',
    requestId: 'alice-1',
    sourceUserId: '899212',
    minutesAgo: 1,
  });

  const alice = registeredDb('alice');
  await assertFails(alice.collection('externalIdentityLinkRequests').get());
});

test('user cannot query another users request history', async () => {
  await seedRequest({
    uid: 'bob',
    requestId: 'bob-1',
    sourceUserId: '999999',
    minutesAgo: 1,
  });

  const alice = registeredDb('alice');
  await assertFails(
    alice
      .collection('externalIdentityLinkRequests')
      .where('lanskeUserId', '==', 'bob')
      .get(),
  );
});

test('admin can get one request but cannot browse request history unbounded', async () => {
  await seedRequest({
    uid: 'bob',
    requestId: 'bob-1',
    sourceUserId: '999999',
    minutesAgo: 1,
  });

  const admin = registeredDb('admin-user', { admin: true });

  await assertSucceeds(
    admin.doc('externalIdentityLinkRequests/bob-1').get(),
  );
  await assertFails(
    admin.collection('externalIdentityLinkRequests').get(),
  );
});
