"""
Insights API View
=================
Provides health insights and analytics for the user.
"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from repositories.glucose_repository import GlucoseRepository
from repositories.health_card_repository import HealthCardRepository
from datetime import timedelta
from django.utils import timezone


class InsightsView(APIView):
    """
    GET /api/v1/health/insights/
    
    Returns health insights including:
    - Glucose trends and patterns
    - Health card completion rates
    - Weekly/monthly statistics
    - Recommendations
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            user = request.user
            glucose_repo = GlucoseRepository()
            
            # Get diabetic profile
            profile = user.diabetic_profile if hasattr(user, 'diabetic_profile') else None
            min_glucose = profile.min_glucose if profile else 70
            max_glucose = profile.max_glucose if profile else 180
            
            # Glucose insights (last 30 days)
            stats_30 = glucose_repo.get_statistics(user.id, 30)
            stats_7 = glucose_repo.get_statistics(user.id, 7)
            range_30 = glucose_repo.get_range_analysis(user.id, min_glucose, max_glucose, 30)
            range_7 = glucose_repo.get_range_analysis(user.id, min_glucose, max_glucose, 7)
            
            # Get all readings for pattern analysis
            readings_30 = glucose_repo.get_readings_last_n_days(user.id, 30)
            
            # Analyze patterns
            morning_readings = [r for r in readings_30 if 6 <= r.recorded_at.hour <= 10]
            evening_readings = [r for r in readings_30 if 18 <= r.recorded_at.hour <= 22]
            
            morning_avg = sum(float(r.value) for r in morning_readings) / len(morning_readings) if morning_readings else 0
            evening_avg = sum(float(r.value) for r in evening_readings) / len(evening_readings) if evening_readings else 0
            
            # Generate recommendations
            recommendations = []
            if range_7['below_range_percent'] > 10:
                recommendations.append({
                    'type': 'warning',
                    'title': 'Low glucose detected',
                    'message': f"{range_7['below_range_percent']}% of your readings were below target. Consider discussing this with your doctor."
                })
            elif range_7['above_range_percent'] > 20:
                recommendations.append({
                    'type': 'warning',
                    'title': 'High glucose detected',
                    'message': f"{range_7['above_range_percent']}% of your readings were above target. Review your diet and medication."
                })
            else:
                recommendations.append({
                    'type': 'success',
                    'title': 'Great control!',
                    'message': f"{range_7['in_range_percent']}% of your readings are in target range."
                })
            
            # Trend analysis
            if stats_7['average'] and stats_30['average']:
                trend = 'improving' if stats_7['average'] < stats_30['average'] else 'worsening' if stats_7['average'] > stats_30['average'] else 'stable'
            else:
                trend = 'insufficient_data'
            
            insights_data = {
                'glucose': {
                    'last_7_days': {
                        'average': round(float(stats_7['average']), 1) if stats_7['average'] else 0,
                        'min': int(stats_7['min']) if stats_7['min'] else 0,
                        'max': int(stats_7['max']) if stats_7['max'] else 0,
                        'count': stats_7['count'],
                        'in_range_percent': range_7['in_range_percent'],
                        'below_range_percent': range_7['below_range_percent'],
                        'above_range_percent': range_7['above_range_percent']
                    },
                    'last_30_days': {
                        'average': round(float(stats_30['average']), 1) if stats_30['average'] else 0,
                        'min': int(stats_30['min']) if stats_30['min'] else 0,
                        'max': int(stats_30['max']) if stats_30['max'] else 0,
                        'count': stats_30['count'],
                        'in_range_percent': range_30['in_range_percent'],
                        'below_range_percent': range_30['below_range_percent'],
                        'above_range_percent': range_30['above_range_percent']
                    },
                    'patterns': {
                        'morning_average': round(morning_avg, 1),
                        'evening_average': round(evening_avg, 1),
                        'morning_readings_count': len(morning_readings),
                        'evening_readings_count': len(evening_readings)
                    },
                    'trend': trend
                },
                'recommendations': recommendations,
                'target_range': {
                    'min': min_glucose,
                    'max': max_glucose
                }
            }
            
            return Response({'success': True, 'data': insights_data})
            
        except Exception as e:
            return Response({
                'success': False,
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
