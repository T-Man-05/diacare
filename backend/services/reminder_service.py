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
        reminders = self.reminder_repo.get_upcoming_reminders(user.id, limit=limit)
        return [self._format_reminder(r) for r in reminders]
    
    def create_reminder(self, user, data):
        """
        Create a new reminder
        
        Args:
            user: Django User object
            data: dict with keys: title, description, scheduled_time, reminder_type, is_recurring, recurrence_pattern, is_enabled
        
        Returns:
            dict: formatted reminder
        """
        # Validate required fields
        if 'title' not in data:
            raise ValueError("title is required")
        
        # Accept both 'scheduled_time' and 'time' for flexibility
        scheduled_time = data.get('scheduled_time') or data.get('time')
        if not scheduled_time:
            raise ValueError("scheduled_time is required")
        
        if 'reminder_type' not in data:
            data['reminder_type'] = 'medication'
        
        # Convert scheduled_time to time object if string
        if isinstance(scheduled_time, str):
            from datetime import datetime
            # Try different formats
            for fmt in ['%H:%M:%S', '%H:%M']:
                try:
                    scheduled_time = datetime.strptime(scheduled_time, fmt).time()
                    break
                except ValueError:
                    continue
        
        # Build kwargs for repository
        kwargs = {
            'title': data['title'],
            'scheduled_time': scheduled_time,
            'reminder_type': data.get('reminder_type', 'medication'),
            'description': data.get('description', ''),
            'is_recurring': data.get('is_recurring', False),
            'recurrence_pattern': data.get('recurrence_pattern'),
        }
        
        reminder = self.reminder_repo.create_reminder(user.id, **kwargs)
        return self._format_reminder(reminder)
    
    def update_reminder(self, reminder_id, data):
        """Update a reminder"""
        update_data = {}
        
        # Map incoming fields to model fields
        if 'title' in data:
            update_data['title'] = data['title']
        if 'description' in data:
            update_data['description'] = data['description']
        if 'reminder_type' in data:
            update_data['reminder_type'] = data['reminder_type']
        if 'is_recurring' in data:
            update_data['is_recurring'] = data['is_recurring']
        if 'recurrence_pattern' in data:
            update_data['recurrence_pattern'] = data['recurrence_pattern']
        if 'is_enabled' in data:
            update_data['is_enabled'] = data['is_enabled']
        if 'status' in data:
            update_data['status'] = data['status']
        
        # Handle scheduled_time (accept both field names)
        scheduled_time = data.get('scheduled_time') or data.get('time')
        if scheduled_time:
            if isinstance(scheduled_time, str):
                from datetime import datetime
                for fmt in ['%H:%M:%S', '%H:%M']:
                    try:
                        scheduled_time = datetime.strptime(scheduled_time, fmt).time()
                        break
                    except ValueError:
                        continue
            update_data['scheduled_time'] = scheduled_time
        
        reminder = self.reminder_repo.update_reminder(reminder_id, **update_data)
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
        """Toggle reminder enabled state"""
        reminder = self.reminder_repo.toggle_reminder(reminder_id)
        return self._format_reminder(reminder) if reminder else None
    
    def _format_reminder(self, reminder):
        """Format a reminder for API response - matches model fields"""
        now = timezone.now()
        is_late = False
        
        # Check if reminder is late (not completed today and time has passed)
        if reminder.is_enabled and reminder.status == 'pending':
            today = now.date()
            if not reminder.completed_at or reminder.completed_at.date() < today:
                # Reminder not completed today
                reminder_time = timezone.datetime.combine(today, reminder.scheduled_time)
                if timezone.make_aware(reminder_time) < now:
                    is_late = True
        
        return {
            'id': str(reminder.id),
            'title': reminder.title,
            'description': reminder.description or '',
            'scheduled_time': reminder.scheduled_time.strftime('%H:%M:%S'),
            'reminder_type': reminder.reminder_type,
            'is_enabled': reminder.is_enabled,
            'is_recurring': reminder.is_recurring,
            'recurrence_pattern': reminder.recurrence_pattern,
            'status': reminder.status,
            'is_late': is_late,
            'completed_at': reminder.completed_at.isoformat() if reminder.completed_at else None,
            'created_at': reminder.created_at.isoformat(),
            'updated_at': reminder.updated_at.isoformat()
        }
