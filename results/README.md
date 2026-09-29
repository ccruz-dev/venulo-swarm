# results/

One directory per completed brief: `results/<brief-id>/`.

- `RESULT.md` — written by the runner: branch name, exit status, pointer to the log.
- `agent-output.txt` — full headless agent log.
- `REVIEW-soup.md` — written by Soup's reviewer job: what the diff actually does,
  risks, and a merge recommendation. Advisory only — Campbell decides.

Nothing here is merged to `main` automatically. Ever.
