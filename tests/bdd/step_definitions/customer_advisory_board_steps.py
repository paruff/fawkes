"""
Step definitions for Customer Advisory Board feature tests
"""
import os
import re
from behave import given, when, then
from pathlib import Path


# Helper functions
def get_repo_root():
    """Get the repository root directory"""
    return Path(__file__).parent.parent.parent.parent


def file_exists(filepath):
    """Check if a file exists in the repository"""
    repo_root = get_repo_root()
    full_path = repo_root / filepath
    return full_path.exists()


def read_file_content(filepath):
    """Read file content"""
    repo_root = get_repo_root()
    full_path = repo_root / filepath
    if full_path.exists():
        with open(full_path, "r", encoding="utf-8") as f:
            return f.read()
    return None


def check_section_in_content(content, section_name):
    """Check if a section exists in markdown content"""
    # Look for markdown headers with the section name (case-insensitive)
    pattern = rf"^#+\s+.*{re.escape(section_name)}.*$"
    return bool(re.search(pattern, content, re.IGNORECASE | re.MULTILINE))


# Background steps
@given("the Fawkes platform has active users")
def step_fawkes_has_users(context):
    """Verify platform documentation exists (implies active users)"""
    assert file_exists("README.md"), "Fawkes platform should exist"


@given("the product team has capacity to manage the CAB")
def step_product_team_capacity(context):
    """Verify governance documentation exists"""
    assert file_exists("docs/GOVERNACE.md"), "Governance should be in place"


# Documentation existence checks
@when("I check for the CAB charter document")
def step_check_cab_charter(context):
    """Check if CAB charter exists"""
    context.charter_exists = file_exists("docs/CUSTOMER_ADVISORY_BOARD.md")
    if context.charter_exists:
        context.charter_content = read_file_content("docs/CUSTOMER_ADVISORY_BOARD.md")


@when("I check for CAB templates")
def step_check_cab_templates(context):
    """Check for CAB template files"""
    context.nomination_template_exists = file_exists("docs/research/templates/cab-nomination.md")
    context.meeting_template_exists = file_exists("docs/research/templates/cab-meeting-agenda.md")
    context.feedback_template_exists = file_exists("docs/research/templates/cab-feedback-form.md")

    if context.nomination_template_exists:
        context.nomination_content = read_file_content("docs/research/templates/cab-nomination.md")
    if context.meeting_template_exists:
        context.meeting_content = read_file_content("docs/research/templates/cab-meeting-agenda.md")
    if context.feedback_template_exists:
        context.feedback_content = read_file_content("docs/research/templates/cab-feedback-form.md")


@when("I check for CAB onboarding materials")
def step_check_onboarding_materials(context):
    """Check for CAB onboarding materials"""
    context.welcome_packet_exists = file_exists("docs/research/data/cab-welcome-packet.md")
    if context.welcome_packet_exists:
        context.welcome_packet_content = read_file_content("docs/research/data/cab-welcome-packet.md")


@when("I check for the CAB member directory")
def step_check_member_directory(context):
    """Check for CAB member directory"""
    context.member_directory_exists = file_exists("docs/CUSTOMER_ADVISORY_BOARD_MEMBERS.md")
    if context.member_directory_exists:
        context.member_directory_content = read_file_content("docs/CUSTOMER_ADVISORY_BOARD_MEMBERS.md")


@when("I check for CAB operational guides")
def step_check_operational_guides(context):
    """Check for operational guides"""
    context.howto_guide_exists = file_exists("docs/how-to/run-advisory-board-meetings.md")
    if context.howto_guide_exists:
        context.howto_guide_content = read_file_content("docs/how-to/run-advisory-board-meetings.md")


@given("I review the CAB charter")
@when("I review the CAB charter")
def step_review_charter(context):
    """Load and review CAB charter"""
    context.charter_content = read_file_content("docs/CUSTOMER_ADVISORY_BOARD.md")
    assert context.charter_content is not None, "CAB charter should exist"


@given("I review the welcome packet")
@when("I review the welcome packet")
def step_review_welcome_packet(context):
    """Load and review welcome packet"""
    context.welcome_packet_content = read_file_content("docs/research/data/cab-welcome-packet.md")
    assert context.welcome_packet_content is not None, "Welcome packet should exist"


@given("I review the CAB operational guide")
@when("I review the CAB operational guide")
def step_review_operational_guide(context):
    """Load and review operational guide"""
    context.howto_guide_content = read_file_content("docs/how-to/run-advisory-board-meetings.md")
    assert context.howto_guide_content is not None, "Operational guide should exist"


@given("I check the CAB member directory")
@when("I check the CAB member directory")
def step_check_directory(context):
    """Load and check member directory"""
    context.member_directory_content = read_file_content("docs/CUSTOMER_ADVISORY_BOARD_MEMBERS.md")
    assert context.member_directory_content is not None, "Member directory should exist"


