# DORA Change Failure Rate — Deployment/Incident Webhook Schema

> Design doc for #1944. Scoped as design-only, not an implementation — see
> [What this doc does NOT do](#what-this-doc-does-not-do).

## Status and dependency on #1919

**#1919 (wire DevLake's webhook plugin for deployment signal) is still OPEN as of
this writing.** The golden-path pipeline currently only calls GitHub's own
Deployments API (PR #1917), which `docs/KNOWN_LIMITATIONS.md` KL-12 documents as
structurally insufficient for DevLake's `dora` plugin — it needs `cicd_tasks` rows
with `type='Deployment'`, which only DevLake's own `webhook` plugin can populate
directly for a non-GitHub-Actions pipeline like Tekton's golden path.

The schemas below come from DevLake's actual, currently-documented `webhook` plugin
API (`https://devlake.apache.org/docs/Plugins/webhook`), not from #1919's
implementation — that API is a fixed external contract, independent of how #1919
gets built. Once #1919 lands and creates the real webhook connection, this schema
should still apply unmodified, **provided** the deployment and incident events are
both submitted to a webhook connection scoped into the same DevLake project as
tracer-bullet (see [Correlation mechanism](#correlation-mechanism) below — this is
the one thing #1919's implementation must get right for CFR to work at all).

## Deployment payload

`POST <devlake-host>/api/rest/plugins/webhook/:connectionId/deployments`

```json
{
  "id": "tracer-bullet-<short-sha>",
  "startedDate": "2026-09-12T14:00:00Z",
  "finishedDate": "2026-09-12T14:01:30Z",
  "environment": "PRODUCTION",
  "result": "SUCCESS",
  "deploymentCommits": [
    {
      "repoUrl": "https://github.com/paruff/tracer-bullet",
      "refName": "main",
      "startedDate": "2026-09-12T14:00:00Z",
      "finishedDate": "2026-09-12T14:01:30Z",
      "commitSha": "<short-sha>",
      "commitMsg": "<commit subject line>"
    }
  ]
}
```

| Field | Required | Notes for this project |
|---|---|---|
| `id` | yes | Must be unique per `cicd_deployments` row — `tracer-bullet-<short-sha>` matches the tag scheme `gitops-promote` already uses |
| `startedDate` / `finishedDate` | yes | Bracket the `gitops-promote` task's own runtime, not the whole pipeline |
| `environment` | no (default `PRODUCTION`) | Should be set explicitly once alpha/beta/prod ApplicationSets (#1804) are all live, so CFR can eventually be sliced by environment |
| `result` | no (default `SUCCESS`) | `gitops-promote` should send `FAILURE` if the promotion PR merge fails, not just skip the call |
| `deploymentCommits[].commitSha` | yes | The same short-SHA `fetch-source` already exposes as a Tekton result |

## Incident payload

`POST <devlake-host>/api/rest/plugins/webhook/:connectionId/issues`

```json
{
  "issueKey": "tracer-bullet-incident-<n>",
  "title": "<short description of the production incident>",
  "type": "INCIDENT",
  "status": "TODO",
  "originalStatus": "open",
  "createdDate": "2026-09-12T15:30:00Z",
  "severity": "high",
  "url": "https://github.com/paruff/fawkes/issues/<tracking-issue-number>"
}
```

| Field | Required | Notes for this project |
|---|---|---|
| `issueKey` | yes | Unique within the connection — no existing incident-tracking convention exists yet in this repo, so this schema doesn't invent one beyond "must be unique" |
| `type` | no, but must be `INCIDENT` | The `dora` plugin's Change Failure Rate calculation specifically filters on this value |
| `status` / `originalStatus` | yes | `status` is DevLake's own enum (`TODO`/`IN_PROGRESS`/`DONE`); `originalStatus` is a free-text passthrough of whatever the source system calls it |
| `createdDate` | yes | This is the timestamp DevLake uses for time-window correlation against deployments — see below |

## Correlation mechanism

**There is no explicit "this incident was caused by that deployment" field in
either payload.** Per DevLake's own webhook plugin documentation: *"incidents on a
project will be related to the last deployment on the project with a timestamp
that is before the incident's timestamp."* Correlation is implicit:

1. Both the deployment and the incident must be added to the **same DevLake
   project** (a DevLake-side scoping concept, not a field in either JSON payload
   above).
2. DevLake's `dora` plugin then matches each `INCIDENT`-type issue to the most
   recent deployment in that project whose timestamp precedes the incident's
   `createdDate`.
3. Change Failure Rate = (deployments matched to at least one incident) /
   (total deployments), over the reporting window.

This means #1944's schema work is really only half the story: **whoever
implements #1919/#1945 must also ensure the deployment webhook connection and
whatever eventually submits incident events (#1945's Alertmanager receiver, most
likely) are both scoped into the same DevLake project as tracer-bullet** — a
connection/scoping detail, not a payload field, and easy to get silently wrong
(events would still accept and store, but never correlate).

## What this doc does NOT do

- Does not build the webhook receiver — that's #1945.
- Does not modify `golden-path-pipeline.yaml`'s `gitops-promote` task to call the
  deployments endpoint above — that's #1919, still open.
- Does not invent an incident-tracking convention for this repo — `issueKey` and
  `severity` are left generic pending whatever #1945's Alertmanager integration
  actually needs to send.

## Related

- #1919 — DevLake webhook plugin wiring for deployment signal (open, blocking)
- #1945 — Alertmanager webhook receiver posting incident events to DevLake (next issue)
- #1946 — Change Failure Rate panel on the DORA Grafana dashboard
- #1947 — BDD scenario for Change Failure Rate computation
- `docs/KNOWN_LIMITATIONS.md` KL-12 — why GitHub Deployments API alone is insufficient
