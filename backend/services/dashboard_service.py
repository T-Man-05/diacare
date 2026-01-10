"""Dashboard Service - Aggregates data for dashboard screen (BFF Pattern)"""

from typing import Dict, Any, List
from datetime import datetime, timedelta
from django.utils import timezone
from repositories.glucose_repository import GlucoseRepository
from repositories.health_card_repository import HealthCardRepository
from repositories.reminder_repository import ReminderRepository
from apps.users.models import User, DiabeticProfile


class DashboardService:
    """
    BFF Service for Dashboard Screen
    
    This service aggregates all data needed for the dashboard in ONE API call.
    This is the "Backend for Frontend" pattern - one endpoint per screen.
    """
    
    @staticmethod
    def get_dashboard_data(user_id: int) -> Dict[str, Any]:
        """
        Get all dashboard data in one call
        
        Returns complete dashboard payload with:
        - User info
        - Latest glucose reading
        - Glucose trend (7 days)
        - Health cards (water, pills, activity)
        - Today's reminders
        - Quick stats
        """
        
        # Get user and diabetic profile
        user = User.objects.select_related('diabetic_profile').get(id=user_id)
        diabetic_profile = user.diabetic_profile
        
        # 1. Latest Glucose Reading
        latest_reading = GlucoseRepository.get_today_readings(user_id).first()
        latest_glucose = None
        if latest_reading:
            status = DashboardService._get_glucose_status(
                float(latest_reading.value),
                diabetic_profile.min_glucose,
                diabetic_profile.max_glucose
            )
            latest_glucose = {
                'value': float(latest_reading.value),
                'unit': latest_reading.unit,
                'status': status,
                'reading_type': latest_reading.reading_type,
                'recorded_at': latest_reading.recorded_at.isoformat(),
            }
        
        # 2. Glucose Trend (last 7 days)
        trend_data = DashboardService._get_glucose_trend(user_id, days=7)
        
        # 3. Statistics
        stats = GlucoseRepository.get_statistics(user_id, days=7)
        glucose_stats = {
            'average': round(float(stats['average']), 1) if stats['average'] else 0.0,
            'min': float(stats['min']) if stats['min'] else 0.0,
            'max': float(stats['max']) if stats['max'] else 0.0,
            'readings_count': stats['count']
        }
        
        # 4. Range Analysis
        range_analysis = GlucoseRepository.get_range_analysis(
            user_id,
            diabetic_profile.min_glucose,
            diabetic_profile.max_glucose,
            days=7
        )
        
        # 5. Health Cards (today)
        health_cards = DashboardService._get_health_cards(user_id)
        
        # 6. Next Reminder (single closest upcoming reminder)
        next_reminder = DashboardService._get_next_reminder(user_id)
        reminders = [next_reminder] if next_reminder else []

        # Count late reminders (time already passed but not completed)
        late_reminders_count = ReminderRepository.count_late_reminders(user_id)
        
        # 7. Streaks & Goals (placeholder for future)
        goals = {
            'daily_readings_target': 4,
            'readings_today': GlucoseRepository.get_today_readings(user_id).count(),
            'water_target': 8,
            'water_consumed': health_cards.get('water', {}).get('value', 0)
        }
        
        return {
            'user': {
                'id': user.id,
                'full_name': user.full_name,
                'email': user.email,
                'profile_image_url': user.profile_image_url,
            },
            'glucose': {
                'latest': latest_glucose,
                'trend': trend_data,
                'stats': glucose_stats,
                'range_analysis': range_analysis,
                'target_range': {
                    'min': diabetic_profile.min_glucose,
                    'max': diabetic_profile.max_glucose
                }
            },
            'health_cards': health_cards,
            # Backward compatible: still expose `reminders` but it now contains
            # at most ONE item (the closest upcoming reminder).
            'reminders': reminders,
            # Preferred field for clients that only need the closest reminder.
            'next_reminder': next_reminder,
            'late_reminders_count': late_reminders_count,
            'goals': goals,
            'timestamp': timezone.now().isoformat()
        }
    
    @staticmethod
    def _get_glucose_status(value: float, min_range: int, max_range: int) -> str:
        """Determine glucose status based on range"""
        if value < min_range:
            return "low"
        elif value > max_range:
            return "high"
        else:
            return "normal"
    
    @staticmethod
    def _get_glucose_trend(user_id: int, days: int = 7) -> List[Dict[str, Any]]:
        """Get glucose readings trend for charting"""
        readings = GlucoseRepository.get_user_readings(user_id, days)
        
        trend_data = []
        for reading in readings:
            trend_data.append({
                'id': str(reading.id),
                'value': float(reading.value),
                'recorded_at': reading.recorded_at.isoformat(),
                'reading_type': reading.reading_type
            })
        
        return trend_data
    
    @staticmethod
    def _get_health_cards(user_id: int) -> Dict[str, Dict[str, Any]]:
        """Get today's health tracking cards"""
        cards = HealthCardRepository.get_today_cards(user_id)
        
        result = {}
        for card in cards:
            result[card.card_type] = {
                'value': float(card.value),
                'unit': card.unit,
                'recorded_date': card.recorded_date.isoformat()
            }
        
        # Ensure all common cards exist (with 0 values if not tracked yet)
        for card_type in ['water', 'pills', 'activity', 'weight']:
            if card_type not in result:
                card = HealthCardRepository.get_or_create_card(user_id, card_type)
                result[card_type] = {
                    'value': float(card.value),
                    'unit': card.unit,
                    'recorded_date': card.recorded_date.isoformat()
                }
        
        return result
    
    @staticmethod
    def _get_next_reminder(user_id: int) -> Dict[str, Any] | None:
        """Get the single closest upcoming reminder (or None)."""
        reminder = ReminderRepository.get_next_upcoming_reminder(user_id)
        if not reminder:
            return None

        return {
            'id': str(reminder.id),
            'title': reminder.title,
            'scheduled_time': reminder.scheduled_time.isoformat(),
            'reminder_type': reminder.reminder_type,
            'status': reminder.status,
            'is_enabled': reminder.is_enabled,
        }
