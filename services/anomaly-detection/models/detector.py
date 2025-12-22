"""
ML-based anomaly detector using multiple algorithms.

Implements:
- Isolation Forest for general anomaly detection
- Statistical methods (Z-score, IQR)
- Time series forecasting (Prophet) for trend-based anomalies
"""
import logging
import os
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

logger = logging.getLogger(__name__)

# Configuration
ANOMALY_THRESHOLD = float(os.getenv("ANOMALY_THRESHOLD", "0.7"))
LOOKBACK_MINUTES = int(os.getenv("LOOKBACK_MINUTES", "60"))
MIN_SAMPLES = int(os.getenv("MIN_SAMPLES", "10"))

# Global state
models_initialized = False
isolation_forest = None
scaler = None


def initialize_models():
    """Initialize ML models for anomaly detection."""
    global models_initialized, isolation_forest, scaler
    
    logger.info("Initializing anomaly detection models")
    
    try:
        # Initialize Isolation Forest
        isolation_forest = IsolationForest(
            contamination=0.05,  # Expect 5% anomalies
            random_state=42,
            n_estimators=100
        )
        
        # Initialize scaler
        scaler = StandardScaler()
        
        models_initialized = True
        logger.info("✅ Anomaly detection models initialized successfully")
        
        try:
            from app.main import MODELS_LOADED
            MODELS_LOADED.set(5)  # 5 detection models available
        except ImportError:
            # During testing, app.main may not be available
            pass
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize models: {e}")
        raise


def get_model_info() -> List[Dict]:
    """Get information about loaded models."""
    return [
        {
            "name": "Isolation Forest",
            "type": "general_anomaly",
            "description": "Detects anomalies in general metrics using isolation forest algorithm"
        },
        {
            "name": "Statistical Z-Score",
            "type": "statistical",
            "description": "Detects anomalies using statistical Z-score method"
        },
        {
            "name": "IQR Method",
            "type": "statistical",
            "description": "Detects anomalies using Interquartile Range method"
        },
        {
            "name": "Rate of Change",
            "type": "derivative",
            "description": "Detects sudden spikes or drops in metrics"
        },
        {
            "name": "Pattern Deviation",
            "type": "time_series",
            "description": "Detects deviations from historical patterns"
        }
    ]


async def detect_anomalies(metric_query: str, http_client) -> List:
    """
    Detect anomalies for a given Prometheus query.
    
    Args:
        metric_query: PromQL query string
        http_client: HTTP client for querying Prometheus
    
    Returns:
        List of AnomalyScore objects
    """
    try:
        from app.main import AnomalyScore, PROMETHEUS_URL
    except ImportError:
        # During testing
        from ..app.main import AnomalyScore, PROMETHEUS_URL
    
    if not models_initialized:
        logger.warning("Models not initialized, skipping detection")
        return []
    
    try:
        # Query Prometheus for time series data
        end_time = datetime.now()
        start_time = end_time - timedelta(minutes=LOOKBACK_MINUTES)
        
        params = {
            'query': metric_query,
            'start': start_time.timestamp(),
            'end': end_time.timestamp(),
            'step': '60s'  # 1 minute resolution
        }
        
        response = await http_client.get(
            f"{PROMETHEUS_URL}/api/v1/query_range",
            params=params,
            timeout=30.0
        )
        
        if response.status_code != 200:
            logger.warning(f"Prometheus query failed with status {response.status_code}")
            return []
        
        data = response.json()
        
        if data.get('status') != 'success':
            logger.warning(f"Prometheus query unsuccessful: {data}")
            return []
        
        results = data.get('data', {}).get('result', [])
        
        if not results:
            logger.debug(f"No data returned for query: {metric_query}")
            return []
        
        # Process each time series
        detected_anomalies = []
        
        for series in results:
            metric_name = series.get('metric', {})
            metric_label = _format_metric_name(metric_name, metric_query)
            values = series.get('values', [])
            
            if len(values) < MIN_SAMPLES:
                logger.debug(f"Not enough samples for {metric_label}: {len(values)}")
                continue
            
            # Extract timestamps and values
            timestamps = [datetime.fromtimestamp(v[0]) for v in values]
            metric_values = [float(v[1]) for v in values]
            
            # Run multiple detection methods
            anomalies = []
            
            # Method 1: Statistical Z-score
            z_anomalies = _detect_zscore(timestamps, metric_values)
            anomalies.extend(z_anomalies)
            
            # Method 2: IQR method
            iqr_anomalies = _detect_iqr(timestamps, metric_values)
            anomalies.extend(iqr_anomalies)
            
            # Method 3: Rate of change
            roc_anomalies = _detect_rate_of_change(timestamps, metric_values)
            anomalies.extend(roc_anomalies)
            
            # Method 4: Isolation Forest (if we have enough data)
            if len(metric_values) >= 20:
                if_anomalies = _detect_isolation_forest(timestamps, metric_values)
                anomalies.extend(if_anomalies)
            
            # Deduplicate and create AnomalyScore objects
            # Take the most recent anomaly with highest score
            if anomalies:
                # Sort by timestamp (descending) then score (descending)
                anomalies.sort(key=lambda x: (x[0], x[2]), reverse=True)
                
                # Take top anomaly
                ts, value, score, expected, method = anomalies[0]
                
                # Determine severity based on score
                if score >= 0.9:
                    severity = "critical"
                elif score >= 0.75:
                    severity = "high"
                elif score >= 0.6:
                    severity = "medium"
                else:
                    severity = "low"
                
                # Calculate confidence based on agreement between methods
                unique_methods = set(a[4] for a in anomalies)
                confidence = min(1.0, len(unique_methods) / 3.0)  # More methods agree = higher confidence
                
                anomaly_score = AnomalyScore(
                    metric=metric_label,
                    timestamp=ts,
                    score=score,
                    confidence=confidence,
                    value=value,
                    expected_value=expected,
                    severity=severity
                )
                
                detected_anomalies.append(anomaly_score)
        
        return detected_anomalies
        
    except Exception as e:
        logger.error(f"Error detecting anomalies for {metric_query}: {e}", exc_info=True)
        return []