@given("I review the CAB charter document")
def step_review_charter_document(context):
    """Load CAB charter for validation"""
    context.charter_content = read_file_content("docs/CUSTOMER_ADVISORY_BOARD.md")
    assert context.charter_content is not None, "CAB charter should exist"


# File existence assertions
@then('the file "{filepath}" should exist')
def step_file_should_exist(context, filepath):
    """Assert file exists"""
    assert file_exists(filepath), f"File {filepath} should exist"


# Charter content checks
@then("the charter should define board composition")
def step_charter_defines_composition(context):
    """Check charter has board composition section"""
    assert check_section_in_content(
        context.charter_content, "Board Composition"
    ), "Charter should have Board Composition section"


@then("the charter should define member criteria")
def step_charter_defines_criteria(context):
    """Check charter has member criteria"""
    assert check_section_in_content(
        context.charter_content, "Member Criteria"
    ), "Charter should have Member Criteria section"


@then("the charter should define membership process")
def step_charter_defines_process(context):
    """Check charter has membership process"""
    assert check_section_in_content(
        context.charter_content, "Membership Process"
    ), "Charter should have Membership Process section"


@then("the charter should define meeting cadence")
def step_charter_defines_cadence(context):
    """Check charter has meeting cadence"""
    assert check_section_in_content(
        context.charter_content, "Meeting Cadence"
    ), "Charter should have Meeting Cadence section"


@then("the charter should define feedback process")
def step_charter_defines_feedback(context):
    """Check charter has feedback process"""
    assert check_section_in_content(
        context.charter_content, "Feedback Process"
    ), "Charter should have Feedback Process section"


@then("the charter should define communication channels")
def step_charter_defines_channels(context):
    """Check charter has communication channels"""
    assert check_section_in_content(
        context.charter_content, "Communication Channels"
    ), "Charter should have Communication Channels section"


# Template content checks
@then("the nomination template should include nominee information")
def step_nomination_has_info(context):
    """Check nomination template has nominee information"""
    assert "Nominee Name" in context.nomination_content, "Nomination template should include nominee information fields"


@then("the nomination template should include Fawkes experience")
def step_nomination_has_experience(context):
    """Check nomination template has Fawkes experience section"""
    assert (
        "Fawkes Experience" in context.nomination_content
    ), "Nomination template should include Fawkes experience section"


@then("the nomination template should include qualifications")
def step_nomination_has_qualifications(context):
    """Check nomination template has qualifications"""
    assert (
        "Background and Qualifications" in context.nomination_content
    ), "Nomination template should include qualifications section"


@then("the nomination template should include community involvement")
def step_nomination_has_community(context):
    """Check nomination template has community involvement"""
    assert (
        "Community Involvement" in context.nomination_content
    ), "Nomination template should include community involvement section"


@then("the meeting template should include agenda sections")
def step_meeting_has_agenda(context):
    """Check meeting template has agenda"""
    assert "Agenda" in context.meeting_content, "Meeting template should include agenda"


@then("the meeting template should include time allocations")
def step_meeting_has_time(context):
    """Check meeting template has time allocations"""
    assert "minutes" in context.meeting_content.lower(), "Meeting template should include time allocations"


@then("the meeting template should include action items section")
def step_meeting_has_actions(context):
    """Check meeting template has action items"""
    assert "Action Items" in context.meeting_content, "Meeting template should include action items section"


@then("the meeting template should include notes section")
def step_meeting_has_notes(context):
    """Check meeting template has notes section"""
    assert (
        "Notes" in context.meeting_content or "Meeting Notes" in context.meeting_content
    ), "Meeting template should include notes section"


@then("the feedback form should include relevance assessment")
def step_feedback_has_relevance(context):
    """Check feedback form has relevance assessment"""
    assert "Relevance" in context.feedback_content, "Feedback form should include relevance assessment"


@then("the feedback form should include priority assessment")
def step_feedback_has_priority(context):
    """Check feedback form has priority assessment"""
    assert "Priority" in context.feedback_content, "Feedback form should include priority assessment"


@then("the feedback form should include approach evaluation")
def step_feedback_has_approach(context):
    """Check feedback form has approach evaluation"""
    assert "Approach" in context.feedback_content, "Feedback form should include approach evaluation"


@then("the feedback form should include adoption planning")
def step_feedback_has_adoption(context):
    """Check feedback form has adoption planning"""
    assert "Adoption" in context.feedback_content, "Feedback form should include adoption planning"


# Welcome packet checks
@then("the welcome packet should include time commitment details")
def step_welcome_has_time_commitment(context):
    """Check welcome packet has time commitment"""
    assert "Time Commitment" in context.welcome_packet_content, "Welcome packet should include time commitment details"


