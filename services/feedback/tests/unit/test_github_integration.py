"""
Unit tests for GitHub integration module.
"""
import pytest
from unittest.mock import Mock, AsyncMock, patch
import httpx

from app.github_integration import (
    is_github_enabled,
    create_github_issue,
    update_issue_status,
    _attach_screenshot_to_issue
)


class TestGitHubEnabled:
    """Tests for GitHub integration enabled check."""
    
    def test_github_enabled_with_token(self):
        """Test that GitHub is enabled when token is set."""
        with patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('app.github_integration.is_github_enabled', return_value=True):
            assert is_github_enabled() is True
    
    def test_github_disabled_without_token(self):
        """Test that GitHub is disabled when token is not set."""
        with patch('app.github_integration.GITHUB_TOKEN', None):
            assert not is_github_enabled()


class TestCreateGitHubIssue:
    """Tests for GitHub issue creation."""
    
    @pytest.mark.asyncio
    async def test_create_issue_without_token(self):
        """Test that issue creation fails gracefully without token."""
        with patch('app.github_integration.is_github_enabled', return_value=False):
            success, url, error = await create_github_issue(
                feedback_id=1,
                feedback_type="bug_report",
                category="UI/UX",
                comment="Test bug"
            )
            
            assert not success
            assert url is None
            assert error == "GitHub integration not configured"
    
    @pytest.mark.asyncio
    async def test_create_bug_report_issue(self):
        """Test creating a bug report issue."""
        mock_response = Mock()
        mock_response.status_code = 201
        mock_response.json.return_value = {
            "html_url": "https://github.com/test/repo/issues/123",
            "number": 123
        }
        
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('httpx.AsyncClient') as mock_client:
            
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.post = AsyncMock(return_value=mock_response)
            
            success, url, error = await create_github_issue(
                feedback_id=1,
                feedback_type="bug_report",
                category="UI/UX",
                comment="Test bug report",
                rating=3,
                page_url="https://example.com/page"
            )
            
            assert success
            assert url == "https://github.com/test/repo/issues/123"
            assert error is None
            
            # Verify the API was called correctly
            assert mock_client_instance.post.called
            call_args = mock_client_instance.post.call_args
            
            # Check URL
            assert "/issues" in str(call_args[0][0])
            
            # Check payload
            payload = call_args[1]['json']
            assert "🐛 Bug" in payload['title']
            assert "bug" in payload['labels']
            assert "feedback" in payload['labels']
    
    @pytest.mark.asyncio
    async def test_create_feature_request_issue(self):
        """Test creating a feature request issue."""
        mock_response = Mock()
        mock_response.status_code = 201
        mock_response.json.return_value = {
            "html_url": "https://github.com/test/repo/issues/124",
            "number": 124
        }
        
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('httpx.AsyncClient') as mock_client:
            
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.post = AsyncMock(return_value=mock_response)
            
            success, url, error = await create_github_issue(
                feedback_id=2,
                feedback_type="feature_request",
                category="Features",
                comment="Add new feature",
                rating=5
            )
            
            assert success
            assert url == "https://github.com/test/repo/issues/124"
            
            # Verify payload
            call_args = mock_client_instance.post.call_args
            payload = call_args[1]['json']
            assert "✨ Feature Request" in payload['title']
            assert "enhancement" in payload['labels']
    
    @pytest.mark.asyncio
    async def test_create_issue_with_screenshot(self):
        """Test creating an issue with screenshot note."""
        mock_response = Mock()
        mock_response.status_code = 201
        mock_response.json.return_value = {
            "html_url": "https://github.com/test/repo/issues/125",
            "number": 125
        }
        
        mock_comment_response = Mock()
        mock_comment_response.status_code = 201
        
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('httpx.AsyncClient') as mock_client:
            
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.post = AsyncMock(
                side_effect=[mock_response, mock_comment_response]
            )
            
            success, url, error = await create_github_issue(
                feedback_id=3,
                feedback_type="bug_report",
                category="UI/UX",
                comment="Bug with screenshot",
                screenshot_data="base64encodeddata"
            )
            
            assert success
            # Should have been called twice (issue + comment)
            assert mock_client_instance.post.call_count == 2
    
    @pytest.mark.asyncio
    async def test_create_issue_api_error(self):
        """Test handling API errors when creating issue."""
        mock_response = Mock()
        mock_response.status_code = 500
        mock_response.text = "Internal Server Error"
        
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('httpx.AsyncClient') as mock_client:
            
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.post = AsyncMock(return_value=mock_response)
            
            success, url, error = await create_github_issue(
                feedback_id=4,
                feedback_type="feedback",
                category="Other",
                comment="Test"
            )
            
            assert not success
            assert url is None
            assert "Failed to create GitHub issue" in error


