# Lanske account Plan

## Purpose

web #220 introduces the minimum Plan foundation for registered Lanske
accounts.

Plan is the account's contract/tier state and remains separate from:

- Role: for example, `user` / `admin`
- Entitlement: actual feature availability and limits
- Permission: operations allowed for a specific resource
- Usage: actual consumption counted against a limit

The initial Plan values are:

```text
free
premium
```

This issue does not implement payment, subscription lifecycle, pricing, or
Premium feature definitions.

## Storage

Plan is stored as a protected field on the registered Lanske user document.

```text
users/{firebaseAuthUid}
  schemaVersion: 1
  createdAt: Timestamp
  plan: free | premium
  externalIdentityIds: Map<String, String> // optional
```

New registered-account documents created by the current client explicitly set:

```text
plan: free
```

Existing user documents created before web #220 may not contain `plan`.
A missing field is interpreted as `free`, so no migration is required for
the initial rollout.

Only a missing field receives this compatibility default. Unknown stored
values fail closed as invalid data instead of being treated as Premium.

## Current Plan lookup

`PlanReader` is the application-facing interface for current Plan lookup.

`CurrentAccountPlanReader`:

- returns `null` for signed-out sessions
- returns `null` for Anonymous Auth sessions
- resolves the registered account's `LanskeUser.plan` for account sessions

This keeps Plan off `AuthSession`; authentication state and contract state
remain separate responsibilities.

## Write protection

The Flutter client does not expose a Plan-change operation.

Firestore Security Rules allow a registered account to create its own user
document only with either:

- `plan: free`, or
- no `plan` field, for short-lived backward compatibility with an older
  deployed client

A client-created user document cannot start as `premium`.

After creation, ordinary account updates cannot change `plan`. The admin
Custom Claim from web #216 does not grant Plan mutation rights either.

A future payment/backend/operations flow may update Plan from a trusted
environment. That write path is intentionally outside web #220.

## Separation from admin Role

Administrator state remains in Firebase Authentication Custom Claims:

```text
admin: true
```

Plan remains in Firestore.

An administrator is not automatically Premium, and Premium does not imply
administrator access.

web #221 builds Entitlement resolution on top of this separation.
