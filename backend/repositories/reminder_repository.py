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
        """Get all enabled reminders for today (for dashboard display)"""
        return Reminder.objects.filter(
            user_id=user_id,
            is_enabled=True
        ).order_by("scheduled_time")

    @staticmethod
    def get_upcoming_reminders(user_id: int, limit: int = 10) -> QuerySet:
        """Get upcoming (future-time) reminders for today.

        Notes:
        - Reminders are time-only (no date), so we treat them as "today".
        - Excludes completed/done reminders.
        - Returns at most `limit` reminders ordered by scheduled_time.
        """
        now = timezone.now().time()
        queryset = (
            Reminder.objects.filter(user_id=user_id, is_enabled=True)
            .exclude(status__in=["completed", "done"])
            .filter(scheduled_time__gte=now)
            .order_by("scheduled_time")
        )
        return queryset[:limit]

    @staticmethod
    def get_next_upcoming_reminder(user_id: int) -> Optional[Reminder]:
        """Get the single closest upcoming reminder for today.

        Returns:
            The next Reminder (closest future scheduled_time), or None if none.
        """
        now = timezone.now().time()
        base_qs = (
            Reminder.objects.filter(user_id=user_id, is_enabled=True)
            .exclude(status__in=["completed", "done"])
        )

        # 1) Prefer the closest reminder still ahead of us today.
        upcoming = (
            base_qs.filter(scheduled_time__gte=now)
            .order_by("scheduled_time")
            .first()
        )
        if upcoming:
            return upcoming

        # 2) If none remain today, wrap to the next day: pick the earliest one.
        return base_qs.order_by("scheduled_time").first()

    @staticmethod
    def count_late_reminders(user_id: int) -> int:
        """Count enabled reminders that are late today (time already passed) and not done."""
        now = timezone.now().time()
        return (
            Reminder.objects.filter(user_id=user_id, is_enabled=True)
            .exclude(status__in=["completed", "done"])
            .filter(scheduled_time__lt=now)
            .count()
        )
    
    @staticmethod
    def create_reminder(user_id: int, title: str = None, scheduled_time: time = None,
                       reminder_type: str = "medication", description: str = "",
                       is_recurring: bool = False, recurrence_pattern: str = None,
                       **kwargs) -> Reminder:
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
