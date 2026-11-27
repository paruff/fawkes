"""ADR-039 rule 5: common may only name a package at the version each monolith pins."""

from pathlib import Path

import pytest

SERVICES = Path(__file__).resolve().parents[2]
# Skipped as an empty parameter set until the first monolith exists.
MONOLITHS = sorted(SERVICES.glob("fawkes-*/requirements.txt"))


def pins(path: Path) -> dict[str, str]:
    """Package name (extras dropped) to exact version."""
    lines = (line.split("#")[0].strip() for line in path.read_text().splitlines())
    return {name.split("[")[0].lower(): version for name, _, version in (x.partition("==") for x in lines if x)}


@pytest.mark.parametrize("monolith", MONOLITHS, ids=lambda path: path.parent.name)
def test_common_pins_match_the_monolith(monolith):
    common = pins(SERVICES / "common" / "requirements.txt")
    theirs = pins(monolith)

    assert {name: theirs.get(name) for name in common} == common
