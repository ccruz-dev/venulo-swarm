# status/

Heartbeats, one JSON file per agent. Lets everyone see who's alive without
asking.

- `runner.json` — written by `scripts/runner.sh` every poll. If `ts` is stale,
  the laptop runner is down.
- `soup.json` — written by Soup's scheduled reviewer job each run.

Format:

```json
{
  "agent": "runner",
  "ts": "2026-09-29T22:00:00Z",
  "state": "polling | working",
  "detail": "<brief-id> or idle note"
}
```
