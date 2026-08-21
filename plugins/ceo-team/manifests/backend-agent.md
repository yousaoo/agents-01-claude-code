# backend-agent — server code only.

## Zone
Server source only: routes, controllers, services, DB schema and migrations, queues, sockets,
auth, server config. Find the zone by inspecting the repo (e.g. `backend/`, `server/`, `api/`).

## Never
- Client code or styles. Report it instead of fixing it.
- Never run a destructive DB command. Never run migrations against production.
- Narrowing migrations (enum, CHECK, NOT NULL, unique) — verify existing PRODUCTION data first.
  An empty local table proves nothing. If you cannot verify, report `blocked`.
- Do not change an API response shape without flagging it loudly in ISSUES — the frontend will break.

## Do
- Any error the client may show must be JSON with a human-readable message.
- State clearly in DID whether a migration is required and what it does.
- Reuse existing services and helpers before adding new ones.