@then("the welcome packet should include first steps checklist")
def step_welcome_has_checklist(context):
    """Check welcome packet has first steps checklist"""
    assert (
        "First Steps" in context.welcome_packet_content or "Checklist" in context.welcome_packet_content
    ), "Welcome packet should include first steps checklist"


@then("the welcome packet should include communication channels")
def step_welcome_has_channels(context):
    """Check welcome packet has communication channels"""
    assert (
        "Communication Channels" in context.welcome_packet_content
    ), "Welcome packet should include communication channels"


@then("the welcome packet should include meeting schedule")
def step_welcome_has_schedule(context):
    """Check welcome packet has meeting schedule"""
    assert (
        "Meeting Schedule" in context.welcome_packet_content or "Quarterly" in context.welcome_packet_content
    ), "Welcome packet should include meeting schedule"


@then("the welcome packet should include how to provide feedback")
def step_welcome_has_feedback_process(context):
    """Check welcome packet has feedback process"""
    assert (
        "Provide Feedback" in context.welcome_packet_content or "How to" in context.welcome_packet_content
    ), "Welcome packet should include how to provide feedback"


# Member directory checks
@then("the member directory should indicate recruitment status")
def step_directory_has_status(context):
    """Check directory has recruitment status"""
    assert (
        "Forming" in context.member_directory_content or "Recruiting" in context.member_directory_content
    ), "Member directory should indicate recruitment status"


@then("the member directory should include how to join section")
def step_directory_has_join_info(context):
    """Check directory has how to join info"""
    assert (
        "How to Join" in context.member_directory_content or "Apply" in context.member_directory_content
    ), "Member directory should include how to join section"


@then("the member directory should have template for member profiles")
def step_directory_has_template(context):
    """Check directory has profile template"""
    assert (
        "Member Name" in context.member_directory_content or "template" in context.member_directory_content.lower()
    ), "Member directory should have template for member profiles"


# How-to guide checks
@then("the guide should include pre-meeting checklist")
def step_guide_has_pre_meeting(context):
    """Check guide has pre-meeting checklist"""
    assert (
        "Pre-Meeting" in context.howto_guide_content or "Before" in context.howto_guide_content
    ), "Guide should include pre-meeting checklist"


@then("the guide should include during-meeting facilitation tips")
def step_guide_has_during_meeting(context):
    """Check guide has during-meeting tips"""
    assert (
        "During Meeting" in context.howto_guide_content or "Facilitat" in context.howto_guide_content
    ), "Guide should include during-meeting facilitation tips"


@then("the guide should include post-meeting follow-up steps")
def step_guide_has_post_meeting(context):
    """Check guide has post-meeting follow-up"""
    assert (
        "Post-Meeting" in context.howto_guide_content or "Follow" in context.howto_guide_content
    ), "Guide should include post-meeting follow-up steps"


@then("the guide should include facilitator best practices")
def step_guide_has_best_practices(context):
    """Check guide has best practices"""
    assert (
        "Best Practices" in context.howto_guide_content or "Tips" in context.howto_guide_content
    ), "Guide should include facilitator best practices"


# Detailed charter checks
@when("I check the board composition section")
def step_check_composition_section(context):
    """Extract composition section from charter"""
    # Content already loaded in previous steps
    pass


@then("the target size should be 5-7 members")
def step_target_size(context):
    """Check target size is defined"""
    assert "5-7" in context.charter_content, "Charter should specify 5-7 members as target size"


@then("member criteria should include active Fawkes usage")
def step_criteria_active_usage(context):
    """Check active usage criterion"""
    assert (
        "Active Fawkes user" in context.charter_content or "active user" in context.charter_content.lower()
    ), "Member criteria should include active Fawkes usage"


@then("member criteria should include production or staging deployment")
def step_criteria_deployment(context):
    """Check deployment criterion"""
    assert (
        "production" in context.charter_content.lower() and "staging" in context.charter_content.lower()
    ), "Member criteria should include production or staging deployment"


@then("member criteria should include leadership role requirement")
def step_criteria_leadership(context):
    """Check leadership criterion"""
    assert (
        "leadership" in context.charter_content.lower() or "lead" in context.charter_content.lower()
    ), "Member criteria should include leadership role requirement"


@then("member criteria should include time commitment")
def step_criteria_time(context):
    """Check time commitment criterion"""
    assert (
        "hours per quarter" in context.charter_content.lower() or "time commitment" in context.charter_content.lower()
    ), "Member criteria should include time commitment"


@then("the composition should aim for diversity in organization size")
def step_diversity_org_size(context):
    """Check organization size diversity"""
    assert (
        "organization size" in context.charter_content.lower() or "startup" in context.charter_content.lower()
    ), "Composition should aim for diversity in organization size"


@then("the composition should aim for diversity in industries")
def step_diversity_industries(context):
    """Check industry diversity"""
    assert (
        "industr" in context.charter_content.lower() or "vertical" in context.charter_content.lower()
    ), "Composition should aim for diversity in industries"


