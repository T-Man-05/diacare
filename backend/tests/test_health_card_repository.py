"""
=============================================================================
Health Card Repository Tests
=============================================================================
Unit tests for the health card repository.
=============================================================================
"""

import pytest
from datetime import date

from repositories.health_card_repository import HealthCardRepository
from apps.health.models import HealthCard


@pytest.mark.django_db
class TestHealthCardRepository:
    """Tests for HealthCardRepository."""

    def test_get_or_create_card_creates_new(self, create_user):
        """Test creating a new health card."""
        user = create_user(email='newcard@test.com')
        
        card = HealthCardRepository.get_or_create_card(
            user_id=user.id,
            card_type='water'
        )
        
        assert card is not None
        assert card.card_type == 'water'
        assert card.value == 0
        assert card.unit == 'glasses'

    def test_get_or_create_card_returns_existing(self, create_user):
        """Test returning existing card instead of creating new."""
        user = create_user(email='existing@test.com')
        
        # Create first card
        card1 = HealthCardRepository.get_or_create_card(
            user_id=user.id,
            card_type='water'
        )
        card1.value = 5
        card1.save()
        
        # Get same card
        card2 = HealthCardRepository.get_or_create_card(
            user_id=user.id,
            card_type='water'
        )
        
        assert card1.id == card2.id
        assert card2.value == 5

    def test_update_card_value(self, create_user):
        """Test updating card value."""
        user = create_user(email='update@test.com')
        
        card = HealthCardRepository.update_card_value(
            user_id=user.id,
            card_type='pills',
            value=3
        )
        
        assert card.value == 3

    def test_increment_card_value(self, create_user):
        """Test incrementing card value."""
        user = create_user(email='increment@test.com')
        
        # Initial increment
        card1 = HealthCardRepository.increment_card_value(
            user_id=user.id,
            card_type='water',
            increment=1
        )
        assert card1.value == 1
        
        # Second increment
        card2 = HealthCardRepository.increment_card_value(
            user_id=user.id,
            card_type='water',
            increment=2
        )
        assert card2.value == 3

    def test_get_today_cards(self, create_user):
        """Test getting today's cards."""
        user = create_user(email='todaycards@test.com')
        
        # Create multiple cards
        for card_type in ['water', 'pills', 'activity']:
            HealthCardRepository.update_card_value(
                user_id=user.id,
                card_type=card_type,
                value=1
            )
        
        cards = HealthCardRepository.get_today_cards(user.id)
        
        assert cards.count() == 3

    def test_get_card_by_type_and_date(self, create_user):
        """Test getting specific card by type and date."""
        user = create_user(email='specific@test.com')
        today = date.today()
        
        # Create card
        HealthCardRepository.update_card_value(
            user_id=user.id,
            card_type='activity',
            value=30,
            recorded_date=today
        )
        
        # Fetch it
        card = HealthCardRepository.get_card_by_type_and_date(
            user_id=user.id,
            card_type='activity',
            recorded_date=today
        )
        
        assert card is not None
        assert card.value == 30

    def test_get_card_not_found(self, create_user):
        """Test getting non-existent card."""
        user = create_user(email='notfound@test.com')
        
        card = HealthCardRepository.get_card_by_type_and_date(
            user_id=user.id,
            card_type='nonexistent'
        )
        
        assert card is None

    def test_default_units(self):
        """Test default units for different card types."""
        assert HealthCardRepository._get_default_unit('water') == 'glasses'
        assert HealthCardRepository._get_default_unit('pills') == 'pills'
        assert HealthCardRepository._get_default_unit('activity') == 'minutes'
        assert HealthCardRepository._get_default_unit('weight') == 'kg'
        assert HealthCardRepository._get_default_unit('unknown') == 'units'
