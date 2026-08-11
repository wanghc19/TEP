# Failed baseline attempt 1

- Date: 2026-08-07
- Runtime: Octave from Conda environment `octave`
- Command: `conda run -n octave octave --quiet --no-gui --eval "addpath('test/root-ready/provenance-closure'); run_provenance_closure('baseline');"`
- Exit code: `1`
- Numerical stage reached: no
- Preserved log: `baseline/run.log`

The run stopped in the pre-numerical raw-source audit because Octave rejected a
`uint8` pattern passed to `strfind`:

```text
error: strfind: PATTERN must be a string or cell array of strings
error: called from
    provenance_closure_diagnostic>LOCAL_extract_body
```

The corrective patch uses a one-to-one `char` view only to locate ASCII marker
indices. Extraction, mutation, byte comparison, and hashing still consume the
original `uint8` buffers without line-ending normalization. Engineer static
checks and a Skeptic delta review both passed before the authorized retry.
