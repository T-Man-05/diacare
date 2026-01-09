"""Glucose Reading Repository - Data Access Layer"""

from typing import List, Optional
from datetime import datetime, timedelta
from django.db.models import QuerySet, Avg, Min, Max, Count
from django.utils import timezone
from apps.health.models import GlucoseReading


class GlucoseRepository:
    """Handles all database operations for Glucose Readings"""
    
    @staticmethod
    def get_user_readings(user_id: int, days: int = 7) -> QuerySet:
        """
        Get all glucose readings for a user within specified days
        
        Args:
            user_id: User ID
            days: Number of days to look back (default: 7)
        
        Returns:
            QuerySet of GlucoseReading objects
        """
        start_date = timezone.now() - timedelta(days=days)
        return GlucoseReading.objects.filter(
            user_id=user_id,
            recorded_at__gte=start_date
        ).order_by("-recorded_at")
    
    @staticmethod
    def get_today_readings(user_id: int) -> QuerySet:
        """Get today's glucose readings for a user"""
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        return GlucoseReading.objects.filter(
            user_id=user_id,
            recorded_at__gte=today_start
        ).order_by("-recorded_at")
    
    @staticmethod
    def get_statistics(user_id: int, days: int = 7) -> dict:
        """
        Calculate glucose statistics for a user
        
        Returns:
            dict: {
                'average': float,
                'min': float,
                'max': float,
                'count': int
            }
        """
        start_date = timezone.now() - timedelta(days=days)
        stats = GlucoseReading.objects.filter(
            user_id=user_id,
            recorded_at__gte=start_date
        ).aggregate(
            average=Avg("value"),
            min=Min("value"),
            max=Max("value"),
            count=Count("id")
        )
        return stats
    
    @staticmethod
    def create_reading(user_id: int, value: float, reading_type: str, 
                      notes: str = "", recorded_at: Optional[datetime] = None) -> GlucoseReading:
        """
        Create a new glucose reading
        
        Args:
            user_id: User ID
            value: Glucose value
            reading_type: Type of reading (before_meal, after_meal, etc.)
            notes: Optional notes
            recorded_at: When reading was taken (defaults to now)
        
        Returns:
            Created GlucoseReading object
        """
        if recorded_at is None:
            recorded_at = timezone.now()
        
        reading = GlucoseReading.objects.create(
            user_id=user_id,
            value=value,
            reading_type=reading_type,
            notes=notes,
            recorded_at=recorded_at
        )
        return reading
    
    @staticmethod
    def get_reading_by_id(reading_id: str) -> Optional[GlucoseReading]:
        """Get a specific glucose reading by ID"""
        try:
            return GlucoseReading.objects.get(id=reading_id)
        except GlucoseReading.DoesNotExist:
            return None
    
    @staticmethod
    def update_reading(reading_id: str, **kwargs) -> Optional[GlucoseReading]:
        """Update a glucose reading"""
        reading = GlucoseRepository.get_reading_by_id(reading_id)
        if reading:
            for key, value in kwargs.items():
                setattr(reading, key, value)
            reading.save()
        return reading
    
    @staticmethod
    def delete_reading(reading_id: str) -> bool:
        """Delete a glucose reading"""
        reading = GlucoseRepository.get_reading_by_id(reading_id)
        if reading:
            reading.delete()
            return True
        return False
    
    @staticmethod
    def get_range_analysis(user_id: int, min_range: int, max_range: int, days: int = 7) -> dict:
        """
        Analyze readings within, below, and above target range
        
        Returns:
            dict: {
                'in_range': int,
                'below_range': int,
                'above_range': int,
                'total': int,
                'in_range_percentage': float
            }
        """
        start_date = timezone.now() - timedelta(days=days)
        readings = GlucoseReading.objects.filter(
            user_id=user_id,
            recorded_at__gte=start_date
        )
        
        total = readings.count()
        if total == 0:
            return {
                'in_range': 0,
                'below_range': 0,
                'above_range': 0,
                'total': 0,
                'in_range_percentage': 0.0
            }
        
        in_range = readings.filter(value__gte=min_range, value__lte=max_range).count()
        below_range = readings.filter(value__lt=min_range).count()
        above_range = readings.filter(value__gt=max_range).count()
        
        return {
            'in_range': in_range,
            'below_range': below_range,
            'above_range': above_range,
            'total': total,
            'in_range_percentage': round((in_range / total) * 100, 1) if total > 0 else 0.0
        }