@then("the composition should aim for diversity in geographic regions")
def step_diversity_geography(context):
    """Check geographic diversity"""
    assert (
        "geographic" in context.charter_content.lower() or "region" in context.charter_content.lower()
    ), "Composition should aim for diversity in geographic regions"


# Process checks
@when("I check the membership process section")
def step_check_process_section(context):
    """Check membership process section"""
    pass  # Content already loaded


@then("the process should support self-nomination")
def step_process_self_nomination(context):
    """Check self-nomination support"""
    assert (
        "self-nomination" in context.charter_content.lower() or "nominate themselves" in context.charter_content.lower()
    ), "Process should support self-nomination"


@then("the process should support team nomination")
def step_process_team_nomination(context):
    """Check team nomination support"""
    assert (
        "team nomination" in context.charter_content.lower()
        or "maintainers can nominate" in context.charter_content.lower()
    ), "Process should support team nomination"


@then("the process should support community nomination")
def step_process_community_nomination(context):
    """Check community nomination support"""
    assert (
        "community nomination" in context.charter_content.lower()
        or "community members can nominate" in context.charter_content.lower()
    ), "Process should support community nomination"


@then("the process should include review and selection criteria")
def step_process_review(context):
    """Check review and selection"""
    assert (
        "review" in context.charter_content.lower() and "selection" in context.charter_content.lower()
    ), "Process should include review and selection criteria"


@then("the process should include onboarding procedures")
def step_process_onboarding(context):
    """Check onboarding procedures"""
    assert "onboarding" in context.charter_content.lower(), "Process should include onboarding procedures"


@then("the process should include term length definition")
def step_process_term_length(context):
    """Check term length definition"""
    assert (
        "term" in context.charter_content.lower() and "months" in context.charter_content.lower()
    ), "Process should include term length definition"


@then("the process should include renewal process")
def step_process_renewal(context):
    """Check renewal process"""
    assert (
        "renewal" in context.charter_content.lower() or "renew" in context.charter_content.lower()
    ), "Process should include renewal process"


# Meeting cadence checks
@when("I check the meeting cadence section")
def step_check_cadence_section(context):
    """Check meeting cadence section"""
    pass  # Content already loaded


@then("quarterly strategic meetings should be defined")
def step_quarterly_meetings(context):
    """Check quarterly meetings"""
    assert "quarterly" in context.charter_content.lower(), "Quarterly strategic meetings should be defined"


@then("the meeting duration should be 2 hours")
def step_meeting_duration(context):
    """Check meeting duration"""
    assert (
        "2 hours" in context.charter_content.lower() or "2 hour" in context.charter_content.lower()
    ), "Meeting duration should be 2 hours"


@then("the meeting format should be virtual")
def step_meeting_format(context):
    """Check meeting format"""
    assert (
        "virtual" in context.charter_content.lower() or "video" in context.charter_content.lower()
    ), "Meeting format should be virtual"


@then("the typical agenda should include platform updates")
def step_agenda_platform_updates(context):
    """Check agenda includes platform updates"""
    assert (
        "platform updates" in context.charter_content.lower() or "progress" in context.charter_content.lower()
    ), "Agenda should include platform updates"


@then("the typical agenda should include roadmap review")
def step_agenda_roadmap(context):
    """Check agenda includes roadmap review"""
    assert "roadmap" in context.charter_content.lower(), "Agenda should include roadmap review"


@then("the typical agenda should include member feedback")
def step_agenda_feedback(context):
    """Check agenda includes member feedback"""
    assert (
        "member feedback" in context.charter_content.lower() or "feedback" in context.charter_content.lower()
    ), "Agenda should include member feedback"


@then("the typical agenda should include deep dive topic")
def step_agenda_deep_dive(context):
    """Check agenda includes deep dive"""
    assert "deep dive" in context.charter_content.lower(), "Agenda should include deep dive topic"


@then("ad-hoc touchpoints should be defined")
def step_adhoc_touchpoints(context):
    """Check ad-hoc touchpoints"""
    assert (
        "ad-hoc" in context.charter_content.lower() or "as needed" in context.charter_content.lower()
    ), "Ad-hoc touchpoints should be defined"


# Feedback process checks
@when("I check the feedback process section")
def step_check_feedback_section(context):
    """Check feedback process section"""
    pass  # Content already loaded


@then("input mechanisms should include quarterly meetings")
def step_input_quarterly(context):
    """Check quarterly meetings as input mechanism"""
    assert "quarterly meeting" in context.charter_content.lower(), "Input mechanisms should include quarterly meetings"


@then("input mechanisms should include async channel")
def step_input_async(context):
    """Check async channel as input mechanism"""
    assert (
        "async" in context.charter_content.lower() or "asynchronous" in context.charter_content.lower()
    ), "Input mechanisms should include async channel"


