# I3.2 isolated host dependency provision contract

## Status and authority

- **Amendment ID:** `I3.2-SAME-CERTIFICATE-HOST-PROVISION-A1`
- **Date:** 2026-08-25
- **Researcher--Engineer:** `AGREED`
- **Skeptic:** `REVIEW PENDING`
- **Provision:** `NOT AUTHORIZED`
- **Dependency preflight:** `NOT AUTHORIZED`
- **Host staging retry:** `NOT AUTHORIZED`
- **Formal MATLAB run:** `NOT AUTHORIZED`

This is the dependency-provision successor to
[[research/projects/eig-apost/implementation/i3/amend-3-2b-a|Revision A]] and a
forward execution amendment to
[[research/projects/eig-apost/implementation/i3/design-3-2b|design-3-2b]]. It
does not change the frozen design, the three MATLAB sources,
`stage_fbie_input.py`, certificate coordinates, schemas, numerical levels,
thresholds, `ecap-a1` tag, or formal MATLAB command. It authorizes nothing by
itself.

The first system-Python staging launch remains the append-only host failure
`HOST_SCIPY_UNAVAILABLE`: host retry count is 1, formal retry count is 0,
`ecap-a1` is unconsumed, and staged input and output are absent. Revision A
correctly stopped because the Codex bundle contains no bundled SciPy
distribution. This contract defines the only permitted isolated provision; it
does not retrospectively change that failure.

## 1. Frozen host and paths

The provision base is exactly:

```text
implementation: CPython
version: 3.12.13
platform: macOS arm64
base interpreter: /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3
```

The only final and partial directories are:

```text
final:   /private/tmp/tep-i32-ecap-dep-a1
partial: /private/tmp/tep-i32-ecap-dep-a1.partial
```

Both must be absent before provision. The staged target and formal
`output/ecap-a1` path must also be absent. The script does not modify the system
Python, Codex bundle, project `octave` environment, any other shared
environment, repository source, historical output, or staged input. It uses a
standard-library `venv` with copied launchers and installs only into the exact
partial directory. It atomically claims that partial with `mkdir(mode=0700)`;
cleanup ownership becomes true only after this call succeeds. Failure removes
only the partial directory created by this launch; it never deletes a
pre-existing partial or overwrites the final directory.

The provision and every future use of the environment require
`PYTHONNOUSERSITE=1` and Python isolated mode `-I`. Child commands remove
ambient `PYTHON*` and `PIP*` configuration, set `PIP_CONFIG_FILE` to the null
device, and use pip `--isolated`. User-site packages, `PYTHONPATH`, extra
indexes, pip configuration, system packages, and interpreter fallback are not
admissible inputs.

## 2. Frozen packages and official source

