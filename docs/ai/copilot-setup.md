# GitHub Copilot Setup Guide

## Overview

GitHub Copilot is an AI-powered coding assistant that helps developers write code faster and with fewer errors. This guide covers setup, configuration, and integration with Fawkes' internal RAG (Retrieval Augmented Generation) system.

## Prerequisites

- GitHub account with Copilot access
- Appropriate IDE (VSCode, IntelliJ IDEA, or Vim/Neovim)
- Organization admin access (for org-level setup)

## Organization Setup

### 1. Enable GitHub Copilot for Organization

**For Organization Admins:**

1. Navigate to your organization settings: `https://github.com/organizations/[YOUR-ORG]/settings/copilot`
2. Click **"Enable GitHub Copilot"**
3. Configure access policies:
   - **Allowed for**: Select teams or all organization members
   - **Public code matching**: Enable/disable suggestions matching public code
   - **Block suggestions**: Configure to block suggestions matching public code (recommended for security)

4. Review and configure policies:
   ```
   Settings → Copilot → Policies
   - Enable/Disable for all members
   - Allow/Block public code suggestions
   - Configure content exclusions (optional)
   ```

5. Set up billing:
   - Navigate to **Billing and Plans**
   - Add payment method
   - Confirm Copilot subscription for users

### 2. Configure User Access and Permissions

**Access Levels:**

- **Full Access**: All features including code completion and chat
- **Limited Access**: Code completion only
- **No Access**: Copilot disabled

**Grant Access:**

1. Go to Organization Settings → Copilot → Access
2. Add users or teams
3. Set permission level
4. Save changes

**Team-based Access (Recommended):**

```bash
# Example: Grant access to development team
Settings → Copilot → Access → Add teams
Select: @org/developers
Permission: Full Access
```

## IDE Setup

### VSCode Setup

**Installation:**

1. Open VSCode
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "GitHub Copilot"
4. Install both:
   - **GitHub Copilot** (code completion)
   - **GitHub Copilot Chat** (conversational AI)

**Configuration:**

1. Sign in to GitHub:
   - Click **Accounts** icon (bottom left)
   - Select **Sign in with GitHub**
   - Authorize VSCode

2. Configure settings (`settings.json`):

```json
{
  // Enable Copilot
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "markdown": true,
    "terraform": true
  },
  
  // Copilot behavior
  "github.copilot.editor.enableAutoCompletions": true,
  "github.copilot.editor.enableCodeActions": true,
  
  // Advanced settings
  "github.copilot.advanced": {
    "debug.overrideEngine": "",
    "debug.overrideProxyUrl": "",
    "length": 500  // Max suggestion length
  }
}
```

**Keyboard Shortcuts:**

- **Accept suggestion**: `Tab`
- **Dismiss suggestion**: `Esc`
- **Next suggestion**: `Alt+]` / `Option+]`
- **Previous suggestion**: `Alt+[` / `Option+[`
- **Open Copilot Chat**: `Ctrl+Shift+I` / `Cmd+Shift+I`

### IntelliJ IDEA Setup

**Installation:**

1. Open IntelliJ IDEA
2. Go to **Settings/Preferences** → **Plugins**
3. Search for "GitHub Copilot"
4. Click **Install**
5. Restart IDE

**Configuration:**

1. Authenticate:
   - **Settings** → **Tools** → **GitHub Copilot**
   - Click **Sign in to GitHub**
   - Complete OAuth flow

2. Configure settings:
   - **Enable GitHub Copilot**: ✓
   - **Show completions automatically**: ✓
   - **Enable for languages**: Select all relevant languages

**Keyboard Shortcuts:**