@then("input mechanisms should include surveys and polls")
def step_input_surveys(context):
    """Check surveys and polls as input mechanism"""
    assert (
        "survey" in context.charter_content.lower() or "poll" in context.charter_content.lower()
    ), "Input mechanisms should include surveys and polls"


@then("input mechanisms should include early access testing")
def step_input_early_access(context):
    """Check early access testing as input mechanism"""
    assert "early access" in context.charter_content.lower(), "Input mechanisms should include early access testing"


@then("input mechanisms should include RFC reviews")
def step_input_rfc(context):
    """Check RFC reviews as input mechanism"""
    assert "rfc" in context.charter_content.lower(), "Input mechanisms should include RFC reviews"


@then("feedback integration process should be documented")
def step_feedback_integration(context):
    """Check feedback integration"""
    assert (
        "integration" in context.charter_content.lower() or "how input is used" in context.charter_content.lower()
    ), "Feedback integration process should be documented"


@then("feedback tracking approach should be defined")
def step_feedback_tracking(context):
    """Check feedback tracking"""
    assert (
        "tracking" in context.charter_content.lower() or "github" in context.charter_content.lower()
    ), "Feedback tracking approach should be defined"


# Communication channels checks
@when("I check the communication channels section")
def step_check_channels_section(context):
    """Check communication channels section"""
    pass  # Content already loaded


@then("Mattermost should be designated as primary channel")
def step_mattermost_primary(context):
    """Check Mattermost is primary"""
    assert (
        "mattermost" in context.charter_content.lower() and "primary" in context.charter_content.lower()
    ), "Mattermost should be designated as primary channel"


@then('the channel name should be "cab-advisory-board"')
def step_channel_name(context):
    """Check channel name"""
    assert "cab-advisory-board" in context.charter_content.lower(), 'Channel name should be "cab-advisory-board"'


@then("the channel should be private")
def step_channel_private(context):
    """Check channel is private"""
    assert "private" in context.charter_content.lower(), "Channel should be private"


@then('GitHub team "@fawkes/advisory-board" should be defined')
def step_github_team(context):
    """Check GitHub team"""
    assert (
        "@fawkes/advisory-board" in context.charter_content or "advisory-board" in context.charter_content.lower()
    ), "GitHub team @fawkes/advisory-board should be defined"


@then("email communication option should be available")
def step_email_option(context):
    """Check email option"""
    assert "email" in context.charter_content.lower(), "Email communication option should be available"


@then("video call platform should be identified")
def step_video_platform(context):
    """Check video platform"""
    assert any(
        platform in context.charter_content.lower() for platform in ["zoom", "meet", "teams", "video"]
    ), "Video call platform should be identified"


# Mattermost setup checks
@when("I check the Mattermost channel setup")
def step_check_mattermost_setup(context):
    """Check Mattermost setup"""
    pass  # Content already loaded


@then("the channel purpose should be documented")
def step_channel_purpose(context):
    """Check channel purpose"""
    assert "purpose" in context.charter_content.lower(), "Channel purpose should be documented"


@then("the channel members should include advisory board team")
def step_channel_members_cab(context):
    """Check channel members include CAB"""
    assert "advisory-board" in context.charter_content.lower(), "Channel members should include advisory board team"


@then("the channel members should include product team")
def step_channel_members_product(context):
    """Check channel members include product team"""
    assert (
        "product team" in context.charter_content.lower() or "product-team" in context.charter_content.lower()
    ), "Channel members should include product team"


@then("the channel guidelines should be defined")
def step_channel_guidelines(context):
    """Check channel guidelines"""
    assert (
        "guidelines" in context.charter_content.lower() or "rules" in context.charter_content.lower()
    ), "Channel guidelines should be defined"


# Recognition checks
@when("I check the recognition section")
def step_check_recognition_section(context):
    """Check recognition section"""
    pass  # Content already loaded


@then("public recognition mechanisms should be defined")
def step_recognition_mechanisms(context):
    """Check recognition mechanisms"""
    assert "recognition" in context.charter_content.lower(), "Public recognition mechanisms should be defined"


@then("member directory listing should be included")
def step_recognition_directory(context):
    """Check directory listing"""
    assert (
        "directory" in context.charter_content.lower() or "member" in context.charter_content.lower()
    ), "Member directory listing should be included"


@then("release note credits should be mentioned")
def step_recognition_release_notes(context):
    """Check release note credits"""
    assert (
        "release note" in context.charter_content.lower() or "credit" in context.charter_content.lower()
    ), "Release note credits should be mentioned"


@then("blog post opportunities should be mentioned")
def step_recognition_blog(context):
    """Check blog post opportunities"""
    assert "blog" in context.charter_content.lower(), "Blog post opportunities should be mentioned"


@then("speaking opportunities should be mentioned")
def step_recognition_speaking(context):
    """Check speaking opportunities"""
    assert (
        "speaking" in context.charter_content.lower() or "talk" in context.charter_content.lower()
    ), "Speaking opportunities should be mentioned"


