'use strict';
const { synchronize } = require('./reconcile.cjs');

async function main() {
  const apply = process.argv.includes('--apply');
  const apiUrl = process.env.LANSKE_TENNISBEAR_PREVIEW_URL;
  const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID;
  if (!apiUrl || !projectId) {
    throw new Error('Set LANSKE_TENNISBEAR_PREVIEW_URL and FIREBASE_PROJECT_ID');
  }
  const parsed = new URL(apiUrl);
  if (parsed.protocol !== 'https:' && !(parsed.protocol === 'http:' &&
      ['localhost', '127.0.0.1'].includes(parsed.hostname) &&
      process.argv.includes('--allow-local-api'))) {
    throw new Error('Preview API must use HTTPS (or explicitly authorized local HTTP)');
  }
  if (apply && process.env.CONFIRM_PROJECT_ID !== projectId) {
    throw new Error('For writes, set CONFIRM_PROJECT_ID to the exact target project ID');
  }

  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId });
  const database = admin.firestore();
  const result = await synchronize(database, apiUrl, apply);
  console.log(JSON.stringify(result, null, 2));
  if (result.failed > 0) process.exitCode = 1;
}
main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
