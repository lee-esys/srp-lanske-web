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

function anonymousDb(uid) {
  return testEnv
    .authenticatedContext(uid, {
      firebase: {
        sign_in_provider: 'anonymous',
        identities: {},
      },
    })
    .firestore();
}

function newUserData(plan) {
  const data = {
    schemaVersion: 1,
    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
  };
  if (plan !== undefined) {
    data.plan = plan;
  }
  return data;
}

async function seedUser(uid, plan = 'free') {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`users/${uid}`).set({
      schemaVersion: 1,
      createdAt: firebase.firestore.Timestamp.now(),
      plan,
    });
  });
}

test('registered account can create itself with free plan', async () => {
  const db = registeredDb('alice');
  await assertSucceeds(db.doc('users/alice').set(newUserData('free')));
});

test('legacy-compatible account create may omit plan', async () => {
  const db = registeredDb('alice');
  await assertSucceeds(db.doc('users/alice').set(newUserData()));
});

test('registered account cannot create itself as premium', async () => {
  const db = registeredDb('alice');
  await assertFails(db.doc('users/alice').set(newUserData('premium')));
});

test('anonymous user cannot create a Lanske account plan', async () => {
  const db = anonymousDb('anonymous-user');
  await assertFails(
    db.doc('users/anonymous-user').set(newUserData('free')),
  );
});

test('registered account cannot change its own plan', async () => {
  await seedUser('alice');
  const db = registeredDb('alice');

  await assertFails(
    db.doc('users/alice').update({
      plan: 'premium',
    }),
  );
});

test('admin role does not grant plan mutation permission', async () => {
  await seedUser('admin-user');
  const db = registeredDb('admin-user', { admin: true });

  await assertFails(
    db.doc('users/admin-user').update({
      plan: 'premium',
    }),
  );
});
