## File naming conventions

Top-level MATLAB scripts should use short semantic prefixes so that both users and coding agents can quickly identify the purpose of a file.

### General naming guidance

Top-level MATLAB scripts should use short, semantic names. The common reference pattern is:

```text
<prefix>_<task>[_model][_qualifier].m
````

but this is a guideline, not a rigid template.

A good filename should make its purpose clear using the approved prefix and abbreviation list. Do not add unnecessary words merely to fit the template.

Examples:

```text
bloch_test_F.m
bloch_test_S.m
bloch_test_modes.m
scat_edc_ps.m
scat_edc_ps_scan.m
tep_scan_local.m
```

For example, `scat_edc_ps.m` is acceptable because it clearly means a scattering / forced-response script for an empty defect cell with point-source forcing. It does not need to be renamed to `scat_solve_edc_ps.m` unless the extra word `solve` adds useful distinction.

When naming a new file:

1. Start with a meaningful prefix such as `tep_`, `bloch_`, `scat_`, `bie_`, `scan_`, or fallback `test_`.
2. Use existing abbreviations when possible, such as `edc` for empty defect cell and `ps` for point-source forcing.
3. Prefer clarity over strict template matching.
4. If a new abbreviation is introduced, add it to the abbreviation list.



### Prefixes

| Prefix   | Meaning                                                                                      |
| -------- | -------------------------------------------------------------------------------------------- |
| `tep_`   | eigenvalue / resonance problems in the transmission/Bloch matching framework; includes the original transmission eigenvalue problem and related empty-defect-cell cavity eigenvalue problems                                                      |
| `bie_`   | boundary integral equation / operator assembly scripts                                       |
| `bloch_` | Bloch mode package tests or Bloch-mode workflows                                             |
| `scat_`  | scattering / forced response scripts (not `scatt`)                                                        |
| `scan_`  | generic scan infrastructure scripts, only if top-level; package code should live in `+scan/` |

The `tep_` prefix may be used in a broad sense for eigenvalue or resonance searches built from the same transmission / Bloch trace-matching machinery, even when the center defect cell is empty and the problem is not the original material-interface TEP.

### Fallback test prefix

Use `test_` for standalone validation scripts that do not clearly belong to a specific topic prefix such as `tep_`, `bloch_`, `scat_`, or `bie_`.

General form:

```text
test_<object>[_qualifier].m
````

Examples:

```text
test_gamma_branch.m
test_qpgreen_axis_swap.m
test_complex_k_smoke.m
test_matrix_dims.m
```

If a test clearly belongs to a topic-specific workflow, prefer the topic prefix:

```text
bloch_test_modes.m
scat_edc_ps.m
tep_1d_scan_local.m
```

Use `test_` only when no more specific prefix is natural.

For disposable scratch scripts that should not be treated as maintained tests, use:

```text
tmp_<description>.m
```

and avoid committing them unless intentionally preserving them.


### Model abbreviations

| Abbreviation | Meaning                                  |
| ------------ | ---------------------------------------- |
| `1d`         | one-dimensional periodic waveguide model |
| `lead`       | periodic lead cell problem               |
| `edc`        | empty defect cell                        |
| `mc`         | missing column                           |
| `pc`         | perfect periodic crystal                 |
| `cent`       | center cell                              |
| `cav`        | cavity / defect cavity                   |

Prefer `edc` when the center defect cell is empty background medium. Prefer `mc` when emphasizing the physical missing-column crystal interpretation.

### Task abbreviations

| Abbreviation | Meaning                                |
| ------------ | -------------------------------------- |
| `scan`       | parameter scan                         |
| `local`      | local refinement around a selected dip |
| `global`     | global scan over a larger interval     |
| `test`       | validation / consistency test          |
| `ps`         | point-source forcing                   |
| `rhs`        | right-hand-side construction           |
| `tr`         | trace computation                      |
| `trmatch`    | trace matching matrix                  |
| `svd`        | singular-value diagnostic              |
| `conv`       | convergence test                       |
| `demo`       | lightweight demonstration script       |

### Examples

| Filename              | Meaning                                                               |
| --------------------- | --------------------------------------------------------------------- |
| `tep_1d_scan_local.m` | local scan for the 1D periodic-waveguide TEP                          |
| `bloch_test_F.m`      | test for Bloch far-field extraction matrices                          |
| `bloch_test_S.m`      | test for the Bloch cell scattering matrix                             |
| `scat_edc_ps.m`       | scattering problem for an empty defect cell with point-source forcing |
| `scat_edc_ps_scan.m`  | scan for the empty-defect-cell point-source scattering problem        |
| `scat_edc_trmatch.m`  | trace-matching system for the empty defect cell scattering model      |
