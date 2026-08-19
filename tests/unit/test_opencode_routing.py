"""
Regression tests for .github/workflows/opencode.yml's trigger and model
routing logic.

These parse the REAL if: and model: expressions out of the workflow file and
evaluate them against sample comment payloads, rather than duplicating the
logic by hand -- so a change to the workflow's routing is tested by this
file automatically, without needing to remember to update a copy.

Each case below traces to a real bug found and fixed this session:
- bot self-retrigger (PR #1618): the bot's own "opencode session" link
  contains the literal substring "/opencode", which used to re-trigger the
  workflow before the user.type != 'Bot' guard was added.
- hyphenated tag vs. bracket tag (issue #1587): "/oc-security ..." still
  triggers the action (confirmed live) but must NOT match [security]/
  [feature] routing, since the tag isn't literally present.
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


def _load_expression(key: str) -> str:
    with open(WORKFLOW_PATH) as f:
        workflow = yaml.safe_load(f)
    job = workflow["jobs"]["opencode"]
    if key == "if":
        expr = job["if"]
    else:
        run_step = next(s for s in job["steps"] if s.get("name") == "Run OpenCode")
        expr = run_step["with"]["model"]
        expr = re.sub(r"^\s*\$\{\{\s*", "", expr)
        expr = re.sub(r"\s*\}\}\s*$", "", expr)
    return expr.replace("\n", " ")


def _evaluate(expr: str, body: str, user_type: str) -> object:
    """Translate the small subset of GitHub Actions expression syntax this
    workflow actually uses into Python, then evaluate it."""
    py_expr = expr
    py_expr = py_expr.replace("github.event.comment.user.type", "_user_type")
    py_expr = py_expr.replace("github.event.comment.body", "_body")
    py_expr = re.sub(r"contains\(", "_contains(", py_expr)
    py_expr = py_expr.replace("&&", " and ").replace("||", " or ")
    return eval(py_expr, {"_contains": _contains, "_body": body, "_user_type": user_type, "_true": True})


def triggers(body: str, user_type: str = "User") -> bool:
    return bool(_evaluate(_load_expression("if"), body, user_type))


def routed_model(body: str, user_type: str = "User") -> str:
    return _evaluate(_load_expression("model"), body, user_type)


@pytest.mark.unit
class TestTrigger:
    def test_plain_oc_triggers(self):
        assert triggers("/oc fix this") is True

    def test_plain_opencode_triggers(self):
        assert triggers("/opencode implement the feature") is True

    def test_no_mention_does_not_trigger(self):
        assert triggers("just a regular comment, no mention here") is False

    def test_bot_comment_does_not_retrigger(self):
        # Regression test for PR #1618: the bot's own status comments always
        # contain "/opencode" (from "https://opencode.ai/..." -- the "//"
        # before "opencode.ai" forms the substring "/opencode"), so without
        # the user.type guard this would incorrectly re-trigger.
        bot_comment = "[opencode session](https://opencode.ai/s/abc123) | [github run](/owner/repo/actions/runs/123)"
        assert "/opencode" in bot_comment  # sanity: the substring really is there
        assert triggers(bot_comment, user_type="Bot") is False

    def test_human_comment_with_opencode_ai_link_still_triggers(self):
        # Same substring, but a real human comment -- must still trigger.
        assert triggers("/oc please retry, see https://opencode.ai/s/abc123") is True

    def test_hyphenated_tag_still_triggers(self):
        # Confirmed live on issue #1587, run 32296616870.
        assert triggers("/oc-security implement the security fix") is True


@pytest.mark.unit
class TestModelRouting:
    def test_default_routes_to_free_zen_model(self):
        assert routed_model("/oc fix this small bug") == DEFAULT_MODEL

    def test_security_bracket_tag_routes_to_escalated_model(self):
        assert routed_model("/oc [security] fix this CVE") == ESCALATED_MODEL

    def test_feature_bracket_tag_routes_to_escalated_model(self):
        assert routed_model("/oc [feature] implement dark mode toggle") == ESCALATED_MODEL

    def test_opencode_mention_with_bracket_tag_routes_to_escalated_model(self):
        assert routed_model("/opencode [security] harden this") == ESCALATED_MODEL

    def test_hyphenated_security_tag_does_not_escalate(self):
        # Regression test for the exact confusion on issue #1587: typing
        # "/oc-security" feels like it should escalate, but the routing
        # expression checks for the literal "[security]" tag, which this
        # string does not contain -- so it must silently use the default.
        assert routed_model("/oc-security implement the security fix") == DEFAULT_MODEL

    def test_word_security_without_brackets_does_not_escalate(self):
        assert routed_model("/oc please review this security issue") == DEFAULT_MODEL
