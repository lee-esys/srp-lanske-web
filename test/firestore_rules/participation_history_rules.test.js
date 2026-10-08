const assert = require('node:assert/strict');
const { after, before, beforeEach, test } = require('node:test');
const { assertFails, assertSucceeds, initializeTestEnvironment } =
  require('@firebase/rules-unit-testing');
const { clearFirestoreCollections } = require('./test_environment');

let env;
const mappingId = 'tennisbear_899212';
const path = `externalIdentityParticipationHistories/${mappingId}/events/event-1`;

before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-lanske-rules' });
});
beforeEach(async () => { await clearFirestoreCollections(env); });
after(async () => { if (env) await env.cleanup(); });

function db(uid) {
  const email = `${uid}@example.test`;
  return env.authenticatedContext(uid, {
    email, email_verified: true,
    firebase: {
      sign_in_provider: 'password',
      identities: { email: [email] },
    },
  }).firestore();
}

async function seed({ uid = 'alice', link = true } = {}) {
  await env.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await firestore.doc('users/alice').set({
      schemaVersion: 1,
      externalIdentityIds: link ? { tennisbear: mappingId } : {},
    });
    await firestore.doc('users/bob').set({ schemaVersion: 1 });
    if (link) {
      await firestore.doc(`externalIdentityMappings/${mappingId}`).set({
        schemaVersion: 1,
        sourceType: 'tennisbear',
        sourceUserId: '899212',
        lanskeUserId: uid,
      });
    }
    await firestore.doc(path).set({
      schemaVersion: 1,
      eventId: 'event-1',
      sourceType: 'tennisbear',
      sourceUserId: '899212',
      eventDate: null,
      selfSnapshot: null,
      statisticsEligible: false,
      updatedAt: new Date(),
    });
  });
}

test('approved mapping holder can get and list only own projection', async () => {
  await seed();
  const alice = db('alice');
  const doc = await assertSucceeds(alice.doc(path).get());
  assert.equal(doc.data().eventId, 'event-1');
  const docs = await assertSucceeds(alice.collection(
    `externalIdentityParticipationHistories/${mappingId}/events`,
  ).orderBy('eventDate', 'desc').limit(20).get());
  assert.equal(docs.docs.length, 1);
});

test('other users and unauthenticated clients cannot read projection', async () => {
  await seed();
  await assertFails(db('bob').doc(path).get());
  await assertFails(db('bob').collection(
    `externalIdentityParticipationHistories/${mappingId}/events`,
  ).get());
  await assertFails(env.unauthenticatedContext().firestore().doc(path).get());
});

test('mapping unlink immediately revokes access without deleting projection', async () => {
  await seed();
  const alice = db('alice');
  await assertSucceeds(alice.doc(path).get());
  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`externalIdentityMappings/${mappingId}`).delete();
    await context.firestore().doc('users/alice').update({
      externalIdentityIds: {},
    });
  });
  await assertFails(alice.doc(path).get());
  await assertFails(alice.collection(
    `externalIdentityParticipationHistories/${mappingId}/events`,
  ).get());
});

test('pointer alone or mismatched mapping is not sufficient', async () => {
  await seed({ link: false });
  await assertFails(db('alice').doc(path).get());

  await env.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('users/alice').update({
      externalIdentityIds: { tennisbear: mappingId },
    });
    await context.firestore().doc(`externalIdentityMappings/${mappingId}`).set({
      sourceType: 'tennisbear',
      sourceUserId: '899212',
      lanskeUserId: 'bob',
    });
  });
  await assertFails(db('alice').doc(path).get());
});

test('no client may write projections, including identity owner', async () => {
  await seed();
  const alice = db('alice');
  await assertFails(alice.doc(path).update({ statisticsEligible: true }));
  await assertFails(alice.doc(path).delete());
  await assertFails(alice.doc(
    `externalIdentityParticipationHistories/${mappingId}/events/forged`,
  ).set({ eventId: 'forged' }));
  await assertFails(alice.doc(
    `externalIdentityParticipationHistories/${mappingId}`,
  ).set({ anything: true }));
});
