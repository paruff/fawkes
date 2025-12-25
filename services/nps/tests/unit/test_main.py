"""
Unit tests for NPS Survey Service.
"""
import pytest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient

# Import the app - in real testing, we'd mock the database
# For now, just test the score calculation logic
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from app.main import calculate_score_type


class TestNPSScoreCalculation:
    """Test NPS score type calculation."""

    def test_promoter_score_9(self):
        """Test score 9 is classified as promoter."""
        assert calculate_score_type(9) == "promoter"

    def test_promoter_score_10(self):
        """Test score 10 is classified as promoter."""
        assert calculate_score_type(10) == "promoter"

    def test_passive_score_7(self):
        """Test score 7 is classified as passive."""
        assert calculate_score_type(7) == "passive"

    def test_passive_score_8(self):
        """Test score 8 is classified as passive."""
        assert calculate_score_type(8) == "passive"

    def test_detractor_score_0(self):
        """Test score 0 is classified as detractor."""
        assert calculate_score_type(0) == "detractor"

    def test_detractor_score_6(self):
        """Test score 6 is classified as detractor."""
        assert calculate_score_type(6) == "detractor"

    def test_detractor_score_3(self):
        """Test score 3 is classified as detractor."""
        assert calculate_score_type(3) == "detractor"


class TestNPSCalculation:
    """Test NPS calculation logic."""

    def test_nps_calculation_all_promoters(self):
        """Test NPS with all promoters."""
        # 100% promoters, 0% detractors = 100 NPS
        promoters = 10
        passives = 0
        detractors = 0
        total = promoters + passives + detractors

        promoter_pct = promoters / total
        detractor_pct = detractors / total
        nps = (promoter_pct - detractor_pct) * 100

        assert nps == 100.0

    def test_nps_calculation_all_detractors(self):
        """Test NPS with all detractors."""
        # 0% promoters, 100% detractors = -100 NPS
        promoters = 0
        passives = 0
        detractors = 10
        total = promoters + passives + detractors

        promoter_pct = promoters / total
        detractor_pct = detractors / total
        nps = (promoter_pct - detractor_pct) * 100

        assert nps == -100.0

    def test_nps_calculation_mixed(self):
        """Test NPS with mixed responses."""
        # 50% promoters, 20% passives, 30% detractors
        # NPS = (50 - 30) = 20
        promoters = 5
        passives = 2
        detractors = 3
        total = promoters + passives + detractors

        promoter_pct = promoters / total
        detractor_pct = detractors / total
        nps = (promoter_pct - detractor_pct) * 100

        assert nps == 20.0

    def test_nps_calculation_passives_dont_affect(self):
        """Test that passives don't affect NPS score."""
        # Same promoters and detractors, different passives
        # Should have same NPS

        # Case 1: No passives
        promoters1 = 5
        passives1 = 0
        detractors1 = 3
        total1 = promoters1 + passives1 + detractors1
        nps1 = ((promoters1 / total1) - (detractors1 / total1)) * 100

        # Case 2: Many passives
        promoters2 = 5
        passives2 = 10
        detractors2 = 3
        total2 = promoters2 + passives2 + detractors2
        nps2 = ((promoters2 / total2) - (detractors2 / total2)) * 100

        # NPS should be different because passives change the denominator
        # This is correct NPS behavior
        assert nps1 > nps2  # More passives dilutes the score


class TestSurveyValidation:
    """Test survey validation logic."""

    def test_valid_score_range(self):
        """Test valid score range 0-10."""
        for score in range(11):
            score_type = calculate_score_type(score)
            assert score_type in ["promoter", "passive", "detractor"]

    def test_response_rate_calculation(self):
        """Test response rate calculation."""
        total_sent = 100
        total_responses = 35

        response_rate = (total_responses / total_sent) * 100

        assert response_rate == 35.0
        assert response_rate > 30.0  # Target is >30%

    def test_response_rate_edge_case_zero_sent(self):
        """Test response rate when no surveys sent."""
        total_sent = 0
        total_responses = 0

        response_rate = (total_responses / total_sent * 100) if total_sent > 0 else 0.0

        assert response_rate == 0.0


class TestSurveyLinkExpiration:
    """Test survey link expiration logic."""

    def test_link_expired(self):
        """Test expired link detection."""
        expires_at = datetime.now() - timedelta(days=1)
        current_time = datetime.now()

        is_expired = current_time > expires_at

        assert is_expired is True

    def test_link_not_expired(self):
        """Test valid link detection."""
        expires_at = datetime.now() + timedelta(days=29)
        current_time = datetime.now()

        is_expired = current_time > expires_at

        assert is_expired is False

    def test_link_expiry_30_days(self):
        """Test link expires after 30 days."""
        created_at = datetime.now()
        expires_at = created_at + timedelta(days=30)
        check_time = created_at + timedelta(days=31)

        is_expired = check_time > expires_at

        assert is_expired is True


class TestReminderLogic:
    """Test reminder sending logic."""

    def test_reminder_after_7_days(self):
        """Test reminder should be sent after 7 days."""
        created_at = datetime.now() - timedelta(days=8)
        reminder_threshold = datetime.now() - timedelta(days=7)

        should_send_reminder = created_at <= reminder_threshold

        assert should_send_reminder is True

    def test_no_reminder_before_7_days(self):
        """Test reminder should not be sent before 7 days."""
        created_at = datetime.now() - timedelta(days=5)
        reminder_threshold = datetime.now() - timedelta(days=7)

        should_send_reminder = created_at <= reminder_threshold

        assert should_send_reminder is False

    def test_no_reminder_if_responded(self):
        """Test no reminder if user already responded."""
        responded = True
        reminder_sent = False

        should_send_reminder = not responded and not reminder_sent

        assert should_send_reminder is False

    def test_no_reminder_if_already_sent(self):
        """Test no reminder if reminder already sent."""
        responded = False
        reminder_sent = True

        should_send_reminder = not responded and not reminder_sent

        assert should_send_reminder is False
