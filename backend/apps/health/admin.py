"""Admin configuration for Health app"""

from django.contrib import admin
from .models import GlucoseReading, HealthCard


@admin.register(GlucoseReading)
class GlucoseReadingAdmin(admin.ModelAdmin):
    list_display = ["user", "value", "unit", "reading_type", "recorded_at"]
    list_filter = ["reading_type", "recorded_at", "created_at"]
    search_fields = ["user__email", "notes"]
    ordering = ["-recorded_at"]
    date_hierarchy = "recorded_at"


@admin.register(HealthCard)
class HealthCardAdmin(admin.ModelAdmin):
    list_display = ["user", "card_type", "value", "unit", "recorded_date"]
    list_filter = ["card_type", "recorded_date"]
    search_fields = ["user__email"]
    ordering = ["-recorded_date"]
    date_hierarchy = "recorded_date"
