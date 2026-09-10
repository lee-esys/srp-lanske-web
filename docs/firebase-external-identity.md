# Firebase external identity link foundation

This document describes the Firestore/domain foundation introduced by web #211 and the initial user-facing TennisBear link flow introduced by web #212.

## Scope

The foundation links a registered Lanske user to an approved public identity from an external service.

The first supported source is TennisBear, but the model keeps `sourceType` separate from `sourceUserId` so additional sources such as TennisOff can be added later.

This work does not connect imported event participants to approved mappings at runtime and does not implement personal statistics.

## Canonical identity

Display names are not identity keys.

```text
sourceType + sourceUserId
```

For TennisBear:

```text
sourceType   = tennisbear
sourceUserId = "899212"
mappingId    = tennisbear_899212
```

`sourceUserId` is always stored as a string even when the current source uses numeric IDs.

The profile URL is metadata used for input/verification. The stable identity key is `sourceType + sourceUserId`.

## User document

Registered account documents remain `users/{firebaseAuthUid}` with schema version 1.

An optional pointer map is added only after an identity is approved:

```text
users/{uid}
  schemaVersion: 1
  createdAt: Timestamp
  externalIdentityIds:
    tennisbear: tennisbear_899212
```

The pointer map is not the mapping source of truth. It exists for reverse lookup and account UI state.

Anonymous Firebase users do not have `users/{uid}` documents and cannot create link requests.

## Active mapping

Only currently active mappings exist in:

```text
externalIdentityMappings/{mappingId}
```

Example:

```text
externalIdentityMappings/tennisbear_899212
  schemaVersion: 1
  sourceType: tennisbear
  sourceUserId: "899212"
  lanskeUserId: <firebase uid>
  profileUrl: https://www.tennisbear.net/user/899212/info
  approvedAt: Timestamp
  requestId: <approved request id>
  createdAt: Timestamp
  updatedAt: Timestamp
```

The deterministic document ID prevents the same external identity from being actively mapped to multiple Lanske users at the same time.

A user may have at most one active identity per source. This is also represented by `users/{uid}.externalIdentityIds.{sourceType}`.

## Link request history

Requests are stored in:

```text
externalIdentityLinkRequests/{requestId}
```

Core fields:

```text
schemaVersion
lanskeUserId
sourceType
sourceUserId
mappingId
profileUrl
state
confirmationCodeHash
confirmationCodeExpiresAt
createdAt
updatedAt
```

Terminal/history fields are added when applicable:

```text
approvedAt
rejectedAt
canceledAt
unlinkedAt
supersededByRequestId
```

The request document is readable by the requesting user, so internal administrator Firebase UIDs are intentionally not stored there.

Request states currently modeled:

```text
pending
approved
rejected
canceled
expired
superseded
```

Expiration is always checked from `confirmationCodeExpiresAt`; a separate background process is not required to rewrite a stale `pending` request to `expired` immediately.

## Administrator audit

Administrator actor information is stored separately from the user-readable request:

```text
externalIdentityLinkRequestAudits/{requestId}
  schemaVersion: 1
  requestId
  action: approved | rejected
  actorUserId: <admin firebase uid>
  createdAt: Timestamp
```

Ordinary Web users cannot read or write this collection. The minimum admin-role foundation under #198 will later open only the administrator access required by #213.

## Active request lock

A deterministic lock prevents concurrent pending requests for the same Lanske user/source:

```text
externalIdentityLinkRequestLocks/{uid}_{sourceType}
  schemaVersion: 1
  lanskeUserId
  sourceType
  requestId
  createdAt
  updatedAt
```

Request creation writes the request and lock atomically.

Reissue:

1. creates a new request/code,
2. marks the old request `superseded`,
3. moves the lock to the new request.

Cancel marks the active request `canceled` and deletes the lock atomically.

## Confirmation code

The application issues a copy-friendly code such as:

```text
LSK-7K3M-Q2PX
```

Only its SHA-256 hash is stored in Firestore.

The system validity period is seven days. The user-facing flow asks the user to send the code through TennisBear chat within about one hour; that one-hour period is an operational prompt, not a hard expiry.

Reissue always creates a new code and supersedes the old request. The old expiry is never extended.

The plaintext confirmation code exists only in the immediate create/reissue response and in the current UI memory. It is not persisted and therefore cannot be reconstructed after page reload. A user who loses the code must reissue a new one.

## TennisBear URL validation

The initial parser accepts a public profile URL only and canonicalizes it to:

```text
https://www.tennisbear.net/user/{numericUserId}/info
```

No external fetch is performed during request creation. Actual profile ownership is checked later through the manual confirmation flow.

## User-facing flow

web #212 places the initial profile-link controls on `/account` as a separate feature card. The card is rendered only after the current Firebase session is a registered Lanske account and the matching `users/{uid}` document has been ensured.

The card intentionally remains independent from the permanent My Page design so it can be moved or hidden later without coupling profile-link logic to account authentication UI.

The user can:

