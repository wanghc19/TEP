# I3.2 host preflight event publication contract

## Status and scope

- **Amendment ID:** `I3.2-SAME-CERTIFICATE-PREFLIGHT-EVENT-A1`
- **Date:** 2026-08-25
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `NOT REVIEWED`
- **Event publication:** `NOT AUTHORIZED`
- **Host staging retry:** `NOT AUTHORIZED`
- **Formal MATLAB run:** `NOT AUTHORIZED`

This forward amendment records the already completed host dependency preflight
required by
[[research/projects/eig-apost/implementation/i3/amend-3-2b-b|the isolated provision contract]].
It does not rerun the preflight, import NumPy or SciPy, edit the immutable
provision record, stage `fbie-a1`, or change any scientific source, design,
schema, level, threshold, or tag.

The separately authorized preflight completed once with shell exit 0 in
2.6695757909999998 seconds. It reported CPython 3.12.13, NumPy 2.3.2, SciPy
1.18.0, and true values for all four frozen in-memory MAT interface gates. The
staged input and formal output remained absent. The computational/API preflight
therefore passed, but staging remains locked until this evidence is published
as the append-only host event required by the provision contract.

## 1. Frozen evidence

The recorder embeds, byte for byte, the completed preflight's command and raw
stdout, including its final newline. The parsed record is exactly:

```json
{
  "flags": {
    "loadmat_simplify_cells": true,
    "python_ge_3_9": true,
    "savemat_long_field_names": true,
    "savemat_oned_as_column": true
  },
  "numpy": "2.3.2",
  "python": "3.12.13",
  "scipy": "1.18.0"
}
```

The shell status is exactly 0 and the wall time is exactly
2.6695757909999998 seconds. These are fixed observations supplied by the
completed authorized command, not values reconstructed by rerunning Python.

The machine-side recorder also freezes the reviewed provision-record identity.
That identity is stored only in `test/i3/e-cap/record_preflight_event.py`; this
human-facing amendment does not reproduce machine hashes. The provision JSON
must remain byte-identical and retain `dependency_preflight_run=false` and
`staging_retry_run=false`, because it is the earlier immutable event. The new
sibling, not an edit of the provision event, records the later successful
preflight.

## 2. Recorder and unique command

The sole recorder is `test/i3/e-cap/record_preflight_event.py`. It uses only the
standard library and accepts no arguments. If separately authorized, its unique
command from the repository root is:

```console
PYTHONNOUSERSITE=1 /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -I test/i3/e-cap/record_preflight_event.py
```

Before writing, it must verify:

1. it is running under the frozen bundled base interpreter with
   `PYTHONNOUSERSITE=1`;
2. the final environment exists as a nonsymlink directory with mode `0700`;
3. the partial environment, staged input, formal output, and target preflight
   event are all absent;
4. the provision record is a regular nonsymlink file with its exact reviewed
   identity;
5. the provision schema/status, host/platform, installed versions, immutable
   false preflight/staging flags, and formal-unconsumed history agree with the
   frozen evidence;
6. the embedded raw stdout parses to the exact three versions and four true
   flags above; shell status is 0 and wall time is positive.

The recorder must not inspect package code, import NumPy/SciPy, run the
provisioned interpreter, read the historical source artifact, or calculate a
new preflight value.

## 3. Append-only event

The only target is:

```text
/private/tmp/tep-i32-ecap-dep-a1/host-provenance/preflight-a1.json
```

It is created with `O_CREAT|O_EXCL`, mode `0600`, a complete JSON write, flush,
and `fsync`. An existing path, identity mismatch, missing path, unexpected
field, write error, or nonzero validation is
`HOST_PREFLIGHT_EVENT_RECORD_UNAVAILABLE`. There is no overwrite, repair,
fallback, automatic retry, preflight rerun, or staging.

The event records:

- exact command, status, elapsed time, raw stdout with newline, parsed versions
  and gates, and raw-stdout identity;
- provision-record path and identity plus recorder identity;
- `source_artifact_read=false` and the absent partial/input/output guards;
- host staging retry count 1 but `staging_retry_run=false`;
- formal launches 0, formal retry 0, and `ecap_a1_consumed=false`;
- next gate `SEPARATE_HOST_STAGING_AUTHORIZATION` and
  `formal_matlab_must_not_read=true`.

The event remains an ephemeral `/private/tmp` host record, not a formal
scientific artifact. If it is lost, incomplete, or inconsistent, staging is
unavailable; it may not be reconstructed silently.

## 4. Claim and authorization boundary

A valid event would establish only that the preregistered host dependency/API
preflight completed successfully. It would not validate source decoding,
whitelist extraction, numerical evaluation, empirical caps, spectral claims,
or MATLAB portability. It would not consume `ecap-a1` and would not authorize
staging by itself. Independent review of the new event must precede a separate
staging authorization.

The formal MATLAB entry must never read the provision or preflight event,
dependency paths, versions, host command, Markdown, hashes, or historical
output. All reliable/certified/independent/existence flags remain unchanged and
false.

## 5. Acceptance checklist

- [ ] Provision record and environment are unchanged; partial/input/output are
      absent.
- [ ] Exact command, raw stdout including newline, status 0, and wall time are
      frozen once.
- [ ] Parsed Python/NumPy/SciPy versions and four flags match the completed
      preflight.
- [ ] Recorder uses the bundled base Python and only the standard library.
- [ ] Recorder reads no historical source and imports no scientific package.
- [ ] Provision identity and all absence/history guards precede publication.
- [ ] Event publication uses `O_EXCL`, mode `0600`, flush, and `fsync`.
- [ ] Failure creates no staged input/output and permits no automatic retry.
- [ ] Success opens only the independent staging-authorization review gate.
- [ ] Researcher--Engineer agree and Skeptic passes before publication.