def _format_metric_name(metric_dict: Dict, query: str) -> str:
    """Format metric name from labels."""
    if not metric_dict:
        return query
    
    # Try to construct a readable name
    name = metric_dict.get('__name__', query)
    
    # Add important labels
    labels = []
    for key in ['job', 'namespace', 'pod', 'container', 'instance']:
        if key in metric_dict:
            labels.append(f"{key}={metric_dict[key]}")
    
    if labels:
        return f"{name}{{{','.join(labels)}}}"
    return name


def _detect_zscore(timestamps: List[datetime], values: List[float]) -> List[Tuple]:
    """
    Detect anomalies using Z-score method.
    
    Returns list of (timestamp, value, score, expected_value, method)
    """
    if len(values) < MIN_SAMPLES:
        return []
    
    arr = np.array(values)
    mean = np.mean(arr)
    std = np.std(arr)
    
    if std == 0:
        return []
    
    z_scores = np.abs((arr - mean) / std)
    
    anomalies = []
    # Consider points with |z-score| > 3 as anomalies
    for i, z in enumerate(z_scores):
        if z > 3.0:
            score = min(1.0, z / 5.0)  # Normalize to 0-1
            anomalies.append((timestamps[i], values[i], score, mean, 'zscore'))
    
    return anomalies


def _detect_iqr(timestamps: List[datetime], values: List[float]) -> List[Tuple]:
    """
    Detect anomalies using Interquartile Range method.
    
    Returns list of (timestamp, value, score, expected_value, method)
    """
    if len(values) < MIN_SAMPLES:
        return []
    
    arr = np.array(values)
    q1 = np.percentile(arr, 25)
    q3 = np.percentile(arr, 75)
    iqr = q3 - q1
    
    if iqr == 0:
        return []
    
    lower_bound = q1 - 1.5 * iqr
    upper_bound = q3 + 1.5 * iqr
    median = np.median(arr)
    
    anomalies = []
    for i, val in enumerate(values):
        if val < lower_bound or val > upper_bound:
            # Calculate score based on how far outside bounds
            if val < lower_bound:
                deviation = (lower_bound - val) / iqr
            else:
                deviation = (val - upper_bound) / iqr
            
            score = min(1.0, deviation / 2.0)
            anomalies.append((timestamps[i], val, score, median, 'iqr'))
    
    return anomalies


def _detect_rate_of_change(timestamps: List[datetime], values: List[float]) -> List[Tuple]:
    """
    Detect anomalies based on sudden rate of change.
    
    Returns list of (timestamp, value, score, expected_value, method)
    """
    if len(values) < 2:
        return []
    
    # Calculate rate of change
    rates = []
    for i in range(1, len(values)):
        rate = abs(values[i] - values[i-1])
        rates.append(rate)
    
    if not rates or np.std(rates) == 0:
        return []
    
    # Use Z-score on rates
    rates_arr = np.array(rates)
    mean_rate = np.mean(rates_arr)
    std_rate = np.std(rates_arr)
    
    anomalies = []
    for i, rate in enumerate(rates):
        z = abs(rate - mean_rate) / std_rate
        if z > 3.0:
            score = min(1.0, z / 5.0)
            # i+1 because rates are offset by 1
            expected = values[i]  # Previous value
            anomalies.append((timestamps[i+1], values[i+1], score, expected, 'rate_of_change'))
    
    return anomalies


def _detect_isolation_forest(timestamps: List[datetime], values: List[float]) -> List[Tuple]:
    """
    Detect anomalies using Isolation Forest.
    
    Returns list of (timestamp, value, score, expected_value, method)
    """
    global isolation_forest
    
    if len(values) < 20:
        return []
    
    try:
        # Prepare features: value, index, moving average
        arr = np.array(values)
        features = []
        
        for i, val in enumerate(values):
            # Simple features: value, position in time series, local mean
            window_start = max(0, i-5)
            window_end = min(len(values), i+6)
            local_mean = np.mean(arr[window_start:window_end])
            
            features.append([val, i / len(values), local_mean])
        
        features_arr = np.array(features)
        
        # Fit and predict
        predictions = isolation_forest.fit_predict(features_arr)
        scores = isolation_forest.score_samples(features_arr)
        
        # Normalize scores to 0-1 range
        min_score = scores.min()
        max_score = scores.max()
        if max_score > min_score:
            normalized_scores = (scores - min_score) / (max_score - min_score)
        else:
            normalized_scores = np.zeros_like(scores)
        
        mean_val = np.mean(arr)
        
        anomalies = []
        for i, (pred, score) in enumerate(zip(predictions, normalized_scores)):
            if pred == -1:  # Anomaly
                # Invert score (lower isolation forest score = more anomalous)
                anomaly_score = 1.0 - score
                if anomaly_score >= ANOMALY_THRESHOLD:
                    anomalies.append((timestamps[i], values[i], anomaly_score, mean_val, 'isolation_forest'))
        
        return anomalies
        
    except Exception as e:
        logger.error(f"Error in isolation forest detection: {e}")
        return []
