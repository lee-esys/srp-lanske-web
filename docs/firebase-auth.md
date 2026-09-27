# Firebase Auth foundation

## Purpose

Lanske uses Firebase Authentication as the common authentication foundation for ver0.2.0 while preserving the user-facing experience of creating and using schedules without an explicit login step.

This document covers the foundation introduced by web #202. Account registration providers and Lanske user documents are handled by later issues.

## Session model

The application exposes three authentication states:

```text
signed out
anonymous
registered account
```

Firebase Auth UID is the internal identifier used by later ownership features.

The Firebase `User` object is kept behind the auth repository boundary so features do not need to depend directly on Firebase Auth APIs.

## Lazy Anonymous Auth

Anonymous Auth is intentionally lazy.

Opening Lanske, opening a shared URL, or restoring an existing screen must not create an anonymous Firebase user by itself.

When a later feature requires a stable UID, obtain the auth controller from `AuthScope` and request a session explicitly:

```dart
final auth = AuthScope.of(context);
final session = await auth.ensureAnonymousSession();
final uid = session.uid;
```

If a Firebase session already exists, it is reused. If the user is signed out, `signInAnonymously()` is performed once and concurrent requests are coalesced by the controller.

Do not call `ensureAnonymousSession()` simply on page load.

## Event ownership capabilities

New doubles events persist the Firebase Auth UID that exists when the event is first saved as `ownerUid`. Opening or restoring a shared URL does not create an anonymous session only to evaluate ownership.

Owner-only application capabilities are derived at runtime from the saved event owner UID and the current Auth UID:

```text
event.ownerUid + current Auth UID
        -> EventCapabilities
```

For the current policy, matching UIDs allow editing event title / memo, player display names, and court display labels. A different UID, a signed-out session, or a legacy event with `ownerUid == null` is treated as shared access for those structural edits.

Shared access continues to allow schedule viewing, progress and match-result input, regenerate, adopt, and existing share URL reuse. Admin role is not an ownership override.

These capabilities are application-side UI/action controls. Firestore Rules remain the final write-authorization boundary and are handled separately.

## Lanske user documents

Anonymous Firebase users do not create `users/{uid}` documents.

```text
anonymous Firebase user
  -> Firebase Auth only
  -> can be used as event owner UID when an event is saved
  -> no users/{uid} document

registered Lanske account
  -> users/{firebaseAuthUid}
```

Creation and management of the registered Lanske user document is handled by web #203.

## Sign out

Signing out returns the auth state to `signedOut`.

A replacement anonymous user is not created immediately. The next operation that actually needs a UID can call `ensureAnonymousSession()` again.

## Firebase initialization

Firebase is initialized independently of `LANSKE_EVENT_REPOSITORY` because Auth is now an application-wide service rather than a Firestore-repository implementation detail.

For Web, the current generated Firebase options point to the `lanske-srp` project. This means local, Codespaces, and Hosting Preview builds can use the same Firebase Auth user pool unless the environment configuration is separated in a later issue.

## Firebase Console setup

Before testing Anonymous Auth, enable the Anonymous sign-in provider for the Firebase project used by the Web build.

For web #202 only Anonymous Auth is required. Email/Password, Google, Apple, X, authorized domains, and provider callback configuration are handled when the corresponding account-login work starts.

Anonymous account automatic cleanup is not enabled as part of this issue.

## Error handling

Auth failures are exposed through `AuthSessionController.lastError` and are rethrown to the operation that requested authentication.

A failed anonymous sign-in does not automatically block screens that do not require authentication. Existing login-free browsing remains usable unless the requested operation itself requires a UID.

## Responsibility boundaries

The Auth foundation itself does not enforce event write authorization. Event ownership and application capabilities are layered on top of the Auth UID, while owner-based Firestore Rules remain a separate responsibility.

Account registration, provider login, user documents, and anonymous-to-account credential linking are implemented by their respective account features rather than by `AuthSessionController`.
