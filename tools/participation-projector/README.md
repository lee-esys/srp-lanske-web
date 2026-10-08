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
- This tool uses `participationProjectionStates/{eventId}` as a private write
  index for deletion/reconciliation. No client access to that collection.
- A source fetch error causes existing corresponding projections to be removed
  (fail closed); rerun after recovery. Unlink revokes read immediately via
  existing mapping Rules and does not delete this projection.

## Run

From `tools/participation-projector`:

```bash
npm install
npm test

export FIREBASE_PROJECT_ID='<dev-project-id>'
export LANSKE_TENNISBEAR_PREVIEW_URL='<full-existing-preview-endpoint>'
# Authenticate to Google with an appropriate dev service identity/ADC.
node run.cjs                      # dry run: NO WRITES

export CONFIRM_PROJECT_ID="$FIREBASE_PROJECT_ID"
node run.cjs --apply              # explicit writes, inspect first
```

The command scans current `events`, independently refetches each usable source
event, then reconciles the privacy-safe per-identity projections. It removes
tracked records from deleted events. It is safe to rerun and uses a fingerprint
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
- For strict deleted-event handling, a production event-deletion trigger or
  regular full reconciliation is required. Until it exists, projections remain
  potentially stale between explicit runs.

See `docs/firebase-participation-history.md` for the consumer schema.