- **Accept suggestion**: `Tab`
- **Dismiss suggestion**: `Esc`
- **Show all suggestions**: `Alt+\` (Windows/Linux), `Option+\` (Mac)
- **Next suggestion**: `Alt+]`
- **Previous suggestion**: `Alt+[`

### Vim/Neovim Setup

**Prerequisites:**

- Vim 8.0+ or Neovim 0.6+
- Node.js 18+

**Installation (vim-plug):**

Add to `.vimrc` or `init.vim`:

```vim
" GitHub Copilot
Plug 'github/copilot.vim'
```

Then run:
```vim
:PlugInstall
```

**Authentication:**

```vim
:Copilot setup
```

**Configuration:**

Add to `.vimrc`:

```vim
" Enable Copilot
let g:copilot_enabled = 1

" Filetypes to enable
let g:copilot_filetypes = {
    \ 'yaml': v:true,
    \ 'markdown': v:true,
    \ 'terraform': v:true,
    \ '*': v:true,
    \ }

" Disable for specific files
let g:copilot_filetypes = {
    \ 'gitcommit': v:false,
    \ 'gitrebase': v:false,
    \ }
```

**Keyboard Shortcuts:**

- **Accept suggestion**: `<Tab>` (in insert mode)
- **Dismiss**: `<Esc>`
- **Next suggestion**: `<M-]>` or `Alt-]`
- **Previous suggestion**: `<M-[>` or `Alt-[`
- **Disable Copilot**: `:Copilot disable`
- **Enable Copilot**: `:Copilot enable`

## Integration with RAG System

### Overview

Fawkes uses a RAG (Retrieval Augmented Generation) system powered by Weaviate vector database to provide context-aware AI assistance. While GitHub Copilot doesn't natively integrate with custom RAG systems, we can enhance its effectiveness using the following approaches:

### Approach 1: Workspace Context (Recommended)

**Strategy**: Keep relevant documentation in workspace

GitHub Copilot uses open files and workspace context for suggestions. To leverage internal documentation:

1. **Open relevant docs** alongside code:
   ```bash
   # Open in split panes
   code docs/architecture.md src/service.py
   ```

2. **Use workspace-relative paths**:
   - Keep docs in same workspace
   - Reference docs in comments
   - Copilot will use open files as context

**Example:**

```python
# See docs/ai/vector-database.md for Weaviate setup
import weaviate

def search_documentation(query: str):
    """Search internal docs using Weaviate.
    
    Based on patterns from docs/ai/vector-database.md
    """
    client = weaviate.Client("http://weaviate.fawkes.svc:80")
    # Copilot will suggest code based on open documentation
```

### Approach 2: Comment-Based Context

**Strategy**: Provide context in comments

Use detailed comments to guide Copilot with internal conventions:

```python
# Fawkes pattern: Use ErrKind wrapper for all public API errors
# See docs/patterns/error-handling.md
def process_request():
    try:
        result = api_call()
    except Exception as e:
        # Copilot learns from this pattern
        raise ErrKind.from_exception(e)
```

### Approach 3: RAG Query Tool (Custom Integration)

**For advanced users**: Create a wrapper tool that queries RAG before prompting:

```bash
#!/bin/bash
# rag-query.sh - Query internal docs before coding

QUERY="$1"

# Query RAG service
curl -X POST http://rag-service.fawkes.svc:8000/api/v1/query \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$QUERY\", \"limit\": 3}" | \
  jq -r '.results[].content' > /tmp/context.txt

# Open context in editor
code /tmp/context.txt

# Now use Copilot with context loaded
echo "Context loaded. Start coding with Copilot."
```

**Usage:**
```bash
# Load context before coding
./rag-query.sh "How to deploy ArgoCD applications"

# Copilot now has context from open file
```

### Approach 4: Custom Copilot Instructions (Future)

GitHub is developing workspace-level instructions for Copilot. When available:

1. Create `.github/copilot-instructions.md`
2. Add Fawkes-specific guidelines
3. Copilot will follow these instructions

**Example `.github/copilot-instructions.md`:**

```markdown
# Fawkes Coding Guidelines for Copilot

## Architecture Principles
- GitOps-first: All config in Git
- Declarative over imperative
- Kubernetes-native patterns

## Conventions
- Use ErrKind for error handling
- Terraform 1.6+ syntax
- Kustomize for K8s overlays
- BDD tests with Gherkin

## Security
- Never commit secrets
- Use External Secrets Operator
- Scan with Trivy
```

## Testing Code Completion

### Test 1: Basic Code Completion

**Python:**

```python
# Type this comment and wait for Copilot suggestion:
# Function to connect to Weaviate and query for documents

# Copilot should suggest something like:
def query_weaviate(query: str, limit: int = 5):
    import weaviate
    client = weaviate.Client("http://weaviate.fawkes.svc:80")
    result = client.query.get("FawkesDocument", ["title", "content"]) \
        .with_near_text({"concepts": [query]}) \
        .with_limit(limit) \
        .do()
    return result
```

**Terraform:**

```hcl
# Type this comment:
# Create an AKS cluster with 3 nodes

# Copilot should suggest:
resource "azurerm_kubernetes_cluster" "main" {
  name                = "fawkes-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "fawkes"
  
  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2_v2"
  }
}
```

### Test 2: Contextual Suggestions

**Create test file:**

```bash
# Create a test service
cat > /tmp/test-copilot.py << 'EOF'
import weaviate

# Query Fawkes documentation about ArgoCD
# Copilot should provide context-aware completion
EOF

# Open in your IDE and test
code /tmp/test-copilot.py
```

### Test 3: Code Generation

Use Copilot Chat to generate complete components:

**VSCode:**

1. Open Copilot Chat (`Ctrl+Shift+I`)
2. Ask: "Generate a FastAPI endpoint that queries Weaviate for Fawkes documentation"
3. Review and accept code

**Expected output:**

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import weaviate

app = FastAPI()
client = weaviate.Client("http://weaviate.fawkes.svc:80")

class Query(BaseModel):
    query: str
    limit: int = 5

@app.post("/api/v1/search")
async def search_docs(query: Query):
    try:
        result = client.query.get(
            "FawkesDocument", 
            ["title", "content", "filepath"]
        ).with_near_text({
            "concepts": [query.query]
        }).with_limit(query.limit).do()
        
        return {"results": result["data"]["Get"]["FawkesDocument"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Best Practices

### 1. Security Best Practices

**✅ DO:**
- Review all Copilot suggestions before accepting
- Scan for hardcoded credentials or secrets
- Use Copilot for boilerplate, verify for security-critical code
- Enable "Block public code suggestions" for sensitive projects

**❌ DON'T:**
- Blindly accept suggestions without review
- Use Copilot-generated code in production without testing
- Share proprietary code patterns publicly
- Disable security scanning tools

### 2. Code Quality Best Practices

**✅ DO:**
- Use descriptive variable and function names (helps Copilot context)
- Write clear comments explaining intent
- Provide examples in comments for complex logic
- Test all generated code
- Refactor suggestions to match team style

**❌ DON'T:**
- Accept verbose or overly complex suggestions
- Skip code review for Copilot-generated code
- Ignore linting warnings on generated code
- Use outdated patterns suggested by Copilot

### 3. Productivity Best Practices

**✅ DO:**
- Learn keyboard shortcuts for faster workflow
- Use Copilot Chat for explaining complex code
- Leverage Copilot for documentation and tests
- Provide context through comments and open files
- Iterate on suggestions (reject and try again)

**❌ DON'T:**
- Rely solely on Copilot without understanding code
- Spend more time fixing suggestions than writing code
- Accept first suggestion without exploring alternatives
- Use Copilot as a substitute for learning

### 4. Privacy and Compliance

**✅ DO:**
- Review organization's Copilot policies
- Opt-in to telemetry collection (helps improve Copilot)
- Report inappropriate or problematic suggestions
- Use content exclusions for sensitive files

**❌ DON'T:**
- Share Copilot suggestions containing sensitive data
- Use Copilot on code with export restrictions
- Ignore licensing concerns for suggested code
- Disable audit logging (if required by org)

## Limitations and Known Issues

### Current Limitations

1. **Context Window**: Limited to open files and immediate workspace
   - **Mitigation**: Keep relevant docs open in workspace

2. **No Custom RAG Integration**: Cannot directly query internal knowledge base
   - **Mitigation**: Use comment-based context or wrapper scripts

3. **Public Code Bias**: May suggest patterns from public repos over internal conventions
   - **Mitigation**: Provide context through comments and examples

4. **Language Support**: Best for popular languages (Python, JavaScript, Go, Java)
   - **Mitigation**: Less common languages may have lower-quality suggestions

5. **Security Awareness**: May suggest insecure patterns
   - **Mitigation**: Always scan with security tools (Trivy, SonarQube)

### Known Issues

**Issue 1: Incomplete Suggestions**

- **Symptom**: Copilot stops mid-suggestion
- **Fix**: Press `Alt+]` for next suggestion or retype comment

**Issue 2: Irrelevant Suggestions**

- **Symptom**: Suggestions don't match intent
- **Fix**: Add more context in comments or variable names

**Issue 3: Copilot Not Working**

- **Symptom**: No suggestions appearing
- **Fixes**:
  ```bash
  # Check authentication
  # VSCode: Cmd+Shift+P → "GitHub Copilot: Sign In"
  
  # Check status
  # VSCode: Look for Copilot icon in status bar
  
  # Restart extension
  # VSCode: Cmd+Shift+P → "Developer: Reload Window"
  ```

**Issue 4: High Latency**

- **Symptom**: Slow suggestion response
- **Fixes**:
  - Check internet connection
  - Reduce file size or complexity
  - Disable temporarily for large files
  - Check GitHub status page

## Usage Telemetry (Opt-in)

Fawkes collects opt-in telemetry to measure AI coding assistant effectiveness:

**Metrics Collected:**

- Copilot acceptance rate (% of suggestions accepted)
- Lines of AI-generated code (daily/weekly)
- Time saved estimates (based on typing speed)
- Most used languages and features

**Privacy:**

- All metrics are aggregated and anonymized
- No code content is collected
- Opt-in only (disabled by default)
- Data retained for 90 days

**Enable Telemetry:**

```bash
# Set environment variable
export FAWKES_AI_TELEMETRY=enabled

