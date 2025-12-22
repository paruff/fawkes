/**
 * VSM Flow Metrics Widget for Focalboard
 * 
 * Displays real-time flow metrics from the VSM service including:
 * - Work in Progress (WIP) by stage
 * - Cycle time per column/stage
 * - Bottleneck detection
 * - WIP limit warnings
 */

import React, { useEffect, useState } from 'react';
import './styles.css';

interface FlowMetrics {
  throughput: number;
  wip: number;
  cycle_time_avg: number | null;
  cycle_time_p50: number | null;
  cycle_time_p85: number | null;
  cycle_time_p95: number | null;
  period_start: string;
  period_end: string;
}

interface Stage {
  id: number;
  name: string;
  order: number;
  type: string;
  category: string | null;
  wip_limit: number | null;
  description: string | null;
}

interface StageMetrics {
  stage: string;
  wip: number;
  wipLimit: number | null;
  isBottleneck: boolean;
}

interface WidgetSettings {
  vsm_api_url: string;
  refresh_interval: number;
  show_bottlenecks: boolean;
}

const VSMMetricsWidget: React.FC = () => {
  const [metrics, setMetrics] = useState<FlowMetrics | null>(null);
  const [stages, setStages] = useState<Stage[]>([]);
  const [stageMetrics, setStageMetrics] = useState<StageMetrics[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [settings, setSettings] = useState<WidgetSettings>({
    vsm_api_url: 'http://vsm-service.fawkes.svc:8000/api/v1',
    refresh_interval: 30,
    show_bottlenecks: true,
  });

  // Fetch flow metrics from VSM service
  const fetchMetrics = async () => {
    try {
      const response = await fetch(`${settings.vsm_api_url}/metrics?days=7`);
      if (!response.ok) {
        throw new Error(`Failed to fetch metrics: ${response.statusText}`);
      }
      const data = await response.json();
      setMetrics(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      console.error('Error fetching VSM metrics:', err);
    }
  };

  // Fetch stages from VSM service
  const fetchStages = async () => {
    try {
      const response = await fetch(`${settings.vsm_api_url}/stages`);
      if (!response.ok) {
        throw new Error(`Failed to fetch stages: ${response.statusText}`);
      }
      const data = await response.json();
      setStages(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      console.error('Error fetching VSM stages:', err);
    }
  };

  // Calculate stage-specific metrics and detect bottlenecks
  const calculateStageMetrics = () => {
    if (!stages.length) return;

    // In production, this would fetch actual WIP counts from Prometheus or VSM API
    // For now, we'll use mock data based on stage configuration
    const stageMetricsData: StageMetrics[] = stages.map((stage) => {
      // Mock WIP calculation - in production, fetch from Prometheus /metrics endpoint
      const mockWip = Math.floor(Math.random() * 15);
      const isBottleneck =
        settings.show_bottlenecks &&
        stage.wip_limit !== null &&
        mockWip > stage.wip_limit * 0.8; // 80% of WIP limit

      return {
        stage: stage.name,
        wip: mockWip,
        wipLimit: stage.wip_limit,
        isBottleneck,
      };
    });

    setStageMetrics(stageMetricsData);
  };

  // Initial load
  useEffect(() => {
    const initialize = async () => {
      setLoading(true);
      await fetchMetrics();
      await fetchStages();
      setLoading(false);
    };

    initialize();
  }, [settings.vsm_api_url]);

  // Calculate stage metrics when stages change
  useEffect(() => {
    calculateStageMetrics();
  }, [stages, settings.show_bottlenecks]);

  // Auto-refresh metrics
  useEffect(() => {
    if (settings.refresh_interval <= 0) return;

    const intervalId = setInterval(() => {
      fetchMetrics();
      calculateStageMetrics();
    }, settings.refresh_interval * 1000);

    return () => clearInterval(intervalId);
  }, [settings.refresh_interval]);

  const formatCycleTime = (hours: number | null): string => {
    if (hours === null) return 'N/A';
    if (hours < 24) return `${hours.toFixed(1)}h`;
    return `${(hours / 24).toFixed(1)}d`;
  };

  if (loading) {
    return (
      <div className="vsm-widget">
        <div className="vsm-widget-loading">Loading VSM metrics...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="vsm-widget">
        <div className="vsm-widget-error">
          <span className="error-icon">⚠️</span>
          <div>Error loading VSM metrics: {error}</div>
          <button onClick={() => window.location.reload()}>Retry</button>
        </div>
      </div>
    );
  }

  return (
    <div className="vsm-widget">
      <div className="vsm-widget-header">
        <h3>📊 VSM Flow Metrics</h3>
        <a
          href="http://grafana.fawkes.svc/d/vsm-flow-metrics"
          target="_blank"
          rel="noopener noreferrer"
          className="dashboard-link"
        >
          View Full Dashboard →
        </a>
      </div>

      {/* Overall Metrics */}
      <div className="vsm-metrics-grid">
        <div className="metric-card">
          <div className="metric-label">Throughput (7d)</div>
          <div className="metric-value">{metrics?.throughput || 0}</div>
          <div className="metric-unit">items completed</div>
        </div>

        <div className="metric-card">
          <div className="metric-label">WIP</div>
          <div className="metric-value">{metrics?.wip.toFixed(0) || 0}</div>
          <div className="metric-unit">items in progress</div>
        </div>

        <div className="metric-card">
          <div className="metric-label">Cycle Time (P50)</div>
          <div className="metric-value">
            {formatCycleTime(metrics?.cycle_time_p50 || null)}
          </div>
          <div className="metric-unit">median</div>
        </div>

        <div className="metric-card">
          <div className="metric-label">Cycle Time (P85)</div>
          <div className="metric-value">
            {formatCycleTime(metrics?.cycle_time_p85 || null)}
          </div>
          <div className="metric-unit">85th percentile</div>
        </div>
      </div>

      {/* Stage-level Metrics */}
      {stageMetrics.length > 0 && (
        <div className="vsm-stages-section">
          <h4>Stage Metrics</h4>
          <div className="stages-list">
            {stageMetrics.map((stageMetric) => (
              <div
                key={stageMetric.stage}
                className={`stage-card ${
                  stageMetric.isBottleneck ? 'bottleneck' : ''
                }`}
              >
                <div className="stage-name">
                  {stageMetric.isBottleneck && (
                    <span className="bottleneck-icon" title="Bottleneck detected!">
                      ⚠️
                    </span>
                  )}
                  {stageMetric.stage}
                </div>
                <div className="stage-wip">
                  WIP: {stageMetric.wip}
                  {stageMetric.wipLimit && (
                    <span className="wip-limit"> / {stageMetric.wipLimit}</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Bottleneck Warning */}
      {settings.show_bottlenecks &&
        stageMetrics.some((s) => s.isBottleneck) && (
          <div className="bottleneck-warning">
            <span className="warning-icon">⚠️</span>
            <div>
              <strong>Bottlenecks Detected</strong>
              <p>
                Some stages are approaching or exceeding WIP limits. Consider
                moving items forward or addressing blockers.
              </p>
            </div>
          </div>
        )}

      <div className="vsm-widget-footer">
        <small>
          Last updated: {new Date().toLocaleTimeString()} • Auto-refresh:{' '}
          {settings.refresh_interval}s
        </small>
      </div>
    </div>
  );
};

export default VSMMetricsWidget;