class TestUpdateIssueStatus:
    """Tests for GitHub issue status updates."""
    
    @pytest.mark.asyncio
    async def test_update_status_without_token(self):
        """Test that status update fails gracefully without token."""
        with patch('app.github_integration.is_github_enabled', return_value=False):
            success, error = await update_issue_status(
                issue_url="https://github.com/test/repo/issues/1",
                new_status="resolved",
                feedback_id=1
            )
            
            assert not success
            assert error == "GitHub integration not configured"
    
    @pytest.mark.asyncio
    async def test_update_status_to_resolved(self):
        """Test updating issue status to resolved."""
        mock_patch_response = Mock()
        mock_patch_response.status_code = 200
        
        mock_post_response = Mock()
        mock_post_response.status_code = 201
        
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('httpx.AsyncClient') as mock_client:
            
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.patch = AsyncMock(return_value=mock_patch_response)
            mock_client_instance.post = AsyncMock(return_value=mock_post_response)
            
            success, error = await update_issue_status(
                issue_url="https://github.com/test/repo/issues/123",
                new_status="resolved",
                feedback_id=1
            )
            
            assert success
            assert error is None
            
            # Verify the patch call
            patch_call = mock_client_instance.patch.call_args
            assert "/issues/123" in str(patch_call[0][0])
            assert patch_call[1]['json']['state'] == 'closed'
    
    @pytest.mark.asyncio
    async def test_update_status_to_dismissed(self):
        """Test updating issue status to dismissed."""
        mock_patch_response = Mock()
        mock_patch_response.status_code = 200
        
        mock_post_response = Mock()
        mock_post_response.status_code = 201
        
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'), \
             patch('httpx.AsyncClient') as mock_client:
            
            mock_client_instance = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_client_instance
            mock_client_instance.patch = AsyncMock(return_value=mock_patch_response)
            mock_client_instance.post = AsyncMock(return_value=mock_post_response)
            
            success, error = await update_issue_status(
                issue_url="https://github.com/test/repo/issues/124",
                new_status="dismissed",
                feedback_id=2
            )
            
            assert success
            
            # Verify state is closed
            patch_call = mock_client_instance.patch.call_args
            assert patch_call[1]['json']['state'] == 'closed'
    
    @pytest.mark.asyncio
    async def test_update_status_invalid_url(self):
        """Test handling invalid issue URL."""
        with patch('app.github_integration.is_github_enabled', return_value=True), \
             patch('app.github_integration.GITHUB_TOKEN', 'test-token'):
            
            success, error = await update_issue_status(
                issue_url="https://github.com/invalid",
                new_status="resolved",
                feedback_id=1
            )
            
            assert not success
            assert "Invalid issue URL" in error


class TestAttachScreenshot:
    """Tests for screenshot attachment."""
    
    @pytest.mark.asyncio
    async def test_attach_screenshot_comment(self):
        """Test attaching screenshot as comment."""
        mock_client = AsyncMock()
        mock_response = Mock()
        mock_response.status_code = 201
        mock_client.post = AsyncMock(return_value=mock_response)
        
        headers = {"Authorization": "Bearer test-token"}
        
        success = await _attach_screenshot_to_issue(
            client=mock_client,
            headers=headers,
            issue_number=123,
            screenshot_data="base64data",
            feedback_id=1
        )
        
        assert success
        
        # Verify comment was posted
        call_args = mock_client.post.call_args
        assert "/issues/123/comments" in str(call_args[0][0])
        assert "Screenshot" in call_args[1]['json']['body']
    
    @pytest.mark.asyncio
    async def test_attach_screenshot_error(self):
        """Test handling error when attaching screenshot."""
        mock_client = AsyncMock()
        mock_response = Mock()
        mock_response.status_code = 500
        mock_client.post = AsyncMock(return_value=mock_response)
        
        headers = {"Authorization": "Bearer test-token"}
        
        success = await _attach_screenshot_to_issue(
            client=mock_client,
            headers=headers,
            issue_number=123,
            screenshot_data="base64data",
            feedback_id=1
        )
        
        assert not success
