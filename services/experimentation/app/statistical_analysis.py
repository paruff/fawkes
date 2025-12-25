"""Statistical analysis for A/B testing"""
import numpy as np
from scipy import stats
from typing import List, Dict, Any, Optional

from .models import ExperimentStats, VariantStats


class StatisticalAnalyzer:
    """Performs statistical analysis on experiment data"""

    def analyze_experiment(
        self,
        experiment_id: str,
        experiment_name: str,
        status: str,
        variants: List[Dict],
        variant_data: Dict[str, Dict],
        significance_level: float = 0.05
    ) -> ExperimentStats:
        """
        Perform statistical analysis on experiment data

        Args:
            experiment_id: Experiment identifier
            experiment_name: Experiment name
            status: Experiment status
            variants: List of variant configurations
            variant_data: Dictionary of variant data (sample_size, conversions, values)
            significance_level: Statistical significance level (default 0.05)

        Returns:
            ExperimentStats with analysis results
        """
        # Find control variant (first variant by convention)
        control_variant = variants[0]['name']

        # Calculate stats for each variant
        variant_stats = []
        for variant_config in variants:
            variant_name = variant_config['name']
            data = variant_data.get(variant_name, {'sample_size': 0, 'conversions': 0, 'values': []})

            stats_obj = self._calculate_variant_stats(
                variant_name,
                data['sample_size'],
                data['conversions'],
                data['values']
            )
            variant_stats.append(stats_obj)

        # Perform statistical test (control vs each variant)
        control_data = variant_data.get(control_variant, {'sample_size': 0, 'conversions': 0, 'values': []})

        # Find the best performing variant
        winner = None
        min_p_value = 1.0
        significant = False
        effect_size = 0.0

        for variant_config in variants[1:]:  # Skip control
            variant_name = variant_config['name']
            variant_data_obj = variant_data.get(variant_name, {'sample_size': 0, 'conversions': 0, 'values': []})

            # Perform two-proportion z-test
            p_value, effect = self._two_proportion_test(
                control_data['sample_size'],
                control_data['conversions'],
                variant_data_obj['sample_size'],
                variant_data_obj['conversions']
            )

            if p_value < min_p_value:
                min_p_value = p_value

                # Check if significant and better than control
                if p_value < significance_level:
                    significant = True
                    control_rate = control_data['conversions'] / max(control_data['sample_size'], 1)
                    variant_rate = variant_data_obj['conversions'] / max(variant_data_obj['sample_size'], 1)

                    if variant_rate > control_rate:
                        winner = variant_name
                        effect_size = effect

        # Generate recommendation
        recommendation = self._generate_recommendation(
            status,
            significant,
            winner,
            control_variant,
            min_p_value,
            significance_level,
            variant_stats
        )

        # Calculate totals
        total_sample_size = sum(v.sample_size for v in variant_stats)
        total_conversions = sum(v.conversions for v in variant_stats)
        avg_sample_per_variant = total_sample_size // len(variant_stats) if variant_stats else 0

        return ExperimentStats(
            experiment_id=experiment_id,
            experiment_name=experiment_name,
            status=status,
            variants=variant_stats,
            control_variant=control_variant,
            winner=winner,
            statistical_significance=significant,
            p_value=min_p_value,
            confidence_level=1.0 - significance_level,
            effect_size=effect_size,
            recommendation=recommendation,
            sample_size_per_variant=avg_sample_per_variant,
            total_conversions=total_conversions
        )

    def _calculate_variant_stats(
        self,
        variant: str,
        sample_size: int,
        conversions: int,
        values: List[float]
    ) -> VariantStats:
        """Calculate statistics for a single variant"""
        conversion_rate = conversions / sample_size if sample_size > 0 else 0.0

        if values:
            mean_value = np.mean(values)
            std_dev = np.std(values, ddof=1) if len(values) > 1 else 0.0

            # Calculate 95% confidence interval
            if len(values) > 1:
                sem = stats.sem(values)
                ci = stats.t.interval(0.95, len(values)-1, loc=mean_value, scale=sem)
            else:
                ci = (mean_value, mean_value)
        else:
            mean_value = 0.0
            std_dev = 0.0
            ci = (0.0, 0.0)

        return VariantStats(
            variant=variant,
            sample_size=sample_size,
            conversions=conversions,
            conversion_rate=conversion_rate,
            mean_value=mean_value,
            std_dev=std_dev,
            confidence_interval=ci
        )

    def _two_proportion_test(
        self,
        n1: int,
        x1: int,
        n2: int,
        x2: int
    ) -> tuple[float, float]:
        """
        Perform two-proportion z-test

        Args:
            n1: Sample size of group 1 (control)
            x1: Number of successes in group 1
            n2: Sample size of group 2 (variant)
            x2: Number of successes in group 2

        Returns:
            (p_value, effect_size)
        """
        if n1 == 0 or n2 == 0:
            return 1.0, 0.0

        p1 = x1 / n1
        p2 = x2 / n2

        # Pooled proportion
        p_pool = (x1 + x2) / (n1 + n2)

        # Standard error
        se = np.sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))

        if se == 0:
            return 1.0, 0.0

        # Z-statistic
        z = (p2 - p1) / se

        # Two-tailed p-value
        p_value = 2 * (1 - stats.norm.cdf(abs(z)))

        # Effect size (relative difference)
        effect_size = (p2 - p1) / p1 if p1 > 0 else 0.0

        return p_value, effect_size

    def _generate_recommendation(
        self,
        status: str,
        significant: bool,
        winner: Optional[str],
        control: str,
        p_value: float,
        alpha: float,
        variant_stats: List[VariantStats]
    ) -> str:
        """Generate actionable recommendation based on analysis"""
        # Check if we have enough data
        min_sample = min(v.sample_size for v in variant_stats) if variant_stats else 0

        if status != "running" and status != "stopped":
            return f"Experiment is in '{status}' state. Start the experiment to begin collecting data."

        if min_sample < 100:
            return f"Continue running. Need more data (minimum 100 samples per variant, currently {min_sample})."

        if not significant:
            if min_sample < 1000:
                return f"No significant difference yet (p={p_value:.4f}). Continue running to reach target sample size."
            else:
                return f"No significant difference detected (p={p_value:.4f}). Consider stopping and keeping {control}."

        if winner:
            # Calculate effect with safe division
            if len(variant_stats) > 1 and variant_stats[0].conversion_rate > 0:
                effect_pct = variant_stats[1].conversion_rate / variant_stats[0].conversion_rate - 1
                return f"✅ Winner: {winner} shows {effect_pct:.1%} improvement over {control} (p={p_value:.4f}). Recommend rolling out {winner} to 100% traffic."
            else:
                return f"✅ Winner: {winner} detected (p={p_value:.4f}). Recommend rolling out {winner} to 100% traffic."
        else:
            return f"Significant difference found (p={p_value:.4f}) but no clear winner. Review variant performance and consider additional testing."
