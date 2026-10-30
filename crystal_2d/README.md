# Historical 2D waveguide and crystal workflows

This directory preserves earlier 2D periodic-crystal, empty-defect-cell, and
line-defect implementations and validation programs. It is a historical archive,
not a current development plan or a set of recommended run targets.

Do not read or cite these files by default, or use them as current theoretical
authority, implementation examples, or result baselines. Consult them only when
the user explicitly requests historical investigation, reproduction, or migration.
For current work, use the project and experiment links in the [root README](../README.md).

## Contents

| File | Historical role |
| --- | --- |
| [tep_edc_scan_local.m](tep_edc_scan_local.m) | Local eigenvalue search for an empty-defect-cell matching system |
| [tep_edc_projected_gap_scan.m](tep_edc_projected_gap_scan.m) | Sampled projected-gap diagnostic for the periodic leads |
| [scat_edc_ps.m](scat_edc_ps.m) | Empty-defect-cell response to a point source |
| [scat_edc_lead_in.m](scat_edc_lead_in.m) | Empty-defect-cell response to an incoming Bloch mode |
| [scat_ld_lead_in.m](scat_ld_lead_in.m) | Line-defect scattering with a center inclusion |
| [bloch_pc_barnett_scan.m](bloch_pc_barnett_scan.m) | Comparison of 2D quasi-periodic BIE phase scans and Bloch multipliers |
| [bie_pc_ps_extdir.m](bie_pc_ps_extdir.m) | Manufactured-solution check for a perfect-crystal exterior Dirichlet problem |

The first five files were moved here from the repository root without changing
their contents. The former root entry `tep_1d_scan_local.m` belongs to the
[historical 1D waveguide directory](../waveguide_1d/tep_1d_scan_local.m).

These programs still depend on shared MATLAB packages at the repository root.
Those packages, including `+kernel/` and `+bloch/`, remain dependencies of current
work and are not archived by this reorganization. Historical reproduction requires
both the relevant entry-point directory and the repository root on the MATLAB path;
the move itself does not establish compatibility with the current package versions.
