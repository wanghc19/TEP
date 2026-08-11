# I4 singularity-aware proxy-rule experiment

This directory contains a prospective, MATLAB-authoritative test of one
source-placement repair for the package MFS/proxy quasi-periodic Green
function. It does not modify package code and it does not run DLP, DtN, or a
root locator.

## Theory and sources

The claim-to-source boundary is frozen in
[`design.md`](design.md#primary-literature-boundary). The five primary sources
used by this experiment are:

- [Barnett and Betcke (2008)](../../ref/ref_data/Barnett2008.pdf),
  `BarnettBetcke2008`;
- [Barnett and Greengard (2010)](../../ref/ref_data/Barnett2010.pdf),
  `BarnettGreengard2010`;
- [Cho and Barnett (2015)](../../ref/ref_data/unsorted/1410.5003v1.pdf),
  `ChoBarnett2015`;
- [Adcock and Huybrechs (2020)](../../ref/ref_data/Adcock2020.pdf),
  `AdcockHuybrechs2020`;
- [Huybrechs and Olteanu (2019)](../../ref/ref_data/Huybrechs2019.pdf),
  `HuybrechsOlteanu2019`.

The sole candidate is `proxy_dist/d = 0.2`. The old value `0.7` placed the
vertical proxy edges at $|x|=1.2$, beyond the nearest periodic-image
singularities at $|x|=1$. The new value places them at $|x|=0.7$, leaving a
margin $0.3$ before those singularities. This is a preregistered repair, not a
parameter sweep.

## Frozen ladder

| Level | `Nside` | `Ntop` | `Nedge` | `Mpw` |
|---|---:|---:|---:|---:|
| base | 120 | 120 | 64 | 24 |
| Nedge | 120 | 120 | 80 | 24 |
| Nside | 160 | 120 | 64 | 24 |
| Ntop | 120 | 160 | 64 | 24 |
| Mpw | 120 | 120 | 64 | 32 |

`Mpw` is the internal Rayleigh basis used to match the top and bottom of the
proxy box. `M_trace=48` is the separate Fourier bandwidth used to inspect the
physical walls.

## Reproduction

From the repository root in MATLAB R2023b:

```matlab
addpath(fullfile(pwd,'test','i4-proxy-rule'));
run_i4_proxy_rule('pilot');
run_i4_proxy_rule('full');
```

Pilot mode builds no wall matrix. It records package point error, six training
and six shifted hold-out residual blocks, singular values and numerical rank,
coefficient norms, proxy-edge Fourier tails, and internal plane-wave tails.
It also writes `runtime-estimate.md` before any full wall run.

Full mode first repeats the pilot gate, then evaluates the base physical wall
actions and one-axis refinements in the frozen order. It stops immediately if
the base coefficient/tail gate or the first one-axis self-change gate fails.

## Outputs

Each mode writes its own MAT, CSV, Markdown, and log artifacts under `output/`.
The canonical report distinguishes diagnostics from enforced gates and keeps
both manufactured densities, both walls, and every retained Fourier mode.

The band $24<|m|\leq48$ is only a screen of the current output bandwidth. A
later wall-field reconstruction and omitted-tail study is still required to
certify `M_trace` for DtN use.