# Or in your shell profile
echo 'export FAWKES_AI_TELEMETRY=enabled' >> ~/.bashrc
```

**View Your Metrics:**

```bash
# Access AI telemetry dashboard
# Requires VPN/cluster access
open http://grafana.fawkes.local/d/ai-telemetry
```

See [AI Telemetry Dashboard](../../platform/apps/ai-telemetry/README.md) for details.

## Troubleshooting

### Copilot Not Suggesting

1. **Check authentication**:
   ```bash
   # VSCode
   Cmd+Shift+P → "GitHub Copilot: Check Status"
   
   # CLI
   gh copilot status
   ```

2. **Verify subscription**:
   - Check organization settings
   - Confirm user has access
   - Review billing status

3. **Check file type**:
   - Ensure file extension is supported
   - Check language mode in IDE
   - Try `.py`, `.js`, `.tf` files

4. **Network issues**:
   - Check firewall/proxy settings
   - Verify GitHub API access
   - Test with: `curl https://api.github.com/copilot_internal/v2/token`

### Suggestions Not Relevant

1. **Add more context**:
   ```python
   # Add detailed comment
   # Function to query Weaviate for Fawkes docs
   # Uses semantic search with vector embeddings
   # Returns top 5 results with certainty > 0.7
   def search_fawkes_docs(query: str):
       # Copilot now has better context
   ```

