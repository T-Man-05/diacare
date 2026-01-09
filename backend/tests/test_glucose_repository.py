"""
=============================================================================
Glucose Repository Tests
=============================================================================
Unit tests for the glucose reading repository.
=============================================================================
"""

import pytest
from datetime import timedelta
from django.utils import timezone
from decimal import Decimal

from repositories.glucose_repository import GlucoseRepository
from apps.health.models import GlucoseReading


@pytest.mark.django_db
class TestGlucoseRepository:
    """Tests for GlucoseRepository."""

    def test_create_reading(self, create_user):
        """Test creating a glucose reading."""
        user = create_user(email='create@test.com')
        
        reading = GlucoseRepository.create_reading(
            user_id=user.id,
            value=115.5,
            reading_type='before_meal',
            notes='Test reading'
        )
        
        assert reading is not None
        assert reading.user_id == user.id
        assert float(reading.value) == 115.5
        assert reading.reading_type == 'before_meal'
        assert reading.notes == 'Test reading'

    def test_get_user_readings(self, create_user):
        """Test fetching user readings."""
        user = create_user(email='readings@test.com')
        
        # Create multiple readings
        for i in range(5):
            GlucoseRepository.create_reading(
                user_id=user.id,
                value=100 + i * 10,
                reading_type='random'
            )
        
        readings = GlucoseRepository.get_user_readings(user.id, days=7)
        
        assert readings.count() == 5

    def test_get_today_readings(self, create_user):
        """Test fetching today's readings only."""
        user = create_user(email='today@test.com')
        
        # Create today's reading
        GlucoseRepository.create_reading(
            user_id=user.id,
            value=120,
            reading_type='before_meal'
        )
        
        # Create yesterday's reading
        yesterday = timezone.now() - timedelta(days=1)
        GlucoseReading.objects.create(
            user_id=user.id,
            value=130,
            reading_type='before_meal',
            recorded_at=yesterday
        )
        
        today_readings = GlucoseRepository.get_today_readings(user.id)
        
        assert today_readings.count() == 1

    def test_get_statistics(self, create_user):
        """Test calculating glucose statistics."""
        user = create_user(email='stats@test.com')
        
        # Create readings with known values
        values = [80, 100, 120, 140, 160]
        for value in values:
            GlucoseRepository.create_reading(
                user_id=user.id,
                value=value,
                reading_type='random'
            )
        
        stats = GlucoseRepository.get_statistics(user.id, days=7)
        
        assert stats['count'] == 5
        assert stats['min'] == Decimal('80.00')
        assert stats['max'] == Decimal('160.00')
        assert float(stats['average']) == pytest.approx(120.0)

    def test_get_range_analysis(self, create_user):
        """Test glucose range analysis."""
        user = create_user(email='range@test.com')
        
        # Create readings: 2 below, 3 in range, 2 above
        values = [60, 65, 80, 100, 120, 200, 220]
        for value in values:
            GlucoseRepository.create_reading(
                user_id=user.id,
                value=value,
                reading_type='random'
            )
        
        analysis = GlucoseRepository.get_range_analysis(
            user_id=user.id,
            min_range=70,
            max_range=180,
            days=7
        )
        
        assert analysis['total'] == 7
        assert analysis['below_range'] == 2
        assert analysis['in_range'] == 3
        assert analysis['above_range'] == 2
        assert analysis['in_range_percentage'] == pytest.approx(42.9, abs=0.1)

    def test_get_reading_by_id(self, create_user):
        """Test fetching reading by ID."""
        user = create_user(email='byid@test.com')
        
        reading = GlucoseRepository.create_reading(
            user_id=user.id,
            value=110,
            reading_type='fasting'
        )
        
        fetched = GlucoseRepository.get_reading_by_id(str(reading.id))
        
        assert fetched is not None
        assert fetched.id == reading.id

    def test_get_reading_by_id_not_found(self):
        """Test fetching non-existent reading."""
        import uuid
        result = GlucoseRepository.get_reading_by_id(str(uuid.uuid4()))
        assert result is None

    def test_delete_reading(self, create_user):
        """Test deleting a reading."""
        user = create_user(email='delete@test.com')
        
        reading = GlucoseRepository.create_reading(
            user_id=user.id,
            value=100,
            reading_type='random'
        )
        
        result = GlucoseRepository.delete_reading(str(reading.id))
        
        assert result is True
        assert GlucoseRepository.get_reading_by_id(str(reading.id)) is None
