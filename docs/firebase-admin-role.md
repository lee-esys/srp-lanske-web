# Firebase admin role

## Purpose

Lanske uses a Firebase Authentication Custom Claim as the source of truth for
the minimum administrator role introduced by web #216.

```text
admin: true
```

Role remains separate from Plan, Entitlement, and resource Permission. The
admin claim does not grant Premium features and does not automatically grant
access to ordinary event, participant, or match data.

## Client-side role lookup

The Flutter client reads the current Firebase user's ID token through
`AdminRoleReader`.

- Signed-out users are not admins.
- Anonymous Firebase users are not admins.
- A registered user is an admin only when the Custom Claim value is the
  boolean `true`.
- Missing claims, `false`, strings such as `"true"`, and other values fail
  closed.
- Callers can request a forced ID-token refresh when an operational flow needs
  newly changed claims immediately.

The account page uses this lookup to show the temporary administrator card,
and web #213 reuses the same role reader for administrator navigation and
profile-link review. A client-side role check is not a security boundary;
Firestore Security Rules enforce the corresponding data access.

## Firestore Security Rules

`firestore.rules` exposes a shared `isAdmin()` helper that requires both:

```text
registered account
AND
request.auth.token.admin == true
```

web #216 itself did not open additional Firestore resources to administrators.
web #213 consumes the role foundation and adds only the narrowly scoped reads
and atomic writes required for TennisBear profile-link review.

The `users/{uid}` document does not duplicate the admin role.

## Initial role provisioning

Custom Claims must be changed only from a trusted Firebase Admin SDK
environment. Do not add an admin-role write path to the Flutter client and do
not commit service-account credentials to this repository.

For the initial administrator, a one-off script may be run from a trusted
environment such as Google Cloud Shell. Install `firebase-admin` only in that
temporary environment and use Application Default Credentials.

Example for granting the claim while preserving any existing Custom Claims:

```js
const { applicationDefault, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

initializeApp({ credential: applicationDefault() });

async function main() {
  const uid = process.argv[2];
  if (!uid) throw new Error('Firebase Auth UID is required.');

  const auth = getAuth();
  const user = await auth.getUser(uid);

  await auth.setCustomUserClaims(uid, {
    ...(user.customClaims ?? {}),
    admin: true,
  });
}

main();
```

Removing the role should preserve unrelated claims as well:

```js
const claims = { ...(user.customClaims ?? {}) };
delete claims.admin;
await auth.setCustomUserClaims(uid, claims);
```

Do not use an email address, display name, Firestore field, or client request as
an automatic reason to grant the administrator role.

## Token refresh

Changing Custom Claims does not rewrite an already issued ID token.

After granting or removing the role, use one of the following before verifying
the UI or Rules behavior:

- sign out and sign in again, or
- explicitly force-refresh the Firebase ID token.

For the initial #216 verification, signing out and signing in again is the
simplest check. When the refreshed token contains `admin: true`, `/account`
shows a card containing only the administrator label below the account/logout
card.
