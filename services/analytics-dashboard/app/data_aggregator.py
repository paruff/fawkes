"""Data aggregation from multiple analytics sources"""
import os
import asyncio
from typing import Dict, List, Optional
from datetime import datetime, timedelta
import httpx

from .models import (
    UsageTrends,
    FeatureAdoption,
    FeatureUsage,
    ExperimentResults,
    UserSegments,
    UserSegment,
    FunnelData,
    FunnelStep,
    DashboardData,
    TimeSeriesDataPoint,
    VariantMetrics
)
from .metrics import MetricsCollector


class DataAggregator:
    """Aggregate data from multiple sources for analytics dashboard"""
    
    def __init__(self, metrics_collector: MetricsCollector):
        self.metrics_collector = metrics_collector
        self.refresh_interval = int(os.getenv('REFRESH_INTERVAL', '300'))  # 5 minutes default
        self.refresh_task = None
        
        # Service endpoints
        self.plausible_url = os.getenv('PLAUSIBLE_URL', 'http://plausible.fawkes.svc:8000')
        self.experimentation_url = os.getenv('EXPERIMENTATION_URL', 'http://experimentation.fawkes.svc:8000')
        self.feedback_url = os.getenv('FEEDBACK_URL', 'http://feedback-service.fawkes.svc:8000')
        
        # Cache for data
        self._cache = {}
        self._cache_timestamp = {}
    
    async def start_background_refresh(self):
        """Start background task to refresh metrics"""
        self.refresh_task = asyncio.create_task(self._background_refresh())
    
    async def stop_background_refresh(self):
        """Stop background refresh task"""
        if self.refresh_task:
            self.refresh_task.cancel()
            try:
                await self.refresh_task
            except asyncio.CancelledError:
                pass
    
    async def _background_refresh(self):
        """Background task to refresh metrics periodically"""
        while True:
            try:
                await self.refresh_all_metrics()
                await asyncio.sleep(self.refresh_interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"Error in background refresh: {e}")
                await asyncio.sleep(60)  # Wait 1 minute before retry
    
    async def refresh_all_metrics(self):
        """Refresh all metrics from sources"""
        with self.metrics_collector.data_refresh_duration.time():
            # Refresh cache for common time ranges
            for time_range in ['1h', '24h', '7d', '30d']:
                try:
                    await self.get_dashboard_data(time_range)
                except Exception as e:
                    print(f"Error refreshing {time_range} data: {e}")
    
    def _parse_time_range(self, time_range: str) -> timedelta:
        """Parse time range string to timedelta"""
        mapping = {
            '1h': timedelta(hours=1),
            '6h': timedelta(hours=6),
            '24h': timedelta(hours=24),
            '7d': timedelta(days=7),
            '30d': timedelta(days=30),
            '90d': timedelta(days=90)
        }
        return mapping.get(time_range, timedelta(days=7))
    
    async def _fetch_plausible_data(self, time_range: str) -> Dict:
        """Fetch data from Plausible analytics"""
        # Simulate Plausible API calls
        # In production, this would call actual Plausible API
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # These are placeholder calls - adjust based on actual Plausible API
                response = await client.get(
                    f"{self.plausible_url}/api/v1/stats/aggregate",
                    params={"period": time_range}
                )
                if response.status_code == 200:
                    return response.json()
        except Exception as e:
            print(f"Error fetching Plausible data: {e}")
        
        # Return mock data for development
        return {
            'visitors': 1250,
            'pageviews': 8450,
            'bounce_rate': 42.5,
            'visit_duration': 185,
            'top_pages': {
                '/': 2100,
                '/catalog': 1800,
                '/create': 950,
                '/docs': 850,
                '/templates': 720
            },
            'sources': {
                'Direct': 650,
                'GitHub': 350,
                'Internal': 250
            }
        }
    
    async def _fetch_experiment_data(self, status: Optional[str] = None) -> List[Dict]:
        """Fetch experiment results from experimentation service"""
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                url = f"{self.experimentation_url}/api/v1/experiments"
                if status:
                    url += f"?status={status}"
                response = await client.get(url)
                if response.status_code == 200:
                    return response.json()
        except Exception as e:
            print(f"Error fetching experiment data: {e}")
        
        # Return mock data for development
        return [
            {
                'experiment_id': 'exp-001',
                'name': 'New Onboarding Flow',
                'status': 'running',
                'start_date': '2024-12-01T00:00:00Z',
                'variants': [
                    {
                        'variant_id': 'control',
                        'name': 'Control',
                        'assignments': 500,
                        'conversions': 125,
                        'conversion_rate': 0.25,
                        'confidence_interval_low': 0.21,
                        'confidence_interval_high': 0.29
                    },
                    {
                        'variant_id': 'variant-a',
                        'name': 'Variant A',
                        'assignments': 500,
                        'conversions': 175,
                        'conversion_rate': 0.35,
                        'confidence_interval_low': 0.31,
                        'confidence_interval_high': 0.39
                    }
                ],
                'p_value': 0.003,
                'is_significant': True,
                'winner': 'variant-a',
                'recommendation': 'Deploy Variant A - shows 40% improvement in conversions'
            }
        ]
    
    async def get_usage_trends(self, time_range: str) -> UsageTrends:
        """Get usage trends from Plausible"""
        cache_key = f"usage_trends_{time_range}"
        if cache_key in self._cache and \
           datetime.utcnow() - self._cache_timestamp.get(cache_key, datetime.min) < timedelta(minutes=5):
            return self._cache[cache_key]
        
        plausible_data = await self._fetch_plausible_data(time_range)
        
        # Generate time series data (mock for now)
        delta = self._parse_time_range(time_range)
        now = datetime.utcnow()
        time_series = []
        for i in range(20):
            ts = now - delta + (delta / 20) * i
            time_series.append(TimeSeriesDataPoint(
                timestamp=ts,
                value=plausible_data['visitors'] * (0.8 + 0.4 * (i / 20))
            ))
        
        usage_trends = UsageTrends(
            total_users=plausible_data.get('visitors', 0),
            active_users=int(plausible_data.get('visitors', 0) * 0.65),
            page_views=plausible_data.get('pageviews', 0),
            unique_visitors=plausible_data.get('visitors', 0),
            avg_session_duration=plausible_data.get('visit_duration', 0),
            bounce_rate=plausible_data.get('bounce_rate', 0),
            users_over_time=time_series,
            pageviews_over_time=time_series,
            top_pages=plausible_data.get('top_pages', {}),
            traffic_sources=plausible_data.get('sources', {})
        )
        
        # Update metrics
        self.metrics_collector.update_usage_metrics({
            'total_users': usage_trends.total_users,
            'active_users': usage_trends.active_users,
            'page_views': usage_trends.page_views,
            'unique_visitors': usage_trends.unique_visitors,
            'avg_session_duration': usage_trends.avg_session_duration,
            'bounce_rate': usage_trends.bounce_rate
        })
        
        self._cache[cache_key] = usage_trends
        self._cache_timestamp[cache_key] = datetime.utcnow()
        return usage_trends
    
    async def get_feature_adoption(self, time_range: str) -> FeatureAdoption:
        """Get feature adoption metrics"""
        # Mock feature data - in production, aggregate from events
        features = [
            FeatureUsage(
                feature_name='Deploy Application',
                total_uses=850,
                unique_users=245,
                adoption_rate=65.0,
                trend='up'
            ),
            FeatureUsage(
                feature_name='Create Service',
                total_uses=620,
                unique_users=198,
                adoption_rate=52.0,
                trend='up'
            ),
            FeatureUsage(
                feature_name='View Documentation',
                total_uses=1200,
                unique_users=312,
                adoption_rate=82.0,
                trend='stable'
            ),
            FeatureUsage(
                feature_name='Run Pipeline',
                total_uses=1450,
                unique_users=267,
                adoption_rate=70.0,
                trend='up'
            ),
            FeatureUsage(
                feature_name='Configure Monitoring',
                total_uses=340,
                unique_users=125,
                adoption_rate=33.0,
                trend='down'
            )
        ]
        
        # Update metrics
        self.metrics_collector.update_feature_metrics([
            {
                'feature_name': f.feature_name,
                'adoption_rate': f.adoption_rate,
                'unique_users': f.unique_users
            } for f in features
        ])
        
        # Generate adoption trend
        delta = self._parse_time_range(time_range)
        now = datetime.utcnow()
        adoption_trend = []
        for i in range(15):
            ts = now - delta + (delta / 15) * i
            adoption_trend.append(TimeSeriesDataPoint(
                timestamp=ts,
                value=45 + 20 * (i / 15)  # Growing adoption
            ))
        
        return FeatureAdoption(
            total_features=len(features),
            features=features,
            most_adopted='View Documentation',
            least_adopted='Configure Monitoring',
            adoption_trend=adoption_trend
        )
    
    async def get_experiment_results(self, status: Optional[str] = None) -> List[ExperimentResults]:
        """Get experiment results with statistical analysis"""
        exp_data = await self._fetch_experiment_data(status)
        
        results = []
        for exp in exp_data:
            variants = [
                VariantMetrics(**v) for v in exp.get('variants', [])
            ]
            
            result = ExperimentResults(
                experiment_id=exp['experiment_id'],
                experiment_name=exp['name'],
                status=exp['status'],
                start_date=datetime.fromisoformat(exp['start_date'].replace('Z', '+00:00')) if exp.get('start_date') else None,
                end_date=datetime.fromisoformat(exp['end_date'].replace('Z', '+00:00')) if exp.get('end_date') else None,
                variants=variants,
                winner=exp.get('winner'),
                p_value=exp.get('p_value'),
                is_significant=exp.get('is_significant', False),
                recommendation=exp.get('recommendation', 'Continue monitoring')
            )
            results.append(result)
        
        # Update metrics
        self.metrics_collector.update_experiment_metrics([
            {
                'experiment_id': r.experiment_id,
                'status': r.status,
                'variants': [
                    {
                        'variant_id': v.variant_id,
                        'conversions': v.conversions,
                        'conversion_rate': v.conversion_rate
                    } for v in r.variants
                ]
            } for r in results
        ])
        
        return results
    
    async def get_user_segments(self, time_range: str) -> UserSegments:
        """Get user segment analysis"""
        # Mock segment data
        segments = [
            UserSegment(
                segment_name='Power Users',
                user_count=85,
                percentage=22.5,
                avg_engagement=8.7,
                characteristics={'sessions_per_week': '>10', 'features_used': '>5'}
            ),
            UserSegment(
                segment_name='Regular Users',
                user_count=198,
                percentage=52.5,
                avg_engagement=6.2,
                characteristics={'sessions_per_week': '3-10', 'features_used': '2-5'}
            ),
            UserSegment(
                segment_name='New Users',
                user_count=67,
                percentage=17.7,
                avg_engagement=3.1,
                characteristics={'sessions_per_week': '<3', 'features_used': '<2'}
            ),
            UserSegment(
                segment_name='At Risk',
                user_count=27,
                percentage=7.3,
                avg_engagement=1.4,
                characteristics={'last_seen': '>14 days', 'declining_usage': True}
            )
        ]
        
        # Update metrics
        self.metrics_collector.update_segment_metrics([
            {
                'segment_name': s.segment_name,
                'user_count': s.user_count,
                'avg_engagement': s.avg_engagement
            } for s in segments
        ])
        
        return UserSegments(
            total_users=sum(s.user_count for s in segments),
            segments=segments,
            segmentation_method='behavioral',
            last_updated=datetime.utcnow()
        )
    
    async def get_funnel_data(self, funnel_name: str, time_range: str) -> FunnelData:
        """Get funnel visualization data"""
        # Define standard funnels
        funnels = {
            'onboarding': {
                'description': 'New user onboarding flow',
                'steps': [
                    FunnelStep(
                        step_name='Sign Up',
                        step_number=1,
                        users_entered=500,
                        users_completed=450,
                        completion_rate=90.0,
                        drop_off_rate=10.0,
                        avg_time_to_next_step=120
                    ),
                    FunnelStep(
                        step_name='Profile Setup',
                        step_number=2,
                        users_entered=450,
                        users_completed=380,
                        completion_rate=84.4,
                        drop_off_rate=15.6,
                        avg_time_to_next_step=180
                    ),
                    FunnelStep(
                        step_name='First Template',
                        step_number=3,
                        users_entered=380,
                        users_completed=285,
                        completion_rate=75.0,
                        drop_off_rate=25.0,
                        avg_time_to_next_step=300
                    ),
                    FunnelStep(
                        step_name='First Deployment',
                        step_number=4,
                        users_entered=285,
                        users_completed=215,
                        completion_rate=75.4,
                        drop_off_rate=24.6,
                        avg_time_to_next_step=600
                    )
                ]
            },
            'deployment': {
                'description': 'Application deployment workflow',
                'steps': [
                    FunnelStep(
                        step_name='Start Deployment',
                        step_number=1,
                        users_entered=850,
                        users_completed=820,
                        completion_rate=96.5,
                        drop_off_rate=3.5,
                        avg_time_to_next_step=30
                    ),
                    FunnelStep(
                        step_name='Configure Settings',
                        step_number=2,
                        users_entered=820,
                        users_completed=785,
                        completion_rate=95.7,
                        drop_off_rate=4.3,
                        avg_time_to_next_step=120
                    ),
                    FunnelStep(
                        step_name='Build Complete',
                        step_number=3,
                        users_entered=785,
                        users_completed=755,
                        completion_rate=96.2,
                        drop_off_rate=3.8,
                        avg_time_to_next_step=240
                    ),
                    FunnelStep(
                        step_name='Deploy Success',
                        step_number=4,
                        users_entered=755,
                        users_completed=730,
                        completion_rate=96.7,
                        drop_off_rate=3.3,
                        avg_time_to_next_step=180
                    )
                ]
            },
            'service_creation': {
                'description': 'New service creation workflow',
                'steps': [
                    FunnelStep(
                        step_name='Select Template',
                        step_number=1,
                        users_entered=620,
                        users_completed=595,
                        completion_rate=96.0,
                        drop_off_rate=4.0,
                        avg_time_to_next_step=45
                    ),
                    FunnelStep(
                        step_name='Configure Service',
                        step_number=2,
                        users_entered=595,
                        users_completed=540,
                        completion_rate=90.8,
                        drop_off_rate=9.2,
                        avg_time_to_next_step=240
                    ),
                    FunnelStep(
                        step_name='Review & Create',
                        step_number=3,
                        users_entered=540,
                        users_completed=510,
                        completion_rate=94.4,
                        drop_off_rate=5.6,
                        avg_time_to_next_step=60
                    ),
                    FunnelStep(
                        step_name='Service Active',
                        step_number=4,
                        users_entered=510,
                        users_completed=485,
                        completion_rate=95.1,
                        drop_off_rate=4.9,
                        avg_time_to_next_step=300
                    )
                ]
            }
        }
        
        if funnel_name not in funnels:
            raise ValueError(f"Unknown funnel: {funnel_name}")
        
        funnel_config = funnels[funnel_name]
        steps = funnel_config['steps']
        
        overall_conversion = (steps[-1].users_completed / steps[0].users_entered) * 100 if steps else 0
        avg_time = sum(s.avg_time_to_next_step or 0 for s in steps) if steps else None
        
        funnel = FunnelData(
            funnel_name=funnel_name,
            description=funnel_config['description'],
            steps=steps,
            overall_conversion_rate=overall_conversion,
            total_users=steps[0].users_entered if steps else 0,
            completed_users=steps[-1].users_completed if steps else 0,
            avg_completion_time=avg_time
        )
        
        # Update metrics
        self.metrics_collector.update_funnel_metrics({
            funnel_name: {
                'overall_conversion_rate': funnel.overall_conversion_rate,
                'steps': [
                    {
                        'step_name': s.step_name,
                        'completion_rate': s.completion_rate,
                        'drop_off_rate': s.drop_off_rate
                    } for s in funnel.steps
                ]
            }
        })
        
        return funnel
    
    async def get_dashboard_data(self, time_range: str) -> DashboardData:
        """Get complete dashboard data"""
        cache_key = f"dashboard_{time_range}"
        if cache_key in self._cache and \
           datetime.utcnow() - self._cache_timestamp.get(cache_key, datetime.min) < timedelta(minutes=5):
            return self._cache[cache_key]
        
        # Fetch all data concurrently
        usage_trends, feature_adoption, experiments, user_segments = await asyncio.gather(
            self.get_usage_trends(time_range),
            self.get_feature_adoption(time_range),
            self.get_experiment_results(),
            self.get_user_segments(time_range)
        )
        
        # Get key funnels
        funnels = {}
        for funnel_name in ['onboarding', 'deployment', 'service_creation']:
            funnels[funnel_name] = await self.get_funnel_data(funnel_name, time_range)
        
        dashboard = DashboardData(
            time_range=time_range,
            usage_trends=usage_trends,
            feature_adoption=feature_adoption,
            experiments=experiments,
            user_segments=user_segments,
            funnels=funnels
        )
        
        self._cache[cache_key] = dashboard
        self._cache_timestamp[cache_key] = datetime.utcnow()
        return dashboard
    
    async def export_data(self, format: str, time_range: str) -> Dict:
        """Export dashboard data in specified format"""
        data = await self.get_dashboard_data(time_range)
        
        if format == 'json':
            return data.model_dump()
        elif format == 'csv':
            # For CSV, return a simplified version
            return {
                'message': 'CSV export not yet implemented',
                'data': data.model_dump()
            }
        
        return {}