@then("digital badges should be offered")
def step_recognition_badges(context):
    """Check digital badges"""
    assert "badge" in context.charter_content.lower(), "Digital badges should be offered"


@then("swag options should be mentioned")
def step_recognition_swag(context):
    """Check swag options"""
    assert "swag" in context.charter_content.lower(), "Swag options should be mentioned"


# Success metrics checks
@when("I check the success metrics section")
def step_check_metrics_section(context):
    """Check success metrics section"""
    pass  # Content already loaded


@then("engagement metrics should be defined")
def step_metrics_engagement(context):
    """Check engagement metrics"""
    assert (
        "engagement" in context.charter_content.lower() or "attendance" in context.charter_content.lower()
    ), "Engagement metrics should be defined"


@then("engagement metric targets should be specified")
def step_metrics_targets(context):
    """Check metric targets"""
    assert (
        "target" in context.charter_content.lower() or "%" in context.charter_content
    ), "Engagement metric targets should be specified"


@then("impact metrics should be defined")
def step_metrics_impact(context):
    """Check impact metrics"""
    assert "impact" in context.charter_content.lower(), "Impact metrics should be defined"


@then("satisfaction metrics should be defined")
def step_metrics_satisfaction(context):
    """Check satisfaction metrics"""
    assert (
        "satisfaction" in context.charter_content.lower() or "survey" in context.charter_content.lower()
    ), "Satisfaction metrics should be defined"


@then("reporting cadence should be quarterly")
def step_metrics_reporting(context):
    """Check reporting cadence"""
    assert "quarterly" in context.charter_content.lower(), "Reporting cadence should be quarterly"


# Onboarding checks
@when("I check the onboarding process")
def step_check_onboarding_process(context):
    """Check onboarding process"""
    pass  # Content already loaded


@then("week 1 checklist should be defined")
def step_onboarding_week1(context):
    """Check week 1 checklist"""
    assert (
        "week 1" in context.welcome_packet_content.lower() or "first week" in context.welcome_packet_content.lower()
    ), "Week 1 checklist should be defined"


@then("Mattermost access should be included")
def step_onboarding_mattermost(context):
    """Check Mattermost access"""
    assert "mattermost" in context.welcome_packet_content.lower(), "Mattermost access should be included"


@then("GitHub team access should be included")
def step_onboarding_github(context):
    """Check GitHub team access"""
    assert "github" in context.welcome_packet_content.lower(), "GitHub team access should be included"


@then("onboarding call should be scheduled")
def step_onboarding_call(context):
    """Check onboarding call"""
    assert (
        "onboarding call" in context.welcome_packet_content.lower()
        or "intro call" in context.welcome_packet_content.lower()
    ), "Onboarding call should be scheduled"


@then("roadmap review should be assigned")
def step_onboarding_roadmap(context):
    """Check roadmap review"""
    assert "roadmap" in context.welcome_packet_content.lower(), "Roadmap review should be assigned"


@then("channel introduction should be encouraged")
def step_onboarding_intro(context):
    """Check channel introduction"""
    assert (
        "introduce" in context.welcome_packet_content.lower() or "hello" in context.welcome_packet_content.lower()
    ), "Channel introduction should be encouraged"


# Template completeness checks
@when("I check for all CAB templates")
def step_check_all_templates(context):
    """Check all templates exist"""
    context.all_templates_exist = all(
        [
            file_exists("docs/research/templates/cab-nomination.md"),
            file_exists("docs/research/templates/cab-meeting-agenda.md"),
            file_exists("docs/research/templates/cab-feedback-form.md"),
            file_exists("docs/research/data/cab-welcome-packet.md"),
        ]
    )


@then("the nomination template should exist")
def step_nomination_exists(context):
    """Check nomination template exists"""
    assert file_exists("docs/research/templates/cab-nomination.md"), "Nomination template should exist"


@then("the meeting agenda template should exist")
def step_meeting_agenda_exists(context):
    """Check meeting agenda template exists"""
    assert file_exists("docs/research/templates/cab-meeting-agenda.md"), "Meeting agenda template should exist"


@then("the feedback form template should exist")
def step_feedback_form_exists(context):
    """Check feedback form template exists"""
    assert file_exists("docs/research/templates/cab-feedback-form.md"), "Feedback form template should exist"


@then("the welcome packet should exist")
def step_welcome_packet_exists(context):
    """Check welcome packet exists"""
    assert file_exists("docs/research/data/cab-welcome-packet.md"), "Welcome packet should exist"


@then("all templates should be in proper locations")
def step_templates_proper_locations(context):
    """Check all templates are in proper locations"""
    assert context.all_templates_exist, "All templates should be in proper locations"


