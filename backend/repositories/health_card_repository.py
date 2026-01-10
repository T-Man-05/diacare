"""Health Card Repository - Data Access Layer"""

from typing import List, Optional
from datetime import date
from decimal import Decimal, InvalidOperation
from django.db.models import QuerySet
from apps.health.models import HealthCard


class HealthCardRepository:
    """Handles all database operations for Health Cards (water, pills, activity, etc.)"""
    
    @staticmethod
    def get_today_cards(user_id: int) -> QuerySet:
        """Get today's health cards for a user"""
        today = date.today()
        return HealthCard.objects.filter(
            user_id=user_id,
            recorded_date=today
        )
    
    @staticmethod
    def get_or_create_card(user_id: int, card_type: str, recorded_date: Optional[date] = None) -> HealthCard:
        """
        Get existing card or create new one
        
        Args:
            user_id: User ID
            card_type: Type of card (water, pills, activity, weight)
            recorded_date: Date for the card (defaults to today)
        
        Returns:
            HealthCard object
        """
        if recorded_date is None:
            recorded_date = date.today()
        
        card, created = HealthCard.objects.get_or_create(
            user_id=user_id,
            card_type=card_type,
            recorded_date=recorded_date,
            defaults={'value': 0, 'unit': HealthCardRepository._get_default_unit(card_type)}
        )
        return card
    
    @staticmethod
    def update_card_value(user_id: int, card_type: str, value: float, 
                         recorded_date: Optional[date] = None) -> HealthCard:
        """Update or create health card value"""
        card = HealthCardRepository.get_or_create_card(user_id, card_type, recorded_date)
        # Store as Decimal to match the model field type and avoid float issues.
        try:
            card.value = Decimal(str(value))
        except (InvalidOperation, TypeError, ValueError):
            card.value = Decimal('0')
        card.save()
        return card
    
    @staticmethod
    def increment_card_value(user_id: int, card_type: str, increment: float = 1.0,
                           recorded_date: Optional[date] = None) -> HealthCard:
        """Increment health card value (useful for water glasses, pills taken)"""
        card = HealthCardRepository.get_or_create_card(user_id, card_type, recorded_date)
        # DecimalField stores Decimal; adding a float raises TypeError.
        try:
            inc = Decimal(str(increment))
        except (InvalidOperation, TypeError, ValueError):
            inc = Decimal('0')

        current = card.value if card.value is not None else Decimal('0')
        card.value = current + inc
        card.save()
        return card
    
    @staticmethod
    def get_card_by_type_and_date(user_id: int, card_type: str, 
                                 recorded_date: Optional[date] = None) -> Optional[HealthCard]:
        """Get a specific health card"""
        if recorded_date is None:
            recorded_date = date.today()
        
        try:
            return HealthCard.objects.get(
                user_id=user_id,
                card_type=card_type,
                recorded_date=recorded_date
            )
        except HealthCard.DoesNotExist:
            return None
    
    @staticmethod
    def _get_default_unit(card_type: str) -> str:
        """Get default unit for card type"""
        units = {
            'water': 'glasses',
            'pills': 'pills',
            'activity': 'minutes',
            'weight': 'kg',
            'steps': 'steps',
            'sleep': 'hours'
        }
        return units.get(card_type, 'units')
