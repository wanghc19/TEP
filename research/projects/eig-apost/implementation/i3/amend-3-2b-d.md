# I3.2 host staging-success event publication contract

## Status and scope

- **Amendment ID:** `I3.2-SAME-CERTIFICATE-STAGING-EVENT-A1`
- **Date:** 2026-08-25
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `NOT REVIEWED`
- **Event publication:** `NOT AUTHORIZED`
- **Formal MATLAB run:** `NOT AUTHORIZED`

This forward amendment records the completed host staging retry required by
[[research/projects/eig-apost/implementation/i3/amend-3-2b-a|Revision A]],
[[research/projects/eig-apost/implementation/i3/amend-3-2b-b|the isolated host provision contract]],
and
[[research/projects/eig-apost/implementation/i3/amend-3-2b-c|the preflight event contract]].
It does not rerun staging, parse or modify the staged MAT file, edit any prior
host event, start MATLAB, or change a scientific source, design, schema, level,
threshold, or attempt tag.

The separately authorized staging retry completed once with shell exit 0 in
1.495451792 seconds and empty stdout. It created exactly one staged input with
mode `0600` and size 40978143 bytes. The partial environment and formal output
remained absent. Host staging has retry count 1; formal MATLAB has zero launches,
retry count 0, and the `ecap-a1` tag remains unconsumed.

## 1. Frozen staging evidence

The exact successful command from the repository root was:

```console
PYTHONNOUSERSITE=1 /private/tmp/tep-i32-ecap-dep-a1/bin/python3 -I test/i3/e-cap/stage_fbie_input.py --source test/i3/fb-resid/output/fbie-a1/result.mat --target test/i3/e-cap/input/fbie-a1-certificate.mat
```

Its shell status is exactly 0, wall time is exactly 1.495451792 seconds, and raw
stdout is the empty byte string. These are fixed observations from the completed
command, not values reconstructed by invoking the stager again.

The target's exact identity, historical source identity, stager identity, and
the provision/preflight event identities are frozen in the machine-side
recorder. This human-facing amendment does not reproduce hashes. The staged
target's exact reviewed MAT interface is:

- top-level variables `staged` and `staging_provenance` only;
- `staged.input_contract.schema = TEP_I3_2_STAGED_FBIE_A1_CERTIFICATE_V1`;
- `staging_provenance.source_path_at_staging` is the absolute immutable
  `fbie-a1/result.mat` path in this worktree;
- `staging_provenance.host_tool = stage_fbie_input.py`;
- `staging_provenance.formal_runtime_variable = false`;
- `staging_provenance.generated_utc = 2026-08-24T17:24:44.937413+00:00`.

The source identity inside `staging_provenance` agrees with the historical
source and the stager's frozen constant. The target's exact byte identity binds
the listed schema/provenance values to the separately completed read-only host
MAT audit; the recorder does not parse the MAT again.

## 2. Recorder and unique command

The sole recorder is `test/i3/e-cap/record_staging_event.py`. It uses only the
standard library and accepts no arguments. If separately authorized, its unique
command from the repository root is:

```console
PYTHONNOUSERSITE=1 /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -I test/i3/e-cap/record_staging_event.py
```

Before writing, it must verify:

1. the frozen bundled base interpreter and `PYTHONNOUSERSITE=1` invocation;
2. the nonsymlink final environment with mode `0700` and nonsymlink provenance
   directory;
3. exact immutable provision and preflight event identities plus their expected
   status and formal-unconsumed history;
4. the exact historical source and unchanged stager identities;
5. the staged target as a regular nonsymlink file with exact mode, size, and
   reviewed byte identity;
6. absence of the partial environment, formal output, and target staging event.

The recorder hashes but does not parse the source or staged MAT file. It does
not import NumPy/SciPy, run the provisioned interpreter, rerun staging, create a
new staged target, or start MATLAB.

## 3. Append-only staging event

The only target is:

```text
/private/tmp/tep-i32-ecap-dep-a1/host-provenance/staging-a1.json
```

It is created with `O_CREAT|O_EXCL`, mode `0600`, a complete JSON write, flush,
and `fsync`. An existing event, missing or altered prerequisite, target identity
failure, write error, or unexpected history is
`HOST_STAGING_EVENT_RECORD_UNAVAILABLE`. There is no overwrite, repair,
fallback, automatic retry, MAT parsing, staging rerun, or MATLAB launch.

The event records:

- the exact successful command, exit status, elapsed time, empty stdout and its
  identity;
- completed host staging launches 2, retry count 1, and the first
  `HOST_SCIPY_UNAVAILABLE` outcome followed by the successful isolated retry;
- target path/mode/size/identity, top-level variables, schema, and exact
  `staging_provenance` fields;
- source, stager, provision, preflight, and recorder identities;
- absent partial/formal-output guards and formal launches 0/retry 0/tag
  unconsumed;
- next gate `SEPARATE_FORMAL_MATLAB_AUTHORIZATION` and
  `formal_matlab_must_not_read=true`.

The event remains an ephemeral `/private/tmp` host record. It is not a formal
scientific artifact and cannot establish a numerical or spectral claim.

## 4. History, claims, and next gate

The first ambient system-Python staging launch ended with shell exit 1 and
`HOST_SCIPY_UNAVAILABLE`; it created no target. The isolated retry described
above is the only successful staging launch. Recording these observations does
not retroactively change the immutable provision or preflight events.

The staged target is an explicit certificate input, not a result. Successful
event publication establishes only the reviewed host staging history and exact
input identity. It does not validate MATLAB portability, evaluate a cap, consume
`ecap-a1`, or authorize the formal command. The classification-only checkcode
preflight is a separate read-only event; its style-only findings do not replace
formal authorization.

The formal MATLAB entry loads only `staged`. It must never read
`staging_provenance`, host-event JSON, dependency paths or versions, Markdown,
hashes, Git state, or historical output. All reliable, certified, independent,
gap, existence, and upper-bound flags remain false.

## 5. Acceptance checklist

- [ ] Staged target, source, stager, provision, and preflight identities match
      the completed read-only audit.
- [ ] Exact successful command, status 0, time 1.495451792, and empty stdout are
      frozen once.
- [ ] Top-level variables, target schema, and exact staging provenance agree
      with the reviewed target.
- [ ] Partial environment, formal output, and target staging event are absent.
- [ ] Recorder is standard-library only and neither parses MAT nor reruns
      staging/preflight/provision/MATLAB.
- [ ] Event publication uses `O_EXCL`, mode `0600`, flush, and `fsync`.
- [ ] Host retry count is 1; formal launches/retry are 0 and tag is unconsumed.
- [ ] Failure permits no overwrite, fallback, automatic retry, or formal run.
- [ ] Success opens only a separate formal-MATLAB authorization review gate.
- [ ] Researcher--Engineer agree and Skeptic passes before publication.
