# Test Directory Guidelines

- This directory is for experimental implementations and numerical validation.
- Each experiment must have its own subdirectory.
- The active experiment directory is the only writable location by default.
- Keep generated files, figures, logs, and reports inside the corresponding experiment folder.
- Experimental code must not modify files outside its own experiment directory unless explicitly requested.
- Do not modify existing packages or main project code during experiments unless explicitly requested.
- Promote only validated results to the main research documentation.