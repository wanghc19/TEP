# I4 Fliss 2013 dual-track experiment

- Profile: `baseline`
- Runtime cap: 10800 seconds
- Elapsed time: 401.533619 seconds
- Integrity pass: `1`
- Scientific positive-control pass: `0`
- BIE scientific decision: `BIE_MODE_COMPLETENESS_BLOCKED`
- Exact command: `perl -e 'alarm shift; exec @ARGV' 10800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_i4_fliss_experiment('baseline');"`

## Interpretation boundary

Track A (`fliss-smooth-fd-v1`) discretizes the exact smooth Fliss profile. Track B (`sharp-disk-bie-diagnostic-v1`) uses a radius-0.2 sharp homogeneous disk. The outputs are side-by-side diagnostics and must not be pooled as one model. A Track B singular-value dip is not reported as a root or eigenvalue.

## Track A: exact smooth finite-difference control

- strong-control: beta=0.5, reference omega^2=3.4649999999999999, role=`primary-paper-gate`, tail-12 omega^2=3.4609750440405129, normalized residual=1.007e-12, center fraction=4.959e-01, end fraction=6.968e-10, 8/12 relative shift=2.319e-07, mass-vector overlap=1.000000, edge gate available=1, expanded-band membership=0, gap gate pass=0, pass=0.
- weak-control: beta=1.4199999999999999, reference omega^2=10.460000000000001, role=`diagnostic-only`, tail-12 omega^2=10.420704767144551, normalized residual=9.847e-13, center fraction=3.076e-02, end fraction=5.014e-02, 8/12 relative shift=4.573e-04, mass-vector overlap=0.999164, edge gate available=1, expanded-band membership=0, gap gate pass=0, pass=0.

Band-edge uncertainty method: N80 local versus N40 local, N80 standard, and N80 shifted. It is explicit but is not a rigorous error bound.

Track A contrast continuation status: `not-run`. Track A implements the exact s=1 Fliss profile only; no smooth-profile contrast continuation was run.

## Track B: sharp-disk BIE diagnostic

- strong-control, s=1, n=4.1231056256176606: projected-gap candidates=49, usable gap samples=0, bad-count samples=49, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=1.677e-04, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- strong-control, s=0.75, n=3.6055512754639891: projected-gap candidates=49, usable gap samples=0, bad-count samples=49, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=1.403e-04, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- strong-control, s=0.5, n=3: projected-gap candidates=34, usable gap samples=0, bad-count samples=34, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=1.183e-04, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- strong-control, s=0.25, n=2.2360679774997898: projected-gap candidates=0, usable gap samples=0, bad-count samples=0, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=3.696e-03, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- weak-control, s=1, n=4.1231056256176606: projected-gap candidates=42, usable gap samples=0, bad-count samples=42, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=1.082e-03, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- weak-control, s=0.75, n=3.6055512754639891: projected-gap candidates=33, usable gap samples=0, bad-count samples=33, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=7.914e-04, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- weak-control, s=0.5, n=3: projected-gap candidates=28, usable gap samples=0, bad-count samples=28, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=4.751e-04, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- weak-control, s=0.25, n=2.2360679774997898: projected-gap candidates=27, usable gap samples=0, bad-count samples=27, missing modes=490, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=2.459e-04, completeness=`BIE_MODE_COMPLETENESS_BLOCKED`, classification=`real-axis-singular-value-diagnostic`, root claim=0.

Continuation order starts at s=1 as required.

## Negative controls

- Track A `no-defect-center-localization`: value=0.11544766918185641, threshold=0.25, pass=1. Perfect strip must not create a strongly center-localized control mode.
- Track A `manufactured-end-localization`: value=1, threshold=0.90000000000000002, pass=1. An end-supported vector must be classified as end-localized, not centered.
- Track B `homogeneous-medium-no-projected-gap`: value=0, threshold=0, pass=1. The exact s=0 homogeneous limit must retain propagating bulk modes at every control sample.
- Track B `singular-value-dip-is-not-a-root`: value=0, threshold=0, pass=1. Every BIE candidate remains a real-axis singular-value diagnostic only.
