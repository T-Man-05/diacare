"""
=============================================================================
API Endpoint Tests
=============================================================================
Integration tests for REST API endpoints.
=============================================================================
"""

import pytest
from django.urls import reverse


@pytest.mark.django_db
class TestAuthenticationAPI:
    """Tests for authentication endpoints."""

    def test_register_user(self, api_client):
        """Test user registration."""
        data = {
            'email': 'newuser@test.com',
            'full_name': 'New User',
            'password': 'securepass123',
            'password_confirm': 'securepass123'
        }
        
        response = api_client.post('/api/v1/auth/register/', data, format='json')
        
        assert response.status_code == 201
        assert 'user' in response.data
        assert 'tokens' in response.data
        assert response.data['user']['email'] == 'newuser@test.com'

    def test_register_password_mismatch(self, api_client):
        """Test registration with mismatched passwords."""
        data = {
            'email': 'mismatch@test.com',
            'full_name': 'Test User',
            'password': 'password123',
            'password_confirm': 'different123'
        }
        
        response = api_client.post('/api/v1/auth/register/', data, format='json')
        
        assert response.status_code == 400

    def test_login_success(self, api_client, create_user):
        """Test successful login."""
        user = create_user(email='login@test.com', password='testpass123')
        
        data = {
            'email': 'login@test.com',
            'password': 'testpass123'
        }
        
        response = api_client.post('/api/v1/auth/token/', data, format='json')
        
        assert response.status_code == 200
        assert 'access' in response.data
        assert 'refresh' in response.data

    def test_login_wrong_password(self, api_client, create_user):
        """Test login with wrong password."""
        create_user(email='wrongpass@test.com', password='correctpass')
        
        data = {
            'email': 'wrongpass@test.com',
            'password': 'wrongpassword'
        }
        
        response = api_client.post('/api/v1/auth/token/', data, format='json')
        
        assert response.status_code == 401

    def test_get_profile_authenticated(self, authenticated_client):
        """Test getting profile when authenticated."""
        response = authenticated_client.get('/api/v1/auth/profile/')
        
        assert response.status_code == 200
        assert 'email' in response.data

    def test_get_profile_unauthenticated(self, api_client):
        """Test getting profile without authentication."""
        response = api_client.get('/api/v1/auth/profile/')
        
        assert response.status_code == 401


@pytest.mark.django_db
class TestDashboardAPI:
    """Tests for dashboard endpoint."""

    def test_get_dashboard(self, authenticated_client):
        """Test getting dashboard data."""
        response = authenticated_client.get('/api/v1/health/dashboard/')
        
        assert response.status_code == 200
        assert 'user' in response.data
        assert 'glucose' in response.data
        assert 'health_cards' in response.data

    def test_dashboard_unauthenticated(self, api_client):
        """Test dashboard without authentication."""
        response = api_client.get('/api/v1/health/dashboard/')
        
        assert response.status_code == 401


@pytest.mark.django_db
class TestGlucoseAPI:
    """Tests for glucose endpoints."""

    def test_list_glucose_readings(self, authenticated_client):
        """Test listing glucose readings."""
        response = authenticated_client.get('/api/v1/health/glucose/')
        
        assert response.status_code == 200
        assert 'results' in response.data or isinstance(response.data, list)

    def test_create_glucose_reading(self, authenticated_client):
        """Test creating a glucose reading."""
        from django.utils import timezone
        
        data = {
            'value': 120,
            'unit': 'mg/dL',
            'reading_type': 'before_meal',
            'recorded_at': timezone.now().isoformat()
        }
        
        response = authenticated_client.post('/api/v1/health/glucose/', data, format='json')
        
        assert response.status_code == 201
        assert response.data['value'] == '120.00'

    def test_get_glucose_statistics(self, authenticated_client):
        """Test getting glucose statistics."""
        response = authenticated_client.get('/api/v1/health/glucose/statistics/')
        
        assert response.status_code == 200
        assert 'average' in response.data or response.data.get('count') == 0

    def test_get_glucose_range_analysis(self, authenticated_client):
        """Test getting glucose range analysis."""
        response = authenticated_client.get('/api/v1/health/glucose/range_analysis/')
        
        assert response.status_code == 200
        assert 'in_range' in response.data


@pytest.mark.django_db
class TestHealthCardsAPI:
    """Tests for health cards endpoints."""

    def test_list_health_cards(self, authenticated_client):
        """Test listing health cards."""
        response = authenticated_client.get('/api/v1/health/cards/')
        
        assert response.status_code == 200

    def test_increment_health_card(self, authenticated_client):
        """Test incrementing health card value."""
        data = {
            'card_type': 'water',
            'increment': 1
        }
        
        response = authenticated_client.post('/api/v1/health/cards/increment/', data, format='json')
        
        assert response.status_code == 200


@pytest.mark.django_db
class TestRemindersAPI:
    """Tests for reminders endpoints."""

    def test_list_reminders(self, authenticated_client):
        """Test listing reminders."""
        response = authenticated_client.get('/api/v1/reminders/')
        
        assert response.status_code == 200

    def test_create_reminder(self, authenticated_client):
        """Test creating a reminder."""
        data = {
            'title': 'Take medication',
            'reminder_type': 'medication',
            'scheduled_time': '08:00:00'
        }
        
        response = authenticated_client.post('/api/v1/reminders/', data, format='json')
        
        assert response.status_code == 201
        assert response.data['title'] == 'Take medication'


@pytest.mark.django_db
class TestChatAPI:
    """Tests for chat endpoints."""

    def test_chat_requires_message(self, authenticated_client):
        """Test chat endpoint requires message."""
        response = authenticated_client.post('/api/v1/chat/send/', {}, format='json')
        
        assert response.status_code == 400
        assert 'message' in str(response.data).lower()

    def test_get_chat_history(self, authenticated_client):
        """Test getting chat history."""
        response = authenticated_client.get('/api/v1/chat/history/')
        
        assert response.status_code == 200
        assert 'data' in response.data