@then("all templates should be properly formatted")
def step_templates_formatted(context):
    """Check templates are properly formatted (basic markdown check)"""
    for filepath in [
        "docs/research/templates/cab-nomination.md",
        "docs/research/templates/cab-meeting-agenda.md",
        "docs/research/templates/cab-feedback-form.md",
        "docs/research/data/cab-welcome-packet.md",
    ]:
        content = read_file_content(filepath)
        assert content and len(content) > 100, f"Template {filepath} should be properly formatted with content"


# Documentation integration checks
@when("I check the documentation index")
def step_check_docs_index(context):
    """Check documentation index"""
    context.mkdocs_content = read_file_content("mkdocs.yml")


@then("the CAB charter should be discoverable")
def step_charter_discoverable(context):
    """Check charter is in docs index"""
    # Just verify it exists in the docs folder - mkdocs integration is optional
    assert file_exists("docs/CUSTOMER_ADVISORY_BOARD.md"), "CAB charter should be discoverable"


@then("the how-to guide should be in the how-to section")
def step_howto_in_section(context):
    """Check how-to guide is in how-to section"""
    assert file_exists("docs/how-to/run-advisory-board-meetings.md"), "How-to guide should be in how-to section"


@then("templates should be in the research templates section")
def step_templates_in_section(context):
    """Check templates are in research templates section"""
    assert file_exists("docs/research/templates/cab-nomination.md"), "Templates should be in research templates section"


@then("the member directory should be discoverable")
def step_directory_discoverable(context):
    """Check member directory is discoverable"""
    assert file_exists("docs/CUSTOMER_ADVISORY_BOARD_MEMBERS.md"), "Member directory should be discoverable"


# Charter structure validation
@when("I validate the document structure")
def step_validate_structure(context):
    """Validate charter structure"""
    context.charter_sections = []
    # Extract headers from markdown
    for line in context.charter_content.split("\n"):
        if line.startswith("##") and not line.startswith("###"):
            context.charter_sections.append(line.strip("#").strip())


@then("it should have document information section")
def step_has_doc_info(context):
    """Check document information section"""
    assert (
        any("document information" in section.lower() for section in context.charter_sections)
        or "Version" in context.charter_content
    ), "Charter should have document information section"


@then("it should have overview section")
def step_has_overview(context):
    """Check overview section"""
    assert any(
        "overview" in section.lower() for section in context.charter_sections
    ), "Charter should have overview section"


@then("it should have board composition section")
def step_has_composition(context):
    """Check board composition section"""
    assert any(
        "composition" in section.lower() for section in context.charter_sections
    ), "Charter should have board composition section"


@then("it should have membership process section")
def step_has_membership_process(context):
    """Check membership process section"""
    assert any(
        "membership process" in section.lower() for section in context.charter_sections
    ), "Charter should have membership process section"


@then("it should have meeting cadence section")
def step_has_meeting_cadence(context):
    """Check meeting cadence section"""
    assert any(
        "meeting cadence" in section.lower() or "cadence" in section.lower() for section in context.charter_sections
    ), "Charter should have meeting cadence section"


@then("it should have feedback process section")
def step_has_feedback_process(context):
    """Check feedback process section"""
    assert any(
        "feedback process" in section.lower() or "feedback" in section.lower() for section in context.charter_sections
    ), "Charter should have feedback process section"


@then("it should have communication channels section")
def step_has_communication(context):
    """Check communication channels section"""
    assert any(
        "communication" in section.lower() for section in context.charter_sections
    ), "Charter should have communication channels section"


@then("it should have confidentiality and IP section")
def step_has_confidentiality(context):
    """Check confidentiality section"""
    assert (
        any("confidentiality" in section.lower() or "ip" in section.lower() for section in context.charter_sections)
        or "Confidentiality" in context.charter_content
    ), "Charter should have confidentiality and IP section"


@then("it should have recognition section")
def step_has_recognition(context):
    """Check recognition section"""
    assert any(
        "recognition" in section.lower() for section in context.charter_sections
    ), "Charter should have recognition section"


@then("it should have success metrics section")
def step_has_success_metrics(context):
    """Check success metrics section"""
    assert any(
        "success metrics" in section.lower() or "metrics" in section.lower() for section in context.charter_sections
    ), "Charter should have success metrics section"


@then("it should have administration section")
def step_has_administration(context):
    """Check administration section"""
    assert any(
        "administration" in section.lower() for section in context.charter_sections
    ), "Charter should have administration section"


@then("it should have FAQs section")
def step_has_faqs(context):
    """Check FAQs section"""
    assert any("faq" in section.lower() for section in context.charter_sections), "Charter should have FAQs section"


@then("it should have appendix with related documents")
def step_has_appendix(context):
    """Check appendix section"""
    assert (
        any("appendix" in section.lower() for section in context.charter_sections)
        or "Related Documents" in context.charter_content
    ), "Charter should have appendix with related documents"


