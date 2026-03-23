# Dojo Getting Started

The Fawkes Dojo is a structured learning programme for platform engineering teams.
Inspired by martial arts belt systems, it provides a progressive curriculum that
takes developers from platform awareness to platform mastery.

## The Belt System

Each belt represents a level of demonstrated competency. Belts are earned, not given —
each requires completing the learning module and passing a practical assessment.

| Belt | Colour | Topic | Duration |
|------|--------|-------|----------|
| **White Belt** | ⬜ | What is an IDP? DORA metrics fundamentals | 1–2 weeks |
| **Yellow Belt** | 🟨 | CI fundamentals, Jenkins shared library | 2–3 weeks |
| **Green Belt** | 🟩 | GitOps with ArgoCD, Kubernetes | 3–4 weeks |
| **Brown Belt** | 🟫 | Observability, SRE practices | 4–6 weeks |
| **Black Belt** | ⬛ | Platform product thinking, advanced IDP | 6–8 weeks |

## How to Enrol

1. Talk to your team lead or platform team to get access to the dojo environment.
2. Start with the [White Belt module](modules/white-belt/module-01-what-is-idp.md).
3. Complete the exercises in order. Each module builds on the previous one.
4. Book an assessment session with a belt-holder when you feel ready.

## What to Expect

Each module contains:
- **Concepts** — Background reading and explanations
- **Exercises** — Hands-on tasks in the sandbox environment
- **Assessment** — A short practical that demonstrates your competency

Assessments are conducted by a team member who holds the same or higher belt. There
is no time limit on completing a module — go at your own pace.

## Time Commitment

Most learners spend 2–4 hours per week on dojo activities alongside their regular work.
Some teams run dedicated "dojo days" where the whole team works through a module together.

## Belt-Holders as Mentors

Belt-holders are expected to help others working toward the same belt. If you are
stuck on an exercise, reach out in the Discourse dojo category or the `#dojo`
Mattermost channel.

## Sandbox Environment

Each learner gets access to a shared sandbox Kubernetes cluster with all Fawkes
components installed. The sandbox is reset weekly, so commit your work to Git.

```bash
# Connect to the dojo sandbox
kubectl config use-context fawkes-dojo
kubectl get pods -n my-namespace
```

## See Also

- [White Belt Module 01 — What Is an IDP?](modules/white-belt/module-01-what-is-idp.md)
- [Learning Culture Pattern](../patterns/learning-culture.md)
- [Tutorials](../tutorials/index.md)
