"""
Sentiment analysis for feedback comments.

This module provides sentiment analysis using VADER (Valence Aware Dictionary
and sEntiment Reasoner), which is specifically attuned to sentiments expressed
in social media and works well for short texts like feedback comments.

VADER produces:
- Compound score (-1 to +1): normalized, weighted composite score
- Positive, negative, neutral percentages

Sentiment classification:
- Positive: compound score >= 0.05
- Neutral: -0.05 < compound score < 0.05
- Negative: compound score <= -0.05
"""
import logging
from typing import Dict, Optional, Tuple
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

logger = logging.getLogger(__name__)

# Initialize VADER sentiment analyzer
try:
    analyzer = SentimentIntensityAnalyzer()
    logger.info("✅ VADER sentiment analyzer initialized")
except Exception as e:
    logger.error(f"❌ Failed to initialize VADER analyzer: {e}")
    analyzer = None


def analyze_sentiment(text: str) -> Dict[str, float]:
    """
    Analyze sentiment of text using VADER.
    
    Args:
        text: Text to analyze
    
    Returns:
        Dictionary with sentiment scores:
        {
            'compound': -1.0 to +1.0 (normalized weighted composite),
            'pos': 0.0 to 1.0 (positive percentage),
            'neu': 0.0 to 1.0 (neutral percentage),
            'neg': 0.0 to 1.0 (negative percentage)
        }
    """
    if not analyzer:
        logger.warning("VADER analyzer not available, returning neutral sentiment")
        return {
            'compound': 0.0,
            'pos': 0.0,
            'neu': 1.0,
            'neg': 0.0
        }
    
    if not text or not text.strip():
        return {
            'compound': 0.0,
            'pos': 0.0,
            'neu': 1.0,
            'neg': 0.0
        }
    
    try:
        scores = analyzer.polarity_scores(text)
        logger.debug(f"Sentiment analysis: compound={scores['compound']:.3f}")
        return scores
    except Exception as e:
        logger.error(f"Error analyzing sentiment: {e}")
        return {
            'compound': 0.0,
            'pos': 0.0,
            'neu': 1.0,
            'neg': 0.0
        }


def classify_sentiment(compound_score: float) -> str:
    """
    Classify sentiment based on compound score.
    
    Args:
        compound_score: VADER compound score (-1.0 to +1.0)
    
    Returns:
        Sentiment classification: 'positive', 'neutral', or 'negative'
    """
    if compound_score >= 0.05:
        return 'positive'
    elif compound_score <= -0.05:
        return 'negative'
    else:
        return 'neutral'


def analyze_feedback_sentiment(comment: str) -> Tuple[str, float, float, float, float]:
    """
    Analyze feedback comment and return classification with scores.
    
    Args:
        comment: Feedback comment text
    
    Returns:
        Tuple of (sentiment, compound, pos, neu, neg):
        - sentiment: 'positive', 'neutral', or 'negative'
        - compound: compound score (-1.0 to +1.0)
        - pos: positive percentage (0.0 to 1.0)
        - neu: neutral percentage (0.0 to 1.0)
        - neg: negative percentage (0.0 to 1.0)
    """
    scores = analyze_sentiment(comment)
    sentiment = classify_sentiment(scores['compound'])
    
    return (
        sentiment,
        round(scores['compound'], 3),
        round(scores['pos'], 3),
        round(scores['neu'], 3),
        round(scores['neg'], 3)
    )


def get_sentiment_emoji(sentiment: str) -> str:
    """
    Get emoji representation of sentiment.
    
    Args:
        sentiment: 'positive', 'neutral', or 'negative'
    
    Returns:
        Emoji string
    """
    emoji_map = {
        'positive': '😊',
        'neutral': '😐',
        'negative': '😞'
    }
    return emoji_map.get(sentiment, '❓')


def batch_analyze_sentiments(comments: list[str]) -> list[Dict[str, any]]:
    """
    Analyze sentiment for multiple comments.
    
    Args:
        comments: List of comment strings
    
    Returns:
        List of dictionaries with sentiment analysis results
    """
    results = []
    
    for comment in comments:
        sentiment, compound, pos, neu, neg = analyze_feedback_sentiment(comment)
        results.append({
            'comment': comment,
            'sentiment': sentiment,
            'compound': compound,
            'pos': pos,
            'neu': neu,
            'neg': neg,
            'emoji': get_sentiment_emoji(sentiment)
        })
    
    return results


def aggregate_sentiment_stats(sentiments: list[str]) -> Dict[str, any]:
    """
    Calculate aggregate sentiment statistics.
    
    Args:
        sentiments: List of sentiment classifications ('positive', 'neutral', 'negative')
    
    Returns:
        Dictionary with aggregate statistics:
        {
            'total': total count,
            'positive': positive count,
            'neutral': neutral count,
            'negative': negative count,
            'positive_pct': positive percentage,
            'neutral_pct': neutral percentage,
            'negative_pct': negative percentage
        }
    """
    total = len(sentiments)
    
    if total == 0:
        return {
            'total': 0,
            'positive': 0,
            'neutral': 0,
            'negative': 0,
            'positive_pct': 0.0,
            'neutral_pct': 0.0,
            'negative_pct': 0.0
        }
    
    positive = sum(1 for s in sentiments if s == 'positive')
    neutral = sum(1 for s in sentiments if s == 'neutral')
    negative = sum(1 for s in sentiments if s == 'negative')
    
    return {
        'total': total,
        'positive': positive,
        'neutral': neutral,
        'negative': negative,
        'positive_pct': round((positive / total) * 100, 2),
        'neutral_pct': round((neutral / total) * 100, 2),
        'negative_pct': round((negative / total) * 100, 2)
    }