The sole package index is the [official PyPI simple index](https://pypi.org/simple).
The two required distributions are:

| Package | Exact version | Admissible CPython 3.12 arm64 wheels |
|---|---:|---|
| NumPy | `2.3.2` | macOS 11 arm64; macOS 14 arm64 |
| SciPy | `1.18.0` | macOS 12 arm64; macOS 14 arm64 |

The complete official wheel SHA-256 values are stored only in the machine-side
`test/i3/e-cap/requirements-host-a1.txt`. That file contains no source
distribution hash and no non-arm64 hash. The installer must use all of
`--only-binary=:all:`, `--no-deps`, and `--require-hashes`; it may not resolve,
build, upgrade, or download any other distribution. PyPI metadata for the
[NumPy release](https://pypi.org/project/numpy/2.3.2/) and
[SciPy release](https://pypi.org/project/scipy/1.18.0/) is the source locator,
not a runtime dependency of MATLAB.

The largest compatible pair of frozen wheels totals 42,866,549 bytes. The
100 MiB network value is a preregistered static planning cap, not a byte counter
implemented by pip or the provision script; official simple-index metadata is
variable. The 57 MiB margin above the largest wheel pair makes the planned
transfer conservative, and there are no transitive downloads because both
packages are explicit and `--no-deps` is mandatory. The artifact must record
`network_bytes_measured=false`; this contract must not report the planning cap
as a measured hard enclosure.

## 3. Unique provision command

The only provision implementation is
`test/i3/e-cap/provision_host_env.py`. It is a host utility using only the
Python standard library. If separately authorized, the unique command from the
repository root is:

```console
PYTHONNOUSERSITE=1 /Users/whc/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -I test/i3/e-cap/provision_host_env.py
```

The command accepts no arguments. Before creating a directory or opening the
network, it verifies the exact base interpreter, CPython 3.12.13, macOS arm64,
the absent final/input/output paths, one-open regular-file requirements bytes,
their exact frozen identity, and available disk space. It then performs exactly
these steps:

1. atomically create the partial directory with mode `0700`; a
   `FileExistsError` stops without cleanup ownership;
2. create the partial `venv` with copied launchers;
3. write the already opened and hash-verified requirements bytes exactly once
   with `O_EXCL` inside the owned partial tree;
4. invoke that partial environment's pip on this private snapshot, never the
   repository path, in isolated mode against the official index with
   binary-only, no-dependency, hash-required options;
5. read installed NumPy/SciPy versions from distribution metadata without
   importing them;
6. require exact versions `2.3.2` and `1.18.0`;
7. measure the complete partial directory and require at most 300 MiB;
8. write one host-only provision provenance record inside the partial tree;
9. publish with macOS `renamex_np(...,RENAME_EXCL)`, which atomically rejects a
   destination that appeared after the initial absence guard.

The machine-enforced pre-publication wall-time budget is 300 seconds. It covers
`venv`, download, installation, metadata audit, and disk measurement. The final
small JSON write, `fsync`, and exclusive rename occur after that last elapsed
check and are not claimed to lie inside its hard measurement. Pip gets no
retries and a 60-second socket timeout. Final disk is machine-enforced at
300 MiB. Network has the non-enforced 100 MiB static planning cap above. A
static pre-run estimate is less than 50 MiB of wheel/index transfer,
120--240 MiB final disk, and 30--180 seconds. These estimates are operational,
not scientific.

## 4. Failure and cleanup semantics

Any of the following is `HOST_DEPENDENCY_PROVISION_UNAVAILABLE`:

- wrong interpreter, Python version, platform, architecture, or environment;
- any argument, existing final/input/output path, a partial-directory
  `FileExistsError`, missing/nonregular/symlinked requirements input, or
  requirements-identity mismatch;
- less than 300 MiB free before provision;
- unavailable `venv`/pip, network error, timeout, hash mismatch, non-wheel,
  dependency resolution, package/version mismatch, or nonzero child status;
- measured pre-provenance elapsed time above 300 seconds or final partial-tree
  size above 300 MiB;
- provenance write failure or publication failure.

On failure the script removes only the partial path it atomically created and
owned. It never cleans a path when atomic `mkdir` reported `FileExistsError`.
Final path,
staged input, formal output, scientific source, and historical output remain
absent or unchanged. If partial cleanup itself fails, the remaining partial
path is `HOST_DEPENDENCY_PARTIAL_REMAINS`; no provision retry, preflight,
staging, or fallback is allowed until a separately authorized disposition.
There is no automatic retry and no alternate package index, version, wheel,
environment, interpreter, target, or installer.

Successful provision means only that the final directory and its immutable
provision record exist. It does not import NumPy/SciPy, run the API preflight,
open `fbie-a1`, create the staged input, run `checkcode`, or start MATLAB or
Octave.

## 5. Host-only provenance collection

The successful final environment contains the append-only machine record:

```text
/private/tmp/tep-i32-ecap-dep-a1/host-provenance/provision-a1.json
```

It records the base/final/partial paths, exact installed versions, machine-side
script and requirements identities, time/disk budgets, the non-measured static
network planning cap, elapsed time before provenance/publication, disk bytes,
isolated-install flags, compact pip-output identities, the first system-Python
failure, host retry count 1, formal retry count 0, and `ecap-a1` unconsumed. The
formal facts are labeled as frozen prior history plus runtime absence guards
for the staged target and formal output, rather than as facts inferred from
package metadata.
The provision record fixes
`dependency_preflight_run=false` and `staging_retry_run=false`.

Because the record lives under `/private/tmp`, it is an ephemeral host audit
record whose durability depends on that provisioned environment remaining in
place. It is not a formal experiment artifact, is not promoted into historical
output, and cannot support a scientific or long-term provenance claim by
itself. If the operating system removes it, the environment is unavailable and
must not be silently reconstructed or treated as previously provisioned.

If the later preflight is authorized, its exact stdout and status must be
published as a new no-overwrite sibling event
`host-provenance/preflight-a1.json`; the provision record is never edited. A
successful preflight still requires a separate staging authorization. The
formal MATLAB entry must not read the environment's provenance collection,
paths, versions, package metadata, Markdown, hashes, historical output, or any
other host record.

## 6. Post-provision gates

Only after successful provision and independent artifact review does the
Revision A in-memory MAT preflight become eligible. Its interpreter changes
prospectively from the unavailable bundle environment to the provisioned final
interpreter, and both preflight and staging must use this exact prefix:

```text
PYTHONNOUSERSITE=1 /private/tmp/tep-i32-ecap-dep-a1/bin/python3 -I
```

No command is authorized here. The preflight must still exercise
`loadmat(...,simplify_cells=True)` and
`savemat(...,long_field_names=True,oned_as='column')` wholly in memory, record
exact Python/NumPy/SciPy versions and all Boolean interface gates, and stop
without staging on any failure. Only a reviewed successful preflight may lead
to separate authorization of the unchanged stager with the same interpreter,
same isolated prefix, original source, and original target.

Provision, preflight, and staging are three different append-only events.
None is a numerical experiment or a formal `ecap-a1` launch. The formal tag is
consumed only by the separately authorized MATLAB command.

## 7. Acceptance checklist

- [ ] `design-3-2b.md`, all three MATLAB files, `stage_fbie_input.py`, schemas,
      levels, thresholds, and tag are byte-identical.
- [ ] `fbie-a1` source/report are byte-identical; staged input and output are
      absent.
- [ ] The machine requirements contain exactly two versions and four official
      arm64 wheel hashes.
- [ ] The provision script has one argument-free command, exact absent-path
      guards, atomic mode-`0700` partial ownership, a one-open pre-network
      requirements-identity gate, an `O_EXCL` private requirements snapshot,
      and exclusive atomic publication.
- [ ] System/bundle/`octave`/shared environments cannot be modified.
- [ ] User-site, ambient Python/pip configuration, dependencies, source builds,
      extra indexes, and fallback are disabled.
- [ ] Hard time/disk, static network planning, cleanup, and first-failure
      semantics are explicit and not conflated.
- [ ] Success creates only the isolated environment and provision provenance.
- [ ] Success authorizes at most independent review followed by a separately
      authorized preflight; it never auto-runs preflight or staging.
- [ ] Researcher--Engineer agree and Skeptic passes before provision.