2. **Open reference files**:
   - Open similar existing code
   - Open relevant documentation
   - Keep examples in workspace

3. **Adjust settings**:
   ```json
   {
     "github.copilot.advanced": {
       "length": 1000  // Increase for more complete suggestions
     }
   }
   ```

### Performance Issues

1. **Reduce file size**:
   - Close large files
   - Split complex files
   - Work in smaller modules

2. **Disable for specific files**:
   ```json
   {
     "github.copilot.enable": {
       "log": false,
       "xml": false
     }
   }
   ```

3. **Check system resources**:
   - Close unused applications
   - Increase IDE memory
   - Monitor CPU usage

## Additional Resources

### Documentation

- [GitHub Copilot Official Docs](https://docs.github.com/en/copilot)
- [Copilot for Business](https://docs.github.com/en/copilot/overview-of-github-copilot/about-github-copilot-for-business)
- [VSCode Copilot Extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
- [IntelliJ Copilot Plugin](https://plugins.jetbrains.com/plugin/17718-github-copilot)
- [Vim Copilot](https://github.com/github/copilot.vim)

### Internal Resources

- [Fawkes Architecture](../architecture.md)
- [RAG Service Documentation](../../services/rag/README.md)
- [Vector Database Guide](./vector-database.md)
- [AI Telemetry Dashboard](../../platform/apps/ai-telemetry/README.md)
- [Development Guide](../development.md)

### Training and Support

- [Copilot Best Practices (Internal Wiki)](#)
- [AI Coding Assistant Office Hours](#) - Tuesdays 2-3pm
- [Slack: #ai-coding-help](#) - For questions and support
- [Feedback Form](#) - Report issues or suggestions

## FAQ

### Q: Is my code sent to GitHub/OpenAI?

**A:** Yes, code snippets are sent to GitHub's Copilot service for processing. GitHub states that:
- Copilot for Business: Code snippets are NOT used for model training
- Copilot for Individuals: Code may be used for training (can opt out)
- All transmission is encrypted (HTTPS)

### Q: Can I use Copilot for proprietary/confidential code?

**A:** With Copilot for Business, yes. GitHub provides:
- No training on your code
- No code retention after processing
- SOC 2 Type II compliance
- Enterprise-grade security

Verify your organization's policy before using on sensitive code.

### Q: What if Copilot suggests copyrighted code?

**A:** GitHub provides:
- Copyright filter to block verbatim code from public repos
- Legal protection for Business users (in some plans)
- Attribution for code similar to public sources

Best practice: Review suggestions, add attribution, and run license compliance tools.

### Q: How accurate is Copilot?

**A:** Accuracy varies by:
- Language (better for popular languages like Python, JavaScript)
- Context (better with clear comments and examples)
- Complexity (better for common patterns than novel algorithms)

**Typical acceptance rates:**
- Simple boilerplate: 70-90%
- Business logic: 40-60%
- Complex algorithms: 20-40%

Always review and test suggested code.

### Q: Can I customize Copilot for Fawkes conventions?

**A:** Currently limited, but you can:
- Use detailed comments with conventions
- Keep style guides in workspace
- Open example files for context
- Wait for workspace-level instructions feature (coming soon)

### Q: Does Copilot replace code review?

**A:** No. Code review is still essential:
- Verify logic correctness
- Check security implications
- Ensure style consistency
- Validate test coverage

Treat Copilot as a pair programmer, not a replacement for review.

### Q: How do I report problematic suggestions?

**A:** 
1. In VSCode: Right-click suggestion → "Report Issue"
2. Via GitHub: [GitHub Copilot Feedback](https://github.com/github/feedback/discussions/categories/copilot-feedback)
3. Internal: Post in #ai-coding-help Slack channel

### Q: Can I use Copilot offline?

**A:** No, Copilot requires internet connection to:
- Send code context to GitHub's servers
- Receive AI-generated suggestions
- Authenticate your account

For offline development, Copilot will be unavailable.

## Conclusion

GitHub Copilot is a powerful tool for accelerating development in the Fawkes platform. By following this guide and best practices, you can:

- Set up Copilot across your organization
- Integrate with Fawkes' internal documentation and patterns
- Write code faster with fewer errors
- Maintain security and code quality standards

For questions or support, reach out to the platform team via #ai-coding-help on Slack.

**Happy coding! 🚀**
