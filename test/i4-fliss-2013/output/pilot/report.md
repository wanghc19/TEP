# I4 Fliss 2013 dual-track experiment

- Profile: `pilot`
- Runtime cap: 10800 seconds
- Elapsed time: 12.839830 seconds
- Integrity pass: `1`
- Scientific positive-control pass: `0`
- Exact command: `perl -e 'alarm shift; exec @ARGV' 10800 conda run -n octave octave --quiet --no-gui --eval "addpath('/Users/whc/Documents/Work/epost/test/i4-fliss-2013'); results=run_i4_fliss_experiment('pilot');"`

## Interpretation boundary

Track A (`fliss-smooth-fd-v1`) discretizes the exact smooth Fliss profile. Track B (`sharp-disk-bie-diagnostic-v1`) uses a radius-0.2 sharp homogeneous disk. The outputs are side-by-side diagnostics and must not be pooled as one model. A Track B singular-value dip is not reported as a root or eigenvalue.

## Track A: exact smooth finite-difference control

- strong-control: beta=0.5, reference omega^2=3.4649999999999999, role=`primary-paper-gate`, tail-12 omega^2=3.4550275524183549, normalized residual=2.902e-14, center fraction=4.879e-01, end fraction=6.554e-10, 8/12 shift=7.721e-07, mass-vector overlap=1.000000, edge gate available=0, expanded-band membership=0, pass=0.
- weak-control: beta=1.4199999999999999, reference omega^2=10.460000000000001, role=`diagnostic-only`, tail-12 omega^2=10.333689670653927, normalized residual=3.036e-14, center fraction=3.284e-02, end fraction=4.625e-02, 8/12 shift=5.085e-03, mass-vector overlap=0.998947, edge gate available=0, expanded-band membership=0, pass=0.

Band-edge uncertainty method: pilot nested-theta diagnostic only; spatial/local gate unavailable. It is explicit but is not a rigorous error bound.

Track A contrast continuation status: `not-run`. Track A implements the exact s=1 Fliss profile only; no smooth-profile contrast continuation was run.

## Track B: sharp-disk BIE diagnostic

- strong-control, s=1, n=4.1231056256176606: gap samples=0, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=3.281e-05, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- strong-control, s=0.5, n=3: gap samples=0, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=2.204e-05, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- weak-control, s=1, n=4.1231056256176606: gap samples=0, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=2.291e-05, classification=`real-axis-singular-value-diagnostic`, root claim=0.
- weak-control, s=0.5, n=3: gap samples=0, best real-axis dip k=NaN, normalized sigma=NaN, maximum Bloch residual=4.730e-06, classification=`real-axis-singular-value-diagnostic`, root claim=0.

Continuation order starts at s=1 as required.

## Negative controls

- Track A `no-defect-center-localization`: value=0.11530066164030585, threshold=0.25, pass=1. Perfect strip must not create a strongly center-localized control mode.
- Track A `manufactured-end-localization`: value=1, threshold=0.90000000000000002, pass=1. An end-supported vector must be classified as end-localized, not centered.
- Track B `homogeneous-medium-no-projected-gap`: value=0, threshold=0, pass=1. The exact s=0 homogeneous limit must retain propagating bulk modes at every control sample.
- Track B `singular-value-dip-is-not-a-root`: value=0, threshold=0, pass=1. Every BIE candidate remains a real-axis singular-value diagnostic only.
