# Preregistered sequential design

## Frozen objects

- Geometry: period $d=1$, circle radius $R=0.2$, walls $x=\pm0.5$.
- Parameters: $k=1.8603695988$, $\beta=0.5$, $H=1.1$.
- Package path: public MATLAB `lsqminnorm`, `proxy_dist/d=0.2` only.
- Proxy levels: base `(120,120,64,24)`, then `Nedge`, `Nside`, `Ntop`,
  and `Mpw` one at a time.
- Wall grid: `ntot=256`, `Ny=512`; reference bandwidth `Mref=96`.
- Trace levels: `12,24,48,64,96`; candidate `48`, reference `96`.

The Ewald, package, and Rayleigh paths share only geometry, density, and the
final Fourier basis. Ewald is recomputed analytically, package matrices use the
public MFS evaluator, and Rayleigh coefficients use `farfield_extractors`.

## Stopping and gates

DLP-D point qualification precedes every wall matrix. DLP-D wall triangles and
each package one-axis change must pass before DLP-N is interpreted. DLP-N then
repeats its point/self and wall gates. The raw coefficient gate is `1e-8`; all
point, self-change, reconstruction, and tail gates are `2e-9`.

The public solver is not replaced. Pilot records the exact rank policy

$$
\operatorname{rank}_{\mathrm{num}}(A)=\#\{\sigma_j>
\max(m,n)\operatorname{eps}(\sigma_1)\},
$$

with expected ranks `(302,328,302,302,330)`, residuals, coefficient norms,
and the duplicated endpoint coefficient check.

## Trace observables

For every action/path/density/wall, the reference is the coefficient vector
through $|m|\leq96$. The ledger records:

- pairwise E/P/R errors through the reference band;
- omitted maximum and omitted energy for every candidate bandwidth;
- reconstruction change from 48 to 64 and from 64 to 96;
- terminal-band maxima on $64<|m|\leq96$;
- direct half-grid reconstruction residuals for E and P.

The four-action `M_trace=48` decision uses all these quantities. `Mpw` remains
the internal top/bottom proxy matching order and is not `M_trace`.
