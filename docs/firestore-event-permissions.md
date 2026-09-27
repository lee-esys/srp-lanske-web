# Firestore event permissions

## Purpose

Doubles events use a public share URL while keeping structural event editing under
the event owner.

Firestore Security Rules are the final write-authorization boundary. Presentation
capabilities may hide owner-only actions, but Rules must reject the same write
when it is sent directly to Firestore.

## Access model

The event document ID is the public share ID:

```text
events/{publicId}
```

Direct document access and collection queries have different responsibilities.

```text
known publicId
  -> direct get
  -> shared operational writes

current Firebase Auth UID
  -> query where event.ownerUid == current UID
  -> owner event list
```

Rules do not grant an admin-role override for ordinary event ownership.

## Event creation

A new event requires Firebase Authentication, including Anonymous Auth.

The new document is accepted only when:

- `event.ownerUid == request.auth.uid`
- `event.publicId == {publicId}`
- `share.publicId == {publicId}`
- the share event ID matches the event ID
- the initial schema and provenance metadata are valid

A signed-out client cannot create an owner-bearing event, and an authenticated
client cannot choose another UID as `ownerUid`.

## Reads and ownership queries

A client that knows `publicId` may directly read the event document so existing
shared URLs remain usable without login.

Collection listing is different. An authenticated client may query only documents
whose `event.ownerUid` equals its own Firebase Auth UID. The repository therefore
uses:

```text
where event.ownerUid == current UID
```

for ownership listing.

Shared operations do not use an event-ID collection query. Event updates use the
known `publicId` document path directly.

## Event updates

Rules separate event updates by responsibility instead of allowing an owner to
replace the whole document.

### Owner-only structural updates

The following fragments require the current Auth UID to match the saved
`event.ownerUid`:

- event title / memo and player display data
- court display settings

The corresponding event and fragment revisions must advance as expected.

### Shared operational updates

The following state transitions remain available through a shared URL without
requiring ownership:

- setting a newly generated schedule as the current schedule
- adopting the current generated schedule

These transitions may update only their bounded event state fields and revision
metadata. Structural fragments cannot be changed in the same write.

### Immutable ownership

`event.ownerUid` is not part of any ordinary update transition.

Legacy events without `ownerUid` therefore remain shared-only: they can continue
approved operational transitions, but they cannot acquire structural-edit
permission or assign themselves an owner through a normal update.

A future ownership-transfer flow must have its own explicitly bounded Rules path.

## Progress and match writes

Shared collaboration remains enabled under:

```text
events/{publicId}/schedule_progress/{generatedScheduleId}
events/{publicId}/schedule_progress/{generatedScheduleId}/matches/{matchKey}
```

Rules validate the schedule identity fields and permit only operational progress
or match-result fields to change after creation. Identity fields such as schedule
type, generated schedule ID, round number, court number, match number, and
creation timestamp cannot be changed by normal updates.

Team schedule Rules are unchanged by this event permission work.

## Provenance

Firestore provenance metadata remains part of the write contract.

- `createdFrom` is immutable after document creation.
- `lastWrittenFrom` may change on later writes.
- a legacy document without provenance may add `lastWrittenFrom` on its next
  supported update without inventing `createdFrom`.

## Verification

Event permission Rules are covered by:

```text
test/firestore_rules/event_permission_rules.test.js
```

Run the complete Rules suite with:

```bash
npm run test:firestore-rules
```

The emulator suite uses the existing `demo-lanske-rules` project configuration
and does not target the production Firestore project.
