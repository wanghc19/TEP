# Canonical MFS solver-backend metadata

- Runtime: `GNU Octave 10.3.0`
- Package entry point: `/Users/whc/Documents/Work/epost/+kernel/precomp_proxy.m`
- `exist('lsqminnorm','file')`: `0`
- Active package branch: `pinv(A) * b`
- `pinv` implementation: `libinterp/corefcn/pinv.cc`
- MATLAB executed: `no`

The canonical three-path run therefore diagnoses the package MFS path under
Octave's default pseudoinverse backend.  It does not identify the internal
cause as a cutoff-only error: the effective rank, cutoff, coefficient norm,
and residual were not exposed by `kernel.precomp_proxy` in this run.  MATLAB
may select the `lsqminnorm` branch and must not be inferred from this Octave
result.

The read-only metadata query was:

```sh
conda run -n octave octave --quiet --no-gui --eval "fprintf('version=%s\\n',version); fprintf('lsqminnorm_exist=%d\\n',exist('lsqminnorm','file')); fprintf('pinv_path=%s\\n',which('pinv')); fprintf('precomp_path=%s\\n',which('kernel.precomp_proxy'));"
```
