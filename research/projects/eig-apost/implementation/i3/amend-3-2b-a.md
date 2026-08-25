# I3.2 host staging dependency Revision A

## Status and scope

- **Amendment ID:** `I3.2-SAME-CERTIFICATE-HOST-STAGING-REV-A`
- **Date:** 2026-08-25
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `REVIEW PENDING`
- **Dependency preflight:** `NOT AUTHORIZED`
- **Host staging retry:** `NOT AUTHORIZED`
- **Formal MATLAB run:** `NOT AUTHORIZED`

This is a forward-only execution amendment to
[[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]]. It
changes only the host dependency gate that precedes certificate staging. The
frozen design, all three MATLAB sources, `stage_fbie_input.py`, the staged-input
schema, numerical levels, thresholds, `ecap-a1` tag, and formal MATLAB command
remain unchanged. It does not authorize installation, preflight, staging,
`checkcode`, MATLAB, or Octave.

## 1. Preserved failed staging history

The separately authorized host command used the system `python3`, resolved to
`/usr/bin/python3`, and exited with shell status 1 before reading the historical
MAT file because importing SciPy failed. The exact producer message was:

```text
staging requires a host Python environment with scipy
```

Revision A classifies this first launch as `HOST_SCIPY_UNAVAILABLE` and records
the following append-only history:

| Item | Frozen value |
|---|---|
| completed host staging launches | 1 |
| next host staging `retry_count` | 1 |
| formal MATLAB launches | 0 |
| formal MATLAB `retry_count` | 0 |
| `ecap-a1` formal tag | unconsumed |
| staged target | absent |
| temporary staging files | absent |
| `ecap-a1` output | absent |

The immutable `fbie-a1` source artifact and report retain their previously
audited identities. The failed host launch created no input, output, temporary
MAT file, or scientific result. It therefore cannot be relabeled as a formal
`ecap-a1` attempt and cannot change any ordinary anchor or diagnostic.

## 2. Revision A host dependency

Revision A selects the Codex bundled runtime as the only candidate host
interpreter:

```text
bundle: 26.819.11345
python: /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3
```

No package may be installed, upgraded, downgraded, vendored, or obtained by a
fallback under this amendment. In particular, the project `octave`
environment, the system Python, and MATLAB/Octave are not alternative staging
backends. The bundle and absolute interpreter path are execution metadata only;
they do not enter the staged scientific variable or the formal MATLAB runtime.

Read-only filesystem inspection found NumPy but no bundled SciPy distribution
under this runtime. That inspection neither imports Python modules nor decides
whether an external or user-site package could affect a future interpreter
launch. Only the separately authorized preflight below can decide runtime
availability. The known bundle state therefore does not close the dependency
and is not permission to alter it. Unless that preflight later succeeds, the
only valid outcome remains `HOST_SCIPY_UNAVAILABLE`, with the target absent.

## 3. Locked read-only dependency preflight

The first future action, if separately authorized, is exactly this read-only
command from the repository root:

```console
/Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -c "import io,json,sys,numpy,scipy; from scipy.io import loadmat,savemat; assert sys.version_info>=(3,9); key='revision_a_long_field_name_probe_123456789'; b=io.BytesIO(); savemat(b,{'probe':{key:numpy.array([1.0])},'vector':numpy.array([1.0,2.0])},long_field_names=True,oned_as='column'); raw=b.getvalue(); simple=loadmat(io.BytesIO(raw),simplify_cells=True); plain=loadmat(io.BytesIO(raw)); flags={'python_ge_3_9':True,'loadmat_simplify_cells':isinstance(simple['probe'],dict) and key in simple['probe'],'savemat_long_field_names':isinstance(simple['probe'],dict) and key in simple['probe'],'savemat_oned_as_column':numpy.asarray(plain['vector']).shape==(2,1)}; assert all(flags.values()); print(json.dumps({'python':sys.version.split()[0],'numpy':numpy.__version__,'scipy':scipy.__version__,'flags':flags},sort_keys=True))"
```

