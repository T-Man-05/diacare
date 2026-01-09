"""Reminder Serializers"""

from rest_framework import serializers
from apps.reminders.models import Reminder


class ReminderSerializer(serializers.ModelSerializer):
    """Serializer for Reminder model"""
    
    class Meta:
        model = Reminder
        fields = ['id', 'title', 'description', 'reminder_type', 'scheduled_time',
                  'is_enabled', 'is_recurring', 'recurrence_pattern', 'status',
                  'completed_at', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at', 'completed_at']
