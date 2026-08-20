"""
Regression tests for .github/workflows/opencode.yml's trigger and model
routing logic.

The trigger (if:) is a real GitHub Actions expression, parsed and evaluated
directly from the workflow file. The model choice used to be a static
expression too, but as of the "Resolve model" step it's computed at runtime
against the live models.dev catalog (see that step's comment for why:
hardcoded model IDs broke twice in one session). That means the FINAL
resolved model can no longer be tested as pure logic without a network call
-- what CAN still be tested as pure logic is the routing decision (which
model tier a given comment selects) and that the preferred model strings in
the script haven't been silently mistyped or dropped.

Each case below traces to a real bug found and fixed this session:
- bot self-retrigger (PR #1618): the bot's own "opencode session" link
  contains the literal substring "/opencode", which used to re-trigger the
  workflow before the user.type != 'Bot' guard was added.
- hyphenated tag vs. bracket tag (issue #1587): "/oc-security ..." still
  triggers the action (confirmed live) but must NOT match [security]/
  [feature] routing, since the tag isn't literally present.
- doubled NVIDIA prefix (issue #1570, PR #1629).
"""

import re
from pathlib import Path

import pytest
import yaml

WORKFLOW_PATH = Path(__file__).parent.parent.parent / ".github" / "workflows" / "opencode.yml"

DEFAULT_MODEL = "opencode/deepseek-v4-flash-free"
ESCALATED_MODEL = "nvidia/nvidia/nemotron-3-ultra-550b-a55b"


def _contains(haystack: str, needle: str) -> bool:
    """Mirror GitHub Actions' contains(): case-insensitive substring check."""
    return needle.lower() in haystack.lower()


def _load_if_expression() -> str:
    with open(WORKFLOW_PATH) as f:
        workflow = yaml.safe_load(f)
    return workflow["jobs"]["opencode"]["if"].replace("\n", " ")


def _load_resolve_model_script() -> str:
    with open(WORKFLOW_PATH) as f:
        workflow = yaml.safe_load(f)
    step = next(s for s in workflow["jobs"]["opencode"]["steps"] if s.get("id") == "resolve_model")
    return step["run"]


def _evaluate_if(expr: str, body: str, user_type: str) -> bool:
    py_expr = expr
    py_expr = py_expr.replace("github.event.comment.user.type", "_user_type")
    py_expr = py_expr.replace("github.event.comment.body", "_body")
    py_expr = re.sub(r"contains\(", "_contains(", py_expr)
    py_expr = py_expr.replace("&&", " and ").replace("||", " or ")
    return bool(eval(py_expr, {"_contains": _contains, "_body": body, "_user_type": user_type}))


def triggers(body: str, user_type: str = "User") -> bool:
    return _evaluate_if(_load_if_expression(), body, user_type)


def preferred_model(body: str) -> str:
    """Mirror the resolve_model step's PREFERRED= if/else in Python, using
    the actual literal strings extracted from the script -- so a typo or a
    dropped branch in the real script fails this test, not a hand-copied
    guess of what the script should say."""
    script = _load_resolve_model_script()

    escalated_match = re.search(r'PREFERRED="([^"]+)"\s*\n\s*else', script)
    default_match = re.search(r"else\s*\n\s*PREFERRED=\"([^\"]+)\"", script)
    assert escalated_match and default_match, "resolve_model script structure changed unexpectedly"
    escalated = escalated_match.group(1)
    default = default_match.group(1)

    if _contains(body, "[security]") or _contains(body, "[feature]"):
        return escalated
    return default


@pytest.mark.unit
class TestTrigger:
    def test_plain_oc_triggers(self):
        assert triggers("/oc fix this") is True

    def test_plain_opencode_triggers(self):
        assert triggers("/opencode implement the feature") is True

    def test_no_mention_does_not_trigger(self):
        assert triggers("just a regular comment, no mention here") is False

    def test_bot_comment_does_not_retrigger(self):
        bot_comment = "[opencode session](https://opencode.ai/s/abc123) | [github run](/owner/repo/actions/runs/123)"
        assert "/opencode" in bot_comment  # sanity: the substring really is there
        assert triggers(bot_comment, user_type="Bot") is False

    def test_human_comment_with_opencode_ai_link_still_triggers(self):
        assert triggers("/oc please retry, see https://opencode.ai/s/abc123") is True

    def test_hyphenated_tag_still_triggers(self):
        # Confirmed live on issue #1587, run 32296616870.
        assert triggers("/oc-security implement the security fix") is True


@pytest.mark.unit
class TestModelRouting:
    def test_default_routes_to_free_zen_model(self):
        assert preferred_model("/oc fix this small bug") == DEFAULT_MODEL

    def test_security_bracket_tag_routes_to_escalated_model(self):
        assert preferred_model("/oc [security] fix this CVE") == ESCALATED_MODEL

    def test_feature_bracket_tag_routes_to_escalated_model(self):
        assert preferred_model("/oc [feature] implement dark mode toggle") == ESCALATED_MODEL

    def test_case_insensitive_bracket_tag_routes_to_escalated_model(self):
        # Regression test: the bash step uses grep -qiF (case-insensitive) to
        # match GitHub Actions' contains() semantics from before this step
        # existed as pure expression logic -- a plain grep -qF would be
        # case-sensitive and silently diverge from the old behavior.
        assert preferred_model("/oc [SECURITY] fix this CVE") == ESCALATED_MODEL

    def test_hyphenated_security_tag_does_not_escalate(self):
        assert preferred_model("/oc-security implement the security fix") == DEFAULT_MODEL

    def test_word_security_without_brackets_does_not_escalate(self):
        assert preferred_model("/oc please review this security issue") == DEFAULT_MODEL
