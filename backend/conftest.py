"""
=============================================================================
DiaCare API - Test Configuration
=============================================================================
Pytest configuration for Django REST API tests.
=============================================================================
"""

import pytest
from django.conf import settings


@pytest.fixture(scope='session')
def django_db_setup():
    """Setup test database."""
    settings.DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
        # Django expects this key to exist when wrapping views with atomic requests.
        'ATOMIC_REQUESTS': False,
    }


@pytest.fixture
def api_client():
    """Return API client for making requests."""
    from rest_framework.test import APIClient
    return APIClient()


@pytest.fixture
def create_user(db):
    """Factory fixture for creating test users."""
    from apps.users.models import User, DiabeticProfile, UserPreferences
    
    def _create_user(
        email='test@example.com',
        password='testpass123',
        full_name='Test User',
        **kwargs
    ):
        user = User.objects.create_user(
            email=email,
            password=password,
            full_name=full_name,
            **kwargs
        )
        # Create associated profiles
        DiabeticProfile.objects.create(user=user)
        UserPreferences.objects.create(user=user)
        return user
    
    return _create_user


@pytest.fixture
def authenticated_client(api_client, create_user):
    """Return an authenticated API client."""
    from rest_framework_simplejwt.tokens import RefreshToken
    
    user = create_user()
    refresh = RefreshToken.for_user(user)
    api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    api_client.user = user
    return api_client


@pytest.fixture
def sample_glucose_reading(db, create_user):
    """Create a sample glucose reading."""
    from apps.health.models import GlucoseReading
    from django.utils import timezone
    
    user = create_user(email='glucose@test.com')
    reading = GlucoseReading.objects.create(
        user=user,
        value=120.0,
        unit='mg/dL',
        reading_type='before_meal',
        recorded_at=timezone.now()
    )
    return reading


@pytest.fixture
def sample_reminder(db, create_user):
    """Create a sample reminder."""
    from apps.reminders.models import Reminder
    from datetime import time
    
    user = create_user(email='reminder@test.com')
    reminder = Reminder.objects.create(
        user=user,
        title='Take medication',
        reminder_type='medication',
        scheduled_time=time(8, 0),
        is_enabled=True
    )
    return reminder
