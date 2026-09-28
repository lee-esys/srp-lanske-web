const collectionGroupsToClear = [
  'matches',
  'schedule_progress',
];

const collectionsToClear = [
  'users',
  'externalIdentityLinkRequests',
  'externalIdentityLinkRequestLocks',
  'externalIdentityLinkRequestAudits',
  'externalIdentityMappings',
  'eventOwnershipTransfers',
  'events',
  'team_schedules',
  'core_example',
];

async function clearFirestoreCollections(testEnv) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    for (const collectionGroup of collectionGroupsToClear) {
      const snapshot = await db.collectionGroup(collectionGroup).get();
      if (snapshot.empty) {
        continue;
      }

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        batch.delete(doc.ref);
      }
      await batch.commit();
    }

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
