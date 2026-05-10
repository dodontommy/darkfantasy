# Shell ticket preamble (informational only — not sent to a CLI)

Shell tickets are executed by `run-worker.sh` extracting the `## Run` fenced
code block from the ticket and running it under `bash -euo pipefail` from the
ticket's working directory.

There is no LLM in the loop for shell tickets. Use them for:
- Headless `blender --background --python ...` runs
- File checks, manifest verifications
- Render batch invocations
- `git` housekeeping the orchestrator can audit by reviewing the ticket

This file exists so `run-worker.sh` can find a preamble for every worker class
even though shell tickets ignore it.
