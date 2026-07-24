# Trace and gluing

## Weak interface calculation

Let a center field `u_0` and two half-guide fields `u_\pm` have equal Dirichlet traces on `\Gamma^\pm`. Their piecewise union belongs to global `H^1` by the Sobolev gluing theorem. Testing the PDE in the three subdomains gives artificial-boundary terms

\[
\langle\gamma_{N,0}u_0,\gamma_Dv\rangle_{\Gamma^\pm}
+\langle\gamma_{N,\pm}u_\pm,\gamma_Dv\rangle_{\Gamma^\pm}.
\]

Because the outward normals of adjacent pieces are opposite, the global distributional equation has no port-supported source precisely when these conormal traces sum to zero. This orientation must be built into `\Pi^\pm` and `Q^\pm`.

## Restriction--gluing proof skeleton

1. Restrict a global `H^1_\beta` field; L1 supplies its port Cauchy pairs.
2. The lead restrictions are outgoing by the strict-gap characterization, so the pairs lie in `\mathcal C^\pm_{\rm out}`.
3. Conversely, choose half-guide preimages of the two relation pairs.
4. Glue by matching Dirichlet data and cancel conormal terms as above.
5. Apply half-guide uniqueness to show independence of preimage, or quotient the zero-trace solution subspace.
6. Restriction and gluing are inverse linear maps; geometric dimensions therefore agree.

## Decay semantics

Global `H^1` is the definition. In a strict projected gap, stable multipliers yield cellwise exponential estimates. Pointwise exponential decay needs interior/interface regularity followed by local embedding; it should not be silently identified with `L^2` decay.

## Failure checklist

- Matching only Dirichlet values permits a delta source.
- A port through a material junction complicates conormal traces.
- A DtN pole can make Dirichlet data nonunique, while the full Cauchy relation can remain well defined.
- At a band edge the stable exponential estimate is nonuniform or false.

