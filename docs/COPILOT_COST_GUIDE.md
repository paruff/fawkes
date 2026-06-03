# Copilot Cost Guide for Fawkes

## Why this guide exists
Fawkes now pays for Copilot agent work through GitHub AI Credits, where 1 credit equals $0.01.
Chat, CLI, agent mode, cloud agent, Spaces, Spark, and third-party agents consume credits.
Code completions and next edit suggestions stay free for paid plans.

The hidden multiplier is always-on context: `AGENTS.md`, `.github/copilot-instructions.md`, and `CLAUDE.md` are sent on every request.
Large instruction files silently tax every prompt, every day, even when the task only needs one small edit.

## Plan credit budgets
| Plan | Monthly price | Base credits | Flex / promo | Total included AI credits |
|---|---:|---:|---:|---:|
| Copilot Pro | $10 | 1,000 | 500 flex | 1,500 |
| Copilot Pro+ | $39 | 3,900 | 3,100 flex | 7,000 |
| Copilot Business | $19/user | 1,900 pooled | 3,000/user through 2026-09-01 for existing customers | 1,900 standard |
| Copilot Enterprise | $39/user | 3,900 pooled | 7,000/user through 2026-09-01 for existing customers | 3,900 standard |

Source: GitHub Copilot usage-based billing and model pricing docs (June 2026).

## What is free vs what costs
### Free in paid plans
- Inline completions
- Next Edit Suggestions

### Billed in AI credits
- Copilot Chat
- Copilot CLI
- Copilot Edit / Agent Mode / cloud agent
- Copilot Spaces and Spark
- Third-party coding agents
- Copilot PR review (also consumes GitHub Actions minutes)

## The three biggest cost levers
1. **Instruction file size**
   - Highest leverage because it affects every single request.
   - Keep always-on context below 80 lines or about 320 tokens.
2. **Mode selection**
   - Ask is cheapest, Edit is next, Agent Mode is most expensive because it fans out into many model calls.
3. **Model selection**
   - Lightweight and included models stretch the budget.
   - Frontier models should only be used when cheaper models are likely to fail.

## Anti-patterns and cheaper replacements
| Anti-pattern | Cost effect | Better pattern |
|---|---|---|
| 800-line `AGENTS.md` plus long Copilot instructions | Pays a context tax on every prompt | Keep AGENTS lean and move detail to `.github/skills/` |
| Starting Agent Mode for a one-file docs tweak | Multiple model calls for a simple edit | Use Ask or Edit with exact file scope |
| Using frontier models for markdown, YAML, or rename-only tasks | Higher token price with little accuracy gain | Use GPT-5 mini or GPT-4.1 |
| Asking the agent to explore the whole repo before every change | Large repeated input context | Name 3-5 files up front and stop once scope is clear |

### Before/after examples
- **Before:** 9,750 always-on tokens/request x 440 moderate tasks/month x $0.003 per 1K input tokens ~= **$12.87/month** before any task-specific context or output.
- **After:** 600 always-on tokens/request x 440 moderate tasks/month x $0.003 per 1K input tokens ~= **$0.79/month** before task-specific context or output.
- **Savings:** about **94%** on the always-on input tax alone.

## Worked Fawkes monthly scenarios
These examples use the repo audit's always-on context estimate and Sonnet-class input pricing only.

| Usage pattern | Example behavior | Before | After |
|---|---|---:|---:|
| Light | 10 agent tasks/day x 22 days | $6.44 | $0.40 |
| Moderate | 20 agent tasks/day x 22 days | $12.87 | $0.79 |
| Heavy | 50 agent tasks/day x 22 days | $32.19 | $1.98 |

Task output tokens, retries, and large frontier-model runs increase these totals further, which is why context trimming matters first.

## How to read the GitHub billing dashboard
1. Open **Settings -> Billing & licensing -> Metered products -> GitHub Copilot**.
2. Check total AI credits consumed for the billing cycle.
3. Compare pooled included credits versus additional paid usage.
4. Inspect high-cost users, repositories, and cost centers.
5. Cross-check expensive spikes against model choice, agent mode usage, and PR review automation.

## Team admin controls
- Set user-level budgets to stop runaway spend for individual heavy users.
- Set org or enterprise spending limits to cap overage once the pooled allowance is exhausted.
- Use cost centers when multiple teams share the same enterprise pool.
- Review automatic PR review policies because they spend both AI credits and GitHub Actions minutes.
- Keep `.copilotignore` current so agents do not read low-signal files by default.

## Fawkes operating rules
- Treat `AGENTS.md` as a router, not a handbook.
- Put architecture, PR contract, metrics, and model-routing detail in on-demand skills.
- Require a scope check before Agent Mode work.
- Use `bash scripts/token-audit.sh` in monthly metrics review to catch instruction creep early.
