# Anonymous event ownership transfer

## Purpose

When an anonymous Firebase user attempts to link credentials that already belong
to an existing Lanske account, the anonymous UID cannot be preserved by ordinary
provider linking.

The ownership-transfer flow moves only doubles-event ownership from that
anonymous source UID to the authenticated existing-account UID.

This is not a general account merge.

## Security model

The transfer requires evidence from both sides.

```text
anonymous source Auth
  -> creates eventOwnershipTransfers/{sourceUid}
  -> random handoff secret is stored with the request

local browser handoff
  -> keeps sourceUid + handoff secret across reload

existing registered account Auth
  -> writes the same secret as handoffSecretProof
  -> transfer becomes accepted

accepted transfer
  -> target may query events owned by sourceUid
  -> target may change only event.ownerUid + event revision metadata
```

A client-supplied source UID, public event ID, shared URL, local schedule history,
or admin role is not sufficient authorization.

## Transfer record

Transfers use:

```text
eventOwnershipTransfers/{sourceUid}
```

A pending record contains the source UID, a cryptographically random handoff
secret, server timestamps, and a bounded pending lifetime.

Only the currently authenticated pure Anonymous user whose UID equals
`sourceUid` may create or refresh this pending record.

The browser keeps the handoff context in `localStorage`. This local value is a
bearer handoff secret, but it is not sufficient on its own: Firestore also
requires the server-side pending transfer record and an authenticated registered
target account.

## Account switch

A collision does not immediately sign out the anonymous source.

The flow is:

1. detect the existing-account credential collision;
2. while the Anonymous session is still active, create the pending transfer;
3. store the handoff context locally;
4. show the prepared-transfer UI;
5. only after the user chooses to continue, sign out the Anonymous source;
6. use the ordinary existing-account login flow;
7. resume ownership transfer after the registered target account is authenticated.

If target login fails, the handoff remains in browser local storage and the
user can retry login without creating a new transfer.

If the page reloads or the browser is restarted before expiry, the account page exposes a resume action
for the saved handoff.

## Target acceptance

The target account cannot read a pending transfer before acceptance.

Acceptance is an update that must satisfy all of the following in Firestore
Rules:

- the caller is a registered Lanske Firebase account;
- target UID equals `request.auth.uid`;
- target UID differs from source UID;
- the pending transfer has not expired;
- `handoffSecretProof` equals the source-created handoff secret;
- acceptance timestamps and the short accepted authorization window are valid.

Admin role provides no bypass.

The accepted authorization window is short and can be refreshed by the same
target with the same handoff proof during retry. A completed record can also be
refreshed back to accepted when a client did not receive the completion response,
so completion is idempotent across ambiguous network failures.

## Event migration

After acceptance, the target queries:

```text
events where event.ownerUid == sourceUid
```

Firestore Rules permit this query only while the accepted transfer identifies the
current target account.

Each event is migrated independently using a Firestore transaction.

The write re-checks the latest event and changes only:

- `event.ownerUid`
- `event.revision`
- `event.updatedAt`
- `provenance.lastWrittenFrom`

All other event, player, court, share, and schedule fields remain unchanged.

Legacy events without `ownerUid` cannot be claimed by this flow.

## Retry and partial failure

Events are not moved in one large batch.

For example, if three events exist and the first succeeds while the second fails,
a retry queries `sourceUid` again. The already moved event is no longer returned,
so only the remaining events are retried.

The repository also treats a direct retry of an event already owned by the target
as an idempotent no-op.

The transfer record is marked completed only after no remaining source-owned
event from the current query needs migration. The local handoff is cleared only
after completion succeeds.

This keeps prepare, accept, per-event migration, and completion retryable without
rolling successful event transfers back.

## Cancellation

While the original Anonymous source session is still active, the user may stop
the prepared flow locally and continue normal no-login use.

The local handoff is cleared. The server-side pending request becomes unusable
without its random handoff secret and expires automatically.

After the Anonymous source is deliberately signed out to authenticate the target,
the UI does not offer this local cancellation path because that Anonymous Auth
identity cannot simply be recreated.

## Boundaries

This flow does not implement:

- new-account provider linking;
- general Lanske account-to-account merge;
- account deletion ownership handling;
- legacy ownerless event claims;
- admin ownership takeover;
- team-schedule ownership transfer;
- external-identity mapping merge.

The ordinary event permission model remains unchanged: `ownerUid` is immutable
for normal event updates. This transfer flow is the only dedicated exception.