The preflight does not open the historical artifact, create a directory, or
write any file. Its in-memory MAT roundtrip exercises the exact
`loadmat(...,simplify_cells=True)` and
`savemat(...,long_field_names=True,oned_as='column')` interfaces used by the
stager. It passes only if Python is at least 3.9, all imports and assertions
succeed, every recorded interface flag is true, the three versions are
nonempty plain strings, and the process exits 0. The exact stdout and shell
status must be copied into the Revision A review before any staging
authorization. A missing dependency, import error, nonzero status, malformed
version record, false interface flag, or failed in-memory roundtrip is
`HOST_SCIPY_UNAVAILABLE`; there is no fallback and no staging command may be
issued.

The preflight is deliberately an availability and interface-compatibility gate,
not a proof that the historical MAT object will decode. Source identity, source
schema, MATLAB-string decoding, field whitelist, dimensions, and finite-value
checks remain the unchanged stager's responsibility. The current known bundle
does not supply SciPy, so this amendment does not authorize or specify any
dependency provision; that would require a separate reviewed contract.

## 4. Locked retry command and precedence

Only after a recorded successful preflight and a second explicit authorization
may the existing stager be invoked. The sole retry command is:

```console
/Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 test/i3/e-cap/stage_fbie_input.py --source test/i3/fb-resid/output/fbie-a1/result.mat --target test/i3/e-cap/input/fbie-a1-certificate.mat
```

It must run from the repository root, and the target must still be absent. The
unchanged stager first checks the immutable source identity, then performs the
same whitelist and schema checks, writes one temporary MAT file, and publishes
the target by a no-overwrite atomic link. Failure preserves target absence and
does not authorize a changed path, dependency, stager, schema, or retry.

Failure precedence is frozen as follows:

1. dependency preflight failure: `HOST_SCIPY_UNAVAILABLE`;
2. target already exists: `STAGING_TARGET_ALREADY_EXISTS`;
3. source absent or identity/schema/string/field check fails:
   `CERTIFICATE_INPUT_UNAVAILABLE` with the original first message;
4. temporary write or atomic publication fails: `STAGING_EXECUTION_UNAVAILABLE`;
5. only shell exit 0 plus a newly existing target completes staging.

No staging outcome is a numerical result. A successful target would authorize
neither `checkcode` nor the formal MATLAB command; each remains a later,
independent gate.

## 5. Provenance and claim boundary

If staging is eventually successful, host-only provenance must retain both the
first failed system-Python launch and the successful retry, including
interpreters, shell statuses, exact dependency-preflight stdout, and
`retry_count=1`. The formal MATLAB entry continues to load only `staged`; it
must not read host provenance, interpreter paths, dependency versions,
historical output, Markdown, or hashes.

Revision A changes no certificate coordinate, density, QZ state, propagation
map, lift rule, component factor, empirical-cap formula, threshold, warning, or
claim flag. It therefore cannot repair or weaken any scientific qualification
gate in [[test/i3/e-cap/README|the e-cap experiment contract]].

## 6. Mechanical acceptance checklist

- [ ] `design-3-2b.md` is byte-identical to its frozen snapshot.
- [ ] The three MATLAB sources and `stage_fbie_input.py` are byte-identical to
      their spec-to-code PASS snapshot.
- [ ] The historical `fbie-a1` result and report are byte-identical.
- [ ] The staged target, temporary staging files, and `ecap-a1` output are absent.
- [ ] The first host failure is recorded as `HOST_SCIPY_UNAVAILABLE`.
- [ ] Host staging retry count is 1; formal retry count is 0.
- [ ] Researcher--Engineer agree on this bounded dependency amendment.
- [ ] Skeptic passes the amendment before dependency preflight is run.
- [ ] A successful preflight receives separate staging authorization.
- [ ] No fallback, installation, staging, `checkcode`, MATLAB, or Octave occurs
      under this document alone.
