"""
Service Layer - Reminders Business Logic
=========================================
Handles reminder business logic including:
- Listing reminders
- Creating reminders
- Updating reminders
- Marking as completed
"""

from django.utils import timezone
from repositories.reminder_repository import ReminderRepository


class ReminderService:
    """Business logic for reminder operations"""
    
    def __init__(self):
        self.reminder_repo = ReminderRepository()
    
    def get_user_reminders(self, user):
        """Get all reminders for a user"""
        reminders = self.reminder_repo.get_user_reminders(user.id)
        return [self._format_reminder(r) for r in reminders]
    
    def get_upcoming_reminders(self, user, limit=10):
        """Get upcoming reminders (not completed today)"""
        reminders = self.reminder_repo.get_upcoming_reminders(user.id, limit)
        return [self._format_reminder(r) for r in reminders]
    
    def create_reminder(self, user, data):
        """
        Create a new reminder
        
        Args:
            user: Django User object
            data: dict with keys: title, description, time, reminder_type, repeat_days, is_active
        
        Returns:
            dict: formatted reminder
        """
        # Validate required fields
        if 'title' not in data:
            raise ValueError("title is required")
        if 'time' not in data:
            raise ValueError("time is required")
        if 'reminder_type' not in data:
            data['reminder_type'] = 'medication'
        
        # Convert time to time object if string
        if isinstance(data['time'], str):
            from datetime import datetime
            time_obj = datetime.strptime(data['time'], '%H:%M:%S').time()
            data['time'] = time_obj
        
        # Set defaults
        data.setdefault('description', '')
        data.setdefault('repeat_days', '1111111')  # Every day
        data.setdefault('is_active', True)
        
        reminder = self.reminder_repo.create_reminder(user.id, **data)
        return self._format_reminder(reminder)
    
    def update_reminder(self, reminder_id, data):
        """Update a reminder"""
        # Convert time if needed
        if 'time' in data and isinstance(data['time'], str):
            from datetime import datetime
            time_obj = datetime.strptime(data['time'], '%H:%M:%S').time()
            data['time'] = time_obj
        
        reminder = self.reminder_repo.update_reminder(reminder_id, **data)
        return self._format_reminder(reminder) if reminder else None
    
    def delete_reminder(self, reminder_id):
        """Delete a reminder"""
        self.reminder_repo.delete_reminder(reminder_id)
        return {'success': True}
    
    def mark_as_completed(self, reminder_id):
        """Mark reminder as completed"""
        reminder = self.reminder_repo.mark_as_completed(reminder_id)
        return self._format_reminder(reminder) if reminder else None
    
    def toggle_active(self, reminder_id):
        """Toggle reminder active state"""
        reminder = self.reminder_repo.toggle_active(reminder_id)
        return self._format_reminder(reminder) if reminder else None
    
    def _format_reminder(self, reminder):
        """Format a reminder for API response"""
        now = timezone.now()
        is_late = False
        
        # Check if reminder is late (not completed today and time has passed)
        if reminder.is_active:
            today = now.date()
            if not reminder.last_completed_at or reminder.last_completed_at.date() < today:
                # Reminder not completed today
                reminder_time = timezone.datetime.combine(today, reminder.time)
                if timezone.make_aware(reminder_time) < now:
                    is_late = True
        
        return {
            'id': str(reminder.id),
            'title': reminder.title,
            'description': reminder.description or '',
            'time': reminder.time.strftime('%H:%M:%S'),
            'reminder_type': reminder.reminder_type,
            'repeat_days': reminder.repeat_days,
            'is_active': reminder.is_active,
            'is_late': is_late,
            'last_completed_at': reminder.last_completed_at.isoformat() if reminder.last_completed_at else None,
            'created_at': reminder.created_at.isoformat(),
            'updated_at': reminder.updated_at.isoformat()
        }
