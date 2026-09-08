# Firebase external identity link foundation

This document describes the Firestore/domain foundation introduced by web #211.

## Scope

The foundation links a registered Lanske user to an approved public identity from an external service.

The first supported source is TennisBear, but the model keeps `sourceType` separate from `sourceUserId` so additional sources such as TennisOff can be added later.

This issue does not connect imported event participants to approved mappings at runtime and does not implement personal statistics.

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
approvedAt / approvedBy
rejectedAt / rejectedBy
canceledAt
unlinkedAt
supersededByRequestId
```

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

The system validity period is seven days. User-facing UI in #212 will ask the user to send the code through TennisBear chat within about one hour; that one-hour period is an operational prompt, not a hard expiry.

Reissue always creates a new code and supersedes the old request. The old expiry is never extended.

## TennisBear URL validation

The initial parser accepts a public profile URL only and canonicalizes it to:

```text
https://www.tennisbear.net/user/{numericUserId}/info
```

No external fetch is performed during request creation. Actual profile ownership is checked later through the manual confirmation flow.

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
- supersede or cancel their own pending request,
- read their own active mapping only when required for unlink,
- unlink their own active mapping atomically.

Users cannot:

- list active mappings,
- read another user's mapping or request,
- create an approved mapping directly,
- write arbitrary `externalIdentityIds` values.

Approval/rejection and mapping creation intentionally remain denied by the current rules. Those operations become available only after the admin-role foundation under #198 is implemented and #213 connects the minimal administrator confirmation flow.

## Admin operation boundary

`FirestoreExternalIdentityLinkRepository` already contains fail-closed transaction operations for approval/rejection so #213 can reuse the same domain logic.

Before those calls are usable from the Web client, #198 must introduce the minimum admin-role authorization and the Firestore Rules must explicitly permit the corresponding admin reads/writes.

Approval rechecks the request, code hash/expiry, user document, active request lock, source-side mapping uniqueness, and per-user source uniqueness immediately before writing.

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

These items should be reconsidered after #195 is complete and split into existing/new issues only when their privacy and permission boundaries are ready.
