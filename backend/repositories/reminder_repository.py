"""Reminder Repository - Data Access Layer"""

from typing import List, Optional
from datetime import datetime, time
from django.db.models import QuerySet
from django.utils import timezone
from apps.reminders.models import Reminder


class ReminderRepository:
    """Handles all database operations for Reminders"""
    
    @staticmethod
    def get_user_reminders(user_id: int, only_enabled: bool = False) -> QuerySet:
        """
        Get all reminders for a user
        
        Args:
            user_id: User ID
            only_enabled: If True, return only enabled reminders
        
        Returns:
            QuerySet of Reminder objects
        """
        queryset = Reminder.objects.filter(user_id=user_id)
        if only_enabled:
            queryset = queryset.filter(is_enabled=True)
        return queryset.order_by("scheduled_time")
    
    @staticmethod
    def get_today_reminders(user_id: int) -> QuerySet:
        """Get today's upcoming reminders"""
        now = timezone.now()
        current_time = now.time()
        
        return Reminder.objects.filter(
            user_id=user_id,
            is_enabled=True,
            scheduled_time__gte=current_time
        ).order_by("scheduled_time")
    
    @staticmethod
    def create_reminder(user_id: int, title: str, scheduled_time: time,
                       reminder_type: str = "medication", description: str = "",
                       is_recurring: bool = False, recurrence_pattern: str = None) -> Reminder:
        """
        Create a new reminder
        
        Args:
            user_id: User ID
            title: Reminder title
            scheduled_time: Time to trigger reminder
            reminder_type: Type (medication, activity, appointment, etc.)
            description: Optional description
            is_recurring: Whether reminder repeats
            recurrence_pattern: Pattern (daily, weekly, etc.)
        
        Returns:
            Created Reminder object
        """
        reminder = Reminder.objects.create(
            user_id=user_id,
            title=title,
            scheduled_time=scheduled_time,
            reminder_type=reminder_type,
            description=description,
            is_recurring=is_recurring,
            recurrence_pattern=recurrence_pattern,
            is_enabled=True,
            status="pending"
        )
        return reminder
    
    @staticmethod
    def get_reminder_by_id(reminder_id: str) -> Optional[Reminder]:
        """Get a specific reminder by ID"""
        try:
            return Reminder.objects.get(id=reminder_id)
        except Reminder.DoesNotExist:
            return None
    
    @staticmethod
    def update_reminder(reminder_id: str, **kwargs) -> Optional[Reminder]:
        """Update a reminder"""
        reminder = ReminderRepository.get_reminder_by_id(reminder_id)
        if reminder:
            for key, value in kwargs.items():
                setattr(reminder, key, value)
            reminder.save()
        return reminder
    
    @staticmethod
    def mark_as_completed(reminder_id: str) -> Optional[Reminder]:
        """Mark a reminder as completed"""
        reminder = ReminderRepository.get_reminder_by_id(reminder_id)
        if reminder:
            reminder.status = "completed"
            reminder.completed_at = timezone.now()
            reminder.save()
        return reminder
    
    @staticmethod
    def toggle_reminder(reminder_id: str) -> Optional[Reminder]:
        """Toggle reminder enabled/disabled"""
        reminder = ReminderRepository.get_reminder_by_id(reminder_id)
        if reminder:
            reminder.is_enabled = not reminder.is_enabled
            reminder.save()
        return reminder
    
    @staticmethod
    def delete_reminder(reminder_id: str) -> bool:
        """Delete a reminder"""
        reminder = ReminderRepository.get_reminder_by_id(reminder_id)
        if reminder:
            reminder.delete()
            return True
        return False