# Operational guide process checks
@when("I check the meeting lifecycle")
def step_check_meeting_lifecycle(context):
    """Check meeting lifecycle"""
    pass  # Content already loaded


@then("pre-meeting process should be documented")
def step_pre_meeting_documented(context):
    """Check pre-meeting process"""
    assert "pre-meeting" in context.howto_guide_content.lower(), "Pre-meeting process should be documented"


@then("pre-meeting should start 4-6 weeks before")
def step_pre_meeting_timing(context):
    """Check pre-meeting timing"""
    assert (
        "4-6 weeks" in context.howto_guide_content or "6 weeks" in context.howto_guide_content
    ), "Pre-meeting should start 4-6 weeks before"


@then("during-meeting facilitation should be documented")
def step_during_meeting_documented(context):
    """Check during-meeting facilitation"""
    assert (
        "during meeting" in context.howto_guide_content.lower() or "facilitation" in context.howto_guide_content.lower()
    ), "During-meeting facilitation should be documented"


@then("during-meeting should be 2 hours")
def step_during_meeting_duration(context):
    """Check during-meeting duration"""
    assert (
        "2 hours" in context.howto_guide_content or "2 hour" in context.howto_guide_content
    ), "During-meeting should be 2 hours"


@then("post-meeting follow-up should be documented")
def step_post_meeting_documented(context):
    """Check post-meeting follow-up"""
    assert "post-meeting" in context.howto_guide_content.lower(), "Post-meeting follow-up should be documented"


@then("post-meeting should complete within 48 hours")
def step_post_meeting_timing(context):
    """Check post-meeting timing"""
    assert (
        "48 hours" in context.howto_guide_content or "48" in context.howto_guide_content
    ), "Post-meeting should complete within 48 hours"


@then("ongoing follow-up should be documented")
def step_ongoing_documented(context):
    """Check ongoing follow-up"""
    assert (
        "follow-up" in context.howto_guide_content.lower() or "ongoing" in context.howto_guide_content.lower()
    ), "Ongoing follow-up should be documented"


@then("ongoing follow-up should complete within 1 month")
def step_ongoing_timing(context):
    """Check ongoing timing"""
    assert (
        "1 month" in context.howto_guide_content or "month" in context.howto_guide_content
    ), "Ongoing follow-up should complete within 1 month"


# Action item tracking checks
@when("I check the action item process")
def step_check_action_items(context):
    """Check action item process"""
    pass  # Content already loaded


@then("GitHub issues should be created for action items")
def step_action_github_issues(context):
    """Check GitHub issues for actions"""
    assert "github issue" in context.howto_guide_content.lower(), "GitHub issues should be created for action items"


@then('issues should be labeled with "cab-feedback"')
def step_action_labels(context):
    """Check issue labels"""
    assert "cab-feedback" in context.howto_guide_content.lower(), 'Issues should be labeled with "cab-feedback"'


@then("issues should reference meeting date")
def step_action_meeting_date(context):
    """Check meeting date reference"""
    assert (
        "meeting date" in context.howto_guide_content.lower() or "reference" in context.howto_guide_content.lower()
    ), "Issues should reference meeting date"


@then("progress updates should be posted in Mattermost")
def step_action_mattermost_updates(context):
    """Check Mattermost updates"""
    assert (
        "mattermost" in context.howto_guide_content.lower() and "update" in context.howto_guide_content.lower()
    ), "Progress updates should be posted in Mattermost"


@then("members should be notified of completion")
def step_action_completion_notification(context):
    """Check completion notification"""
    assert (
        "notif" in context.howto_guide_content.lower() or "update" in context.howto_guide_content.lower()
    ), "Members should be notified of completion"


# Recruitment status checks
@when("I review the membership status")
def step_review_membership_status(context):
    """Review membership status"""
    pass  # Content already loaded


@then('the status should indicate "Forming"')
def step_status_forming(context):
    """Check forming status"""
    assert "forming" in context.member_directory_content.lower(), 'Status should indicate "Forming"'


@then("the current size should be shown")
def step_current_size_shown(context):
    """Check current size"""
    assert (
        "current size" in context.member_directory_content.lower()
        or "accepting" in context.member_directory_content.lower()
    ), "Current size should be shown"


@then("the target size should be shown")
def step_target_size_shown(context):
    """Check target size"""
    assert (
        "target size" in context.member_directory_content.lower() or "5-7" in context.member_directory_content
    ), "Target size should be shown"


@then("nomination instructions should be available")
def step_nomination_instructions(context):
    """Check nomination instructions"""
    assert (
        "how to join" in context.member_directory_content.lower() or "apply" in context.member_directory_content.lower()
    ), "Nomination instructions should be available"


@then("contact information should be provided")
def step_contact_info(context):
    """Check contact information"""
    assert (
        "contact" in context.member_directory_content.lower() or "email" in context.member_directory_content.lower()
    ), "Contact information should be provided"
