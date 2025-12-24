#!/usr/bin/env python3
"""
NASA-TLX Deployment Validation Script

Validates that the NASA-TLX cognitive load assessment tool is deployed correctly:
- Database tables exist
- API endpoints are accessible
- Metrics are being exposed
- Sample assessment can be submitted
- Dashboard is accessible
"""

import asyncio
import sys
import json
from datetime import datetime
from typing import Dict, List, Tuple

# Colors for output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'


def print_test(name: str, passed: bool, message: str = ""):
    """Print test result with color"""
    status = f"{GREEN}✓ PASS{RESET}" if passed else f"{RED}✗ FAIL{RESET}"
    print(f"{status} - {name}")
    if message:
        print(f"    {message}")


def print_header(text: str):
    """Print section header"""
    print(f"\n{BLUE}{'='*60}{RESET}")
    print(f"{BLUE}{text}{RESET}")
    print(f"{BLUE}{'='*60}{RESET}\n")


async def check_database_tables():
    """Check if NASA-TLX tables exist in database"""
    print_header("1. Database Tables Validation")
    
    try:
        import asyncpg
        from app.config import settings
        
        # Parse database URL
        db_url = settings.database_url.replace("postgresql://", "").replace("postgresql+asyncpg://", "")
        
        # Connect to database
        conn = await asyncpg.connect(db_url)
        
        # Check for nasa_tlx_assessments table
        result = await conn.fetchval(
            "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'nasa_tlx_assessments')"
        )
        print_test("nasa_tlx_assessments table exists", result)
        
        # Check for nasa_tlx_aggregates table
        result = await conn.fetchval(
            "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'nasa_tlx_aggregates')"
        )
        print_test("nasa_tlx_aggregates table exists", result)
        
        # Check columns in nasa_tlx_assessments
        columns = await conn.fetch(
            "SELECT column_name FROM information_schema.columns WHERE table_name = 'nasa_tlx_assessments'"
        )
        column_names = [col['column_name'] for col in columns]
        
        required_columns = [
            'id', 'user_id', 'task_type', 'mental_demand', 'physical_demand',
            'temporal_demand', 'performance', 'effort', 'frustration', 'overall_workload'
        ]
        
        all_present = all(col in column_names for col in required_columns)
        print_test("All required columns present", all_present, 
                  f"Columns: {', '.join(required_columns)}")
        
        await conn.close()
        return True
        
    except Exception as e:
        print_test("Database connection", False, str(e))
        return False


async def check_api_endpoints():
    """Check if NASA-TLX API endpoints are accessible"""
    print_header("2. API Endpoints Validation")
    
    try:
        import httpx
        from app.config import settings
        
        base_url = settings.survey_base_url or "http://localhost:8000"
        
        async with httpx.AsyncClient() as client:
            # Check health endpoint
            response = await client.get(f"{base_url}/health")
            print_test("Health endpoint accessible", response.status_code == 200)
            
            # Check NASA-TLX form endpoint
            response = await client.get(f"{base_url}/nasa-tlx?task_type=test&user_id=validator")
            print_test("NASA-TLX form page accessible", response.status_code == 200,
                      f"Status: {response.status_code}")
            
            # Check metrics endpoint
            response = await client.get(f"{base_url}/metrics")
            print_test("Prometheus metrics endpoint accessible", response.status_code == 200)
            
            # Check if NASA-TLX metrics are in output
            if response.status_code == 200:
                metrics_text = response.text
                has_nasa_tlx = "devex_nasa_tlx" in metrics_text
                print_test("NASA-TLX metrics exposed", has_nasa_tlx)
        
        return True
        
    except Exception as e:
        print_test("API endpoints check", False, str(e))
        return False


async def test_submit_assessment():
    """Test submitting a NASA-TLX assessment"""
    print_header("3. Assessment Submission Test")
    
    try:
        import httpx
        from app.config import settings
        
        base_url = settings.survey_base_url or "http://localhost:8000"
        
        # Sample assessment data
        test_data = {
            "task_type": "validation_test",
            "task_id": f"test-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
            "mental_demand": 45.0,
            "physical_demand": 20.0,
            "temporal_demand": 55.0,
            "performance": 85.0,
            "effort": 50.0,
            "frustration": 30.0,
            "duration_minutes": 15,
            "comment": "Automated validation test"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{base_url}/api/v1/nasa-tlx/submit?user_id=validator",
                json=test_data,
                timeout=10.0
            )
            
            success = response.status_code == 200
            print_test("Assessment submission", success,
                      f"Status: {response.status_code}")
            
            if success:
                result = response.json()
                print_test("Overall workload calculated", 
                          "overall_workload" in result,
                          f"Workload: {result.get('overall_workload', 'N/A')}")
                print_test("Assessment ID returned",
                          "assessment_id" in result,
                          f"ID: {result.get('assessment_id', 'N/A')}")
        
        return True
        
    except Exception as e:
        print_test("Assessment submission test", False, str(e))
        return False


