# Privacy-safe participation history (#250)

## Boundary

`events/{publicId}` contains title, memo, players, source URL and the share
capability. A linked participant must **never** gain event list access from
participation alone. Known publicId access is a separate legacy share policy.

The online My Page read model is:

```text
externalIdentityParticipationHistories/{mappingId}/events/{eventId}
  schemaVersion: 1
  eventId: internal event UUID (not publicId)
  sourceType: tennisbear
  sourceUserId: external user ID string
  eventDate: Firestore Timestamp | null
  selfSnapshot: {
    sourceDisplayName: string
    levelId: int | null
    levelName: string | null
    observedAt: Timestamp | null
  } | null
  statisticsEligible: boolean
  updatedAt: Timestamp
```

The external identity key is `sourceType + "_" + sourceUserId`, matching
`externalIdentityMappings/{mappingId}`. Do not add event title, memo, owner
UID, other players, partner/opponent, source URL, share/public ID or unbounded
source snapshot fields. The internal eventId is only a stable deduplication
key; never turn it into an event-opening URL.

Only registered users with a matching *active* mapping can list/get the nested
event documents. Reads are independent of event ownership or share access.
Unlink removes the active mapping and revokes these reads without erasing the
underlying projection. Re-link re-enables history for the same external identity.

The Flutter repository resolves the approved mapping through the existing
`ExternalIdentityUserReader.getActiveMapping` and then calls
`listByMappingId(mappingId: mapping.id)`. UI integration belongs to #251.
Queries order by `eventDate desc`; missing event dates must be represented as
`null`, not omitted, to participate in ordered queries. The single-field
index is automatic; no composite index is required for this query.

## Writes and trust boundary

**All Firestore client creates, updates and deletes are denied**, including
admin-claim clients. A server-side trusted projector using Admin SDK/IAM must
validate the source independently before publishing documents. It cannot
treat `events/{publicId}.players[].externalIdentity` as conclusive evidence:
event owner clients currently control player identity input and owner display
updates can replace player array elements. A mere Admin SDK copy of
client-authored player identity would create a false attribution risk.

Trusted producer contract:
1. Resolve the source event and independently verify the external participant
   identity `sourceType + sourceUserId`.
2. Match verified participants to the appropriate event / player. Fail closed
   when source evidence is missing, ambiguous, or stale; never use display-name
   equality as a substitute.
3. Write only the strict fields above, with stable internal eventId and a
   real Firestore timestamp; upsert idempotently.
4. On verified event changes, reconcile additions, updates and removals;
   maintain a way to rebuild and remove stale projections.
5. Do not attach ownership, share permissions or statistics computation to the
   projection process.

The current Flutter client **does not publish projections**. Until a trusted
source-verification producer is deployed, the history query can correctly
return an empty result; this must not be presented as evidence that the user
has never participated. A future producer should keep its independent source
verification and backfill/reconciliation strategy explicit rather than
silently treating client event data as trusted.

Match-level advanced statistics remain in local PostgreSQL + batch, outside
this Firestore projection. Owner-managed guest invitations (#260) may later
reuse the domain representation but require their own identity provenance and
consent boundary.