- enter a TennisBear public profile URL,
- create a link request,
- copy the newly issued confirmation code,
- view pending / expired / approved / retryable states,
- reissue a confirmation code,
- cancel a pending request,
- unlink an approved mapping,
- start a fresh request after unlink.

The initial UI explains that:

- this is a Lanske-specific helper and not an official TennisBear account-link feature,
- linking the wrong profile can affect future personal history/statistics display,
- a profile mapping does not itself grant event or schedule access,
- unlink does not delete historical event, participant, match, or result data.

The UI uses a generic conflict message when a request cannot be created because of mapping/uniqueness conflicts. It does not expose whether another Lanske user already owns the external identity.

## User-facing state reads

`FirestoreExternalIdentityUserReader` provides the read side used by the account card.

For an approved mapping it:

1. reads the current user's `externalIdentityIds` pointer,
2. reads only the pointed active mapping document,
3. validates the mapping owner/source before returning it.

For retryable history it queries `externalIdentityLinkRequests` with an explicit `lanskeUserId == currentUid` constraint and selects the latest request for the requested source in application code. This avoids requiring a new composite index while keeping the Firestore query compatible with the owner-only list rule.

The user-facing facade `TennisBearProfileLinkService` combines these reads with the #211 request/reissue/cancel/unlink operations.

## Duplicate/privacy handling

Request creation does not directly read the target deterministic mapping document from the Web client. Firestore Security Rules check whether that mapping already exists and deny the write if it does.

This avoids turning the mapping collection into an existence oracle. A denied mapping conflict is converted to a generic domain conflict; the user UI must not reveal whether another Lanske user already owns the profile.

## Unlink / relink

Unlink removes:

```text
externalIdentityMappings/{mappingId}
users/{uid}.externalIdentityIds.{sourceType}
```

The approved request remains historical evidence of the earlier approval and receives `unlinkedAt` while staying in the `approved` state.

Event, participant, match result, and other source records are not modified or deleted.

Relink always starts a new request and confirmation code, even if the same profile was previously approved.

## Firestore access boundary

Registered users can:

- create their own link request,
- read their own active request lock/request,
- query their own request history with an owner constraint,
- supersede or cancel their own pending request,
- read their own active mapping only when required for account state/unlink,
- unlink their own active mapping atomically.

Users cannot:

- list active mappings,
- read another user's mapping or request,
- query another user's request history,
- read administrator audit records,
- create an approved mapping directly,
- write arbitrary `externalIdentityIds` values.

Approval/rejection, audit creation, and mapping creation intentionally remain denied by the current rules. Those operations become available only after the admin-role foundation under #198 is implemented and #213 connects the minimal administrator confirmation flow.

## Admin operation boundary

`FirestoreExternalIdentityLinkRepository` already contains fail-closed transaction operations for approval/rejection so #213 can reuse the same domain logic.

Before those calls are usable from the Web client, #198 must introduce the minimum admin-role authorization and the Firestore Rules must explicitly permit the corresponding admin reads/writes.

Approval rechecks the request, code hash/expiry, user document, active request lock, source-side mapping uniqueness, per-user source uniqueness, and absence of an earlier audit record immediately before writing.

## Firestore Rules tests

The external identity rules are covered by Emulator-based tests in:

```text
test/firestore_rules/external_identity_rules.test.js
test/firestore_rules/external_identity_user_read_rules.test.js
```

The tests use `@firebase/rules-unit-testing` with `demo-*` project IDs, so they never target the production Firestore project.

The Firestore Emulator requires Java. Use Java 21 for the local test environment.

Install/update the Node dependencies after pulling changes:

```bash
npm install
```

Run the Rules suite with:

```bash
npm run test:firestore-rules
```

The command starts only the Firestore Emulator through `firebase emulators:exec`, loads the repository `firestore.rules`, executes the Node test suite, and shuts the emulator down afterward.

Coverage includes:

- registered / anonymous / unauthenticated request creation,
- required `users/{uid}` existence,
- canonical TennisBear identity validation and seven-day expiry limit,
- duplicate mapping and one-identity-per-source constraints,
- atomic reissue and cancel transitions,
- protected `externalIdentityIds` mutation,
- atomic unlink across mapping / user pointer / request history,
- denial of ordinary-user approval, mapping creation, and admin audit access,
- cross-user read denial,
- owner-constrained request-history queries,
- denial of unscoped or cross-user request-history queries,
- regression coverage for existing event / team schedule / core rules.

Admin approval itself is intentionally not an allow-case in #211/#212; it remains denied until the #198 admin-role foundation and #213 are implemented.

## Deliberately not implemented here

- event participant external identity persistence
- event-import-time mapping lookup
- Lanske-user badge/display-name replacement in imported events
- participant-event lookup from a mapping
- event access requests
- personal event view
- statistics batch/schema/My Page statistics
- TennisBear user detail enrichment
- permanent `/admin` UI
- permanent My Page placement for the profile-link card

These items should be reconsidered after #195 is complete and split into existing/new issues only when their privacy and permission boundaries are ready.