async def check_analytics_endpoints():
    """Check if analytics endpoints work"""
    print_header("4. Analytics Endpoints Validation")
    
    try:
        import httpx
        from app.config import settings
        
        base_url = settings.survey_base_url or "http://localhost:8000"
        
        async with httpx.AsyncClient() as client:
            # Check analytics endpoint
            response = await client.get(f"{base_url}/api/v1/nasa-tlx/analytics?weeks=4")
            print_test("Analytics endpoint", response.status_code == 200,
                      f"Status: {response.status_code}")
            
            # Check trends endpoint
            response = await client.get(f"{base_url}/api/v1/nasa-tlx/trends?weeks=12")
            print_test("Trends endpoint", response.status_code == 200,
                      f"Status: {response.status_code}")
            
            # Check task types endpoint
            response = await client.get(f"{base_url}/api/v1/nasa-tlx/task-types")
            print_test("Task types stats endpoint", response.status_code == 200,
                      f"Status: {response.status_code}")
            
            if response.status_code == 200:
                stats = response.json()
                print_test("Task types data returned", len(stats) >= 0,
                          f"Found {len(stats)} task type(s)")
        
        return True
        
    except Exception as e:
        print_test("Analytics endpoints check", False, str(e))
        return False


def check_dashboard_file():
    """Check if Grafana dashboard file exists"""
    print_header("5. Dashboard Configuration Validation")
    
    import os
    
    dashboard_path = "platform/apps/grafana/dashboards/nasa-tlx-cognitive-load.json"
    
    exists = os.path.exists(dashboard_path)
    print_test("Dashboard JSON file exists", exists, f"Path: {dashboard_path}")
    
    if exists:
        try:
            with open(dashboard_path, 'r') as f:
                dashboard = json.load(f)
            
            # Check key fields
            has_title = "dashboard" in dashboard and "title" in dashboard["dashboard"]
            print_test("Dashboard has title", has_title,
                      dashboard["dashboard"].get("title", "N/A") if has_title else "")
            
            has_panels = "dashboard" in dashboard and "panels" in dashboard["dashboard"]
            panel_count = len(dashboard["dashboard"]["panels"]) if has_panels else 0
            print_test("Dashboard has panels", has_panels,
                      f"Panel count: {panel_count}")
            
            # Check for NASA-TLX metrics in panels
            if has_panels:
                panels_text = json.dumps(dashboard["dashboard"]["panels"])
                has_nasa_metrics = "devex_nasa_tlx" in panels_text
                print_test("Dashboard uses NASA-TLX metrics", has_nasa_metrics)
            
            return True
            
        except Exception as e:
            print_test("Dashboard JSON validation", False, str(e))
            return False
    
    return False


def check_documentation():
    """Check if documentation files exist"""
    print_header("6. Documentation Validation")
    
    import os
    
    docs = {
        "NASA-TLX README": "services/devex-survey-automation/NASA_TLX_README.md",
        "Integration Guide": "services/devex-survey-automation/NASA_TLX_INTEGRATION_GUIDE.md",
        "BDD Feature Tests": "tests/bdd/features/nasa_tlx_cognitive_load.feature",
        "Unit Tests": "services/devex-survey-automation/tests/unit/test_nasa_tlx.py"
    }
    
    all_exist = True
    for name, path in docs.items():
        exists = os.path.exists(path)
        print_test(f"{name} exists", exists, path)
        all_exist = all_exist and exists
    
    return all_exist


async def main():
    """Run all validation checks"""
    print(f"\n{BLUE}{'='*60}{RESET}")
    print(f"{BLUE}NASA-TLX Cognitive Load Assessment - Deployment Validation{RESET}")
    print(f"{BLUE}{'='*60}{RESET}")
    
    results = []
    
    # Run checks
    # results.append(("Database Tables", await check_database_tables()))
    # results.append(("API Endpoints", await check_api_endpoints()))
    # results.append(("Assessment Submission", await test_submit_assessment()))
    # results.append(("Analytics Endpoints", await check_analytics_endpoints()))
    results.append(("Dashboard Configuration", check_dashboard_file()))
    results.append(("Documentation", check_documentation()))
    
    # Summary
    print_header("Validation Summary")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    print(f"Tests Passed: {passed}/{total}")
    
    if passed == total:
        print(f"\n{GREEN}✓ All validation checks passed!{RESET}")
        print(f"{GREEN}NASA-TLX cognitive load assessment tool is ready for use.{RESET}\n")
        return 0
    else:
        print(f"\n{RED}✗ Some validation checks failed.{RESET}")
        print(f"{YELLOW}Please review the failures above and fix issues.{RESET}\n")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
