# Anonymous account transition

## Purpose

web #204 upgrades an existing anonymous Firebase user to a registered Lanske account without discarding the UID that later event ownership depends on.

The transition deliberately separates two cases:

```text
Anonymous user -> new registered account
Anonymous user -> credential already belongs to an existing account
```

The first case can complete in #204. The second case stops before switching Firebase users and hands the ownership-migration problem to #196.

## New account link

For a new Email / Password or Google credential:

```text
anonymous UID A
  -> link provider credential
registered UID A
  -> ensure users/A
```

The link result must still be a registered session with the same UID. A different UID is treated as an invalid transition instead of silently accepting ownership changes.

Provider operations are:

- Email / Password: `EmailAuthProvider.credential()` + `User.linkWithCredential()`
- Google Web: `User.linkWithPopup(GoogleAuthProvider())`
- Google non-Web: `User.linkWithProvider(GoogleAuthProvider())`

After linking, the Firebase ID token is force-refreshed before returning the new session.

## Existing-account collision

A provider link can fail because the credential is already associated with another Firebase account. #204 treats the following Firebase Auth error codes as an expected collision class:

- `credential-already-in-use`
- `email-already-in-use`
- `account-exists-with-different-credential`

On collision:

1. Keep the current anonymous Firebase session active.
2. Verify that the current UID is still the original anonymous source UID.
3. Return an `AccountTransitionResult.existingAccountCollision` containing only the source UID and provider type.
4. Do not call a target-account `signInWith...` method.
5. Do not accept a target UID supplied by the client as proof of ownership.

The target account UID is therefore intentionally unknown at the #204 boundary.

## #196 handoff boundary

#196 is responsible for the actual event ownership transfer.

The transfer must establish both sides safely:

- source: the currently authenticated anonymous UID whose data may be migrated
- target: the registered account authenticated as part of the migration flow

The source UID stored in a client-side transition result is context, not authorization evidence. #196 must not permit a caller to claim arbitrary source UIDs.

No event owner fields are changed by #204.

## Session synchronization

The existing `AuthRepository.sessionChanges()` uses Firebase `authStateChanges()`.

Provider linking changes an existing Firebase user rather than performing a normal sign-in, and `authStateChanges()` is not guaranteed to emit for that operation. Therefore #204 does not depend on the stream for the anonymous -> account UI transition.

After each link attempt, `AccountPage` calls `AuthSessionController.syncCurrentSession()` to synchronize the controller from `FirebaseAuth.currentUser` explicitly.

This also covers the partial-success boundary where provider linking succeeds but `users/{uid}` creation fails: the UI still observes the registered Firebase account and can retry user-document setup.

## Firestore registered-account check

`users/{uid}` remains unavailable to a purely anonymous account.

A newly linked user can temporarily have an ID token whose `firebase.sign_in_provider` still reflects the authentication session that began anonymously. The rules therefore classify the user as registered when either:

- `firebase.sign_in_provider` is not `anonymous`, or
- `firebase.identities` contains at least one linked identity.

A pure anonymous token has no linked identity and remains denied.

## Cancel, retry, and reload

No collision context is persisted in Firestore or local storage in #204.

- Popup cancel: anonymous session remains active.
- Network / provider failure: anonymous session remains active unless Firebase itself completed the link before the failure surfaced.
- User-document failure after a successful link: registered Auth session remains active and `ensureCurrentUser()` can retry.
- Collision: anonymous session remains active.
- Page reload after collision: transient collision UI state is cleared, but the anonymous Firebase session remains the source state and the user can retry later.

This keeps reload and cancel safe while #196 has not yet defined a persistent ownership-transfer record.

## Real-environment verification

Firebase account linking depends on provider configuration and browser behavior and must not be considered verified only by unit tests.

The accumulated ver0.2.0 real-environment checklist is tracked in web #209. In particular #204 requires provider-by-provider confirmation of:

- Anonymous -> new Email / Password account
- Anonymous -> existing Email / Password collision
- Anonymous -> new Google account
- Anonymous -> existing Google collision
- UID preservation
- `users/{uid}` creation after link
- popup cancel / retry
- session synchronization after link

Firebase documentation currently also notes a known account-linking issue affecting some projects, so the real Firebase project behavior is part of the completion check.
