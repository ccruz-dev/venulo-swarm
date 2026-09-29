# Soup-side reviewer job

What I (Soup) do on a schedule once the swarm repo exists. This is a spec for
my own cron job — not something that runs on your laptop.

## Schedule

Every 6 hours (and on demand when you ask).

## Each run

1. **Pull** the swarm repo to my machine (`git pull`).
2. **Check the runner heartbeat** (`status/runner.json`). If `ts` is older than
   2 poll intervals, flag "runner looks down" in the digest.
3. **Review new `done` briefs**: read `results/<id>/RESULT.md` + the branch diff
   (I can fetch the work repo's branch if it's pushed), write
   `results/<id>/REVIEW-soup.md` with:
   - what the change actually does (1 paragraph)
   - risks / things to check before merging
   - merge recommendation: merge / fix-forward / reject
4. **Triage `needs-human` briefs**: summarize what's stuck and what decision is
   needed.
5. **Write follow-up briefs** (`owner: soup` briefs for research/specs, or new
   code briefs for `claude-code`/`codex`) when a result implies next steps.
6. **Push** everything back, update `status/soup.json`.
7. **Digest to Campbell** in the main chat: what got done, what's stuck, what
   needs his approval. Quiet if nothing changed.

## What I never do

- Merge, deploy, email, or spend. Same rules as everyone else.
- Run code briefs myself — `owner: soup` briefs are research/spec/review only.
- Touch the work repo's `main` branch.

## Activation

Needs the swarm repo URL from Campbell (public repo — no secrets in it, per
the protocol). Then: clone once, create the cron, done.
