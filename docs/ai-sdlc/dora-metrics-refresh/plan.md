# Plan: dora-metrics refreshes off the request path

**Traces to:** paruff/fawkes#2319 (the issue is the intent; the regression
tests are the spec). Found while reviewing failure modes for paruff/fawkes#2314.

## Changes

1. `services/dora-metrics/app/main.py`: a background task refreshes from
   GitHub every `CACHE_TTL_SECONDS`, in a thread. `GET /metrics` only prints
   the last good snapshot. No value is printed before the first success, and
   lead time is left out when no release PR is in the window. Two new series,
   `fawkes_repo_dora_refresh_failures_total` and
   `fawkes_repo_dora_last_success_timestamp_seconds`, show a failing or stale
   refresh.
2. `services/dora-metrics/app/collectors/github.py`: `gh` runs with a
   30-second timeout, and a merged-PR list that reaches its limit of 500
   raises, since `gh` truncates without saying so.

## Verification Strategy

| Criterion | Evidence | How |
| --- | --- | --- |
| A scrape never calls GitHub | The collector raises if reached | `test_scrape_never_calls_github` |
| No value before the first success | No `fawkes_repo_deployment_frequency_per_day` sample | `test_no_values_before_the_first_successful_refresh` |
| A failed first refresh isn't reported as zero | No value sample; the failure counter is 1 | `test_first_refresh_failing_reports_a_failure_not_zeros` |
| A later failure keeps the last good values and their age | Same values and same success timestamp after a timeout | `test_later_failure_keeps_the_last_good_values_and_their_age` |
| No release PR gives no lead time | Frequency 0, lead time absent | `test_no_release_prs_reports_zero_frequency_and_no_lead_time` |
| `gh` can't hang the refresh | `subprocess.run` is called with a timeout | `test_gh_is_called_with_a_timeout` |
| A truncated list fails | `RuntimeError` at 500 entries | `test_a_truncated_pr_list_fails_instead_of_undercounting` |
| `/health` answers during a refresh | Old and new code run against a `gh` that sleeps 6 s: 4.0 s and no answer before, 0.002 s after | By hand, output in paruff/fawkes#2320 |
| Not covered | The image build, and behaviour under the real probes on a cluster | After deploy: the success timestamp advances every 10 minutes |

All but the last two rows run with `cd services/dora-metrics && pytest tests/`.
