const collectionsToClear = [
  'users',
  'externalIdentityLinkRequests',
  'externalIdentityLinkRequestLocks',
  'externalIdentityLinkRequestAudits',
  'externalIdentityMappings',
  'events',
  'team_schedules',
  'core_example',
];

async function clearFirestoreCollections(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    for (const collectionPath of collectionsToClear) {
      const snapshot = await db.collection(collectionPath).get();
      if (snapshot.empty) {
        continue;
      }

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }
  });
}

module.exports = {
  clearFirestoreCollections,
};
