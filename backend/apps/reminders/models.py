"""Reminder models for DiaCare API"""

from django.db import models
from django.conf import settings
import uuid


class Reminder(models.Model):
    """Medication and activity reminders"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reminders")
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    reminder_type = models.CharField(max_length=20, default="medication")
    scheduled_time = models.TimeField()
    is_enabled = models.BooleanField(default=True)
    is_recurring = models.BooleanField(default=False)
    recurrence_pattern = models.CharField(max_length=20, blank=True, null=True)
    status = models.CharField(max_length=20, default="pending")
    completed_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = "reminders"
        ordering = ["scheduled_time"]
