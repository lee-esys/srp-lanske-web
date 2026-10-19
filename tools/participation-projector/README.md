# Trusted participation projector (#261)

This is an **operator-run reconciliation command**, not a browser feature or a
deployed always-on trigger. It writes Firestore as a Google service identity
(Admin SDK) and checks current TennisBear event participants by calling the
existing Core `POST /.../tennisbear/import-preview` endpoint. Use the exact
preview endpoint URL configured for your environment; do not guess it.

## Security model

- Requires a service identity authorized for the intended Firestore project.
  Never use a service-account JSON key in the repository or browser.
- Dry run is the default. Writes require `--apply` and
  `CONFIRM_PROJECT_ID=<target>`.
- Firestore Rules continue to **deny all client projection writes**.
- Only TennisBear event records with matching canonical event source references
  and validated UUIDs are candidates. The trusted Core response must match
  the source event ID, and the participant's numeric source user ID must appear
  unambiguously in the independently fetched participant list.
- Event owners still control which Lanske player receives an external user ID
  and which source event is attached to their Lanske event. **This is verification
  of public event participation, not independent proof of the Lanske match
  outcome, nor strong immutable provenance of the event import.** Treat these
  projections as owner-recorded participation. Verification ambiguity fails
  closed.
- The projection exposes no title, source URL, share ID or other players.
- It includes `isConfirmed` from the saved Lanske event's `adopted` status and `participantCount` from active Lanske event players. This is owner-maintained event metadata, not independently verified participant-count evidence.
- My Page displays only `isConfirmed: true` documents. Existing projections lacking this field are considered unconfirmed until an explicit operator-run re-projection. Re-running the projector is required after this schema addition; a Web rebuild does not backfill Firestore documents.
- This tool uses `participationProjectionStates/{eventId}` as a private write
  index for reconciliation (deletion disabled for now). No client access to that collection.
- A source fetch/verification failure does **not** delete existing projections.
  The run logs a failure and exits nonzero; rerun after recovery. Existing
  entries may therefore be stale until a future deletion-safe reconciliation.
  Unlink revokes read via existing mapping Rules without deleting projections.
- **All automatic deletes are disabled**: missing members, missing events,
  duplicate event identities, invalid sources, and incomplete responses must
  never trigger a projection removal. Existing mappingIds are retained when
  new candidates are added. Deletion requires future Core completeness
  guarantees (core #175) and Web follow-up implementation.

## Run

From `tools/participation-projector`:

```bash
npm install
npm test

export FIREBASE_PROJECT_ID='<dev-project-id>'
export LANSKE_TENNISBEAR_PREVIEW_URL='<full-existing-preview-endpoint>'
# Authenticate to Google with an appropriate dev service identity/ADC.
node run.cjs                      # dry run: NO WRITES
node run.cjs --event-id XTR1HOMN  # one events/{publicId} document only

export CONFIRM_PROJECT_ID="$FIREBASE_PROJECT_ID"
node run.cjs --apply              # explicit writes, inspect first
```

The JSON summary now includes a `diagnostics` breakdown:

- `scanned` / `nonTennisbearEvents` / `tennisbearEvents`
- `validSourceEvents` / `invalidSourceEvents`
- `withExternalIdentity` / `missingExternalIdentity` (event counts)
- `verifiedEvents` / `matchedEvents` / `noMatchingPlayers`
- `projectionCandidates` (participant rows, not events)
- `statisticsEligibleTrue` / `statisticsEligibleFalse` (breakdown of the projection candidates; this is the stored event flag, not a score-derived calculation)
- `fetchOrVerifyFailures`, `duplicateEventIds`, `invalidEventIds`

Per-event logs include `non_tennisbear`, `invalid_source`,
`legacy_no_identity`, `no_verified_match` or `verified_match`.
A `legacy_no_identity` event may still be fetched to independently inspect
its source; it does not produce projections. `processed` counts events that
finished reconciliation, including skipped events; it does **not** count
verified TennisBear events. This diagnostic scan remains read-only in dry-run.

The `--event-id` value is the **Firestore document ID/publicId** (such as `XTR1HOMN`), not the internal UUID. A scoped run reads one event only and **does not run the deleted-event cleanup sweep**. Logs now show `provenance.lastWrittenFrom.environment` / `appVersion` (falling back to `createdFrom`) when available; this is informational, NOT an apply filter.

The command scans current `events`, independently refetches each usable source
event, then upserts the privacy-safe per-identity projections. It **does not
remove** tracked records from deleted events, missing participants, or invalid
sources. It is safe to rerun and uses a fingerprint
to avoid writing unchanged projections. Note that the scan is a full-collection
read and makes one external request per eligible event, so control frequency
and cost. A failed verification sets a nonzero exit code.

## Limitations and deployment gates

- This is a **manual operator-run batch**. Automatic realtime event-triggered
  delivery, scheduler configuration, CI deployment and live environment
  verification are **not** implemented. They require a selected trusted
  infrastructure and configured service identity.
- Historical projections created before this index existed cannot be discovered
  safely without a separate inventory/backfill/migration.
- The event owner may change fields after source validation. The projector
  rechecks the current external participant list but cannot prove match results.
- No projections should be treated as externally verified match scores.
- Handle source availability and import HTML changes as operational failures.
  Do not bypass verification when the external source becomes unavailable.
- Large event collections require pagination/checkpointing before scheduling.
- Deletion handling is intentionally deferred. Projections for deleted events
  or removed participants can remain stale even after a full run. Before
  statistical use, rerun after the Core completeness contract and safe Web
  deletion handling are implemented.

See `docs/firebase-participation-history.md` for the consumer schema.
