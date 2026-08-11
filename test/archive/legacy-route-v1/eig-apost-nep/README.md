# Manufactured eig-apost experiment

This isolated experiment implements the fixed-dimensional analytic NEP defined in
`research/projects/eig-apost/implementation/design.md`. It validates only the numerical
root-search and conditional projected-estimator pipeline; it does not implement a physical
BIE or DtN map.

Run from `/Users/whc/Documents/Work/epost`:

```text
conda run -n octave octave --quiet --no-gui --eval "cd('/Users/whc/Documents/Work/epost'); addpath(pwd); addpath(fullfile(pwd,'test','eig-apost-nep')); results=run_manufactured_nep(); assert(results.all_pass);"
```

The entry point writes all generated files to `test/eig-apost-nep/output/`. A successful
run ends with `ALL TESTS PASS` and produces the parameter record, numeric tables, SVG image,
log, MAT file, and experiment report required by the experiment plan.

The governing skeptic review is
`research/projects/eig-apost/implementation/nep-review.md`. Retained `pilot-01`,
`formal-01`, `repro-run1`, and `output` configuration files may still record its former
name, `review.md`; those files are historical provenance and are not rewritten. After the
rename, a deliberate rerun must first create a source-changed baseline and then use an
unchanged-source second run to renew the reproducibility lock.
