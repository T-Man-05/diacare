"""Admin configuration for Reminders app"""

from django.contrib import admin
from .models import Reminder


@admin.register(Reminder)
class ReminderAdmin(admin.ModelAdmin):
    list_display = ["user", "title", "reminder_type", "scheduled_time", "is_enabled", "status"]
    list_filter = ["reminder_type", "is_enabled", "status", "is_recurring"]
    search_fields = ["user__email", "title", "description"]
    ordering = ["scheduled_time"]
    date_hierarchy = "created_at"
