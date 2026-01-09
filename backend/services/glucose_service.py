"""
Service Layer - Glucose Business Logic
=======================================
Handles glucose reading business logic including:
- Listing readings with filters
- Adding new readings
- Calculating statistics
- Determining glucose status
"""

from django.utils import timezone
from datetime import timedelta
from repositories.glucose_repository import GlucoseRepository


class GlucoseService:
    """Business logic for glucose operations"""
    
    def __init__(self):
        self.glucose_repo = GlucoseRepository()
    
    def get_glucose_list(self, user, filters=None):
        """
        Get glucose readings list with optional filters
        
        Args:
            user: Django User object
            filters: dict with optional keys: days, start_date, end_date, limit
        
        Returns:
            dict: {
                'readings': list,
                'statistics': dict,
                'count': int
            }
        """
        filters = filters or {}
        days = int(filters.get('days', 30))
        
        # Get readings
        readings = self.glucose_repo.get_readings_last_n_days(user.id, days)
        
        # Calculate statistics
        stats = self.glucose_repo.get_statistics(user.id, days)
        
        # Get range analysis
        min_glucose = user.diabetic_profile.min_glucose if hasattr(user, 'diabetic_profile') else 70
        max_glucose = user.diabetic_profile.max_glucose if hasattr(user, 'diabetic_profile') else 180
        range_analysis = self.glucose_repo.get_range_analysis(user.id, min_glucose, max_glucose, days)
        
        # Format readings
        formatted_readings = [
            self._format_reading(reading, min_glucose, max_glucose)
            for reading in readings
        ]
        
        return {
            'readings': formatted_readings,
            'statistics': {
                'count': stats['count'],
                'average': round(float(stats['average']), 1) if stats['average'] else 0,
                'min': int(stats['min']) if stats['min'] else 0,
                'max': int(stats['max']) if stats['max'] else 0,
                'period_days': days
            },
            'range_analysis': range_analysis,
            'count': stats['count']
        }
    
    def add_glucose_reading(self, user, data):
        """
        Add a new glucose reading
        
        Args:
            user: Django User object
            data: dict with keys: value, unit, reading_type, recorded_at, notes (optional)
        
        Returns:
            dict: formatted reading
        """
        # Validate required fields
        if 'value' not in data:
            raise ValueError("value is required")
        if 'unit' not in data:
            data['unit'] = 'mg/dL'
        if 'reading_type' not in data:
            data['reading_type'] = 'before_meal'
        if 'recorded_at' not in data:
            data['recorded_at'] = timezone.now()
        
        # Convert recorded_at to datetime if string
        if isinstance(data['recorded_at'], str):
            from datetime import datetime
            data['recorded_at'] = datetime.fromisoformat(data['recorded_at'].replace('Z', '+00:00'))
        
        # Create reading
        reading = self.glucose_repo.create_reading(
            user_id=user.id,
            value=data['value'],
            unit=data['unit'],
            reading_type=data['reading_type'],
            recorded_at=data['recorded_at'],
            notes=data.get('notes')
        )
        
        # Format and return
        min_glucose = user.diabetic_profile.min_glucose if hasattr(user, 'diabetic_profile') else 70
        max_glucose = user.diabetic_profile.max_glucose if hasattr(user, 'diabetic_profile') else 180
        
        return self._format_reading(reading, min_glucose, max_glucose)
    
    def get_glucose_stats(self, user, period_days=7):
        """Get glucose statistics for a period"""
        stats = self.glucose_repo.get_statistics(user.id, period_days)
        
        min_glucose = user.diabetic_profile.min_glucose if hasattr(user, 'diabetic_profile') else 70
        max_glucose = user.diabetic_profile.max_glucose if hasattr(user, 'diabetic_profile') else 180
        range_analysis = self.glucose_repo.get_range_analysis(user.id, min_glucose, max_glucose, period_days)
        
        return {
            'statistics': stats,
            'range_analysis': range_analysis,
            'period_days': period_days
        }
    
    def calculate_glucose_status(self, value, min_range, max_range):
        """
        Calculate glucose status and color
        
        Returns:
            dict: {
                'status': 'low' | 'normal' | 'high',
                'status_color': hex color string,
                'status_text': display text
            }
        """
        if value < min_range:
            return {
                'status': 'low',
                'status_color': '#FF0000',
                'status_text': 'Low'
            }
        elif value > max_range:
            return {
                'status': 'high',
                'status_color': '#FF6600',
                'status_text': 'High'
            }
        else:
            return {
                'status': 'normal',
                'status_color': '#00FF00',
                'status_text': 'Normal'
            }
    
    def _format_reading(self, reading, min_glucose, max_glucose):
        """Format a glucose reading for API response"""
        value = float(reading.value)
        status_info = self.calculate_glucose_status(value, min_glucose, max_glucose)
        
        return {
            'id': str(reading.id),
            'value': int(value),
            'unit': reading.unit,
            'reading_type': reading.reading_type,
            'notes': reading.notes or '',
            'recorded_at': reading.recorded_at.isoformat(),
            'created_at': reading.created_at.isoformat(),
            **status_info
        }
