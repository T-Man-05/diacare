"""Health data models for DiaCare API"""

from django.db import models
from django.conf import settings
import uuid


class GlucoseReading(models.Model):
    """Blood glucose reading record"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="glucose_readings")
    value = models.DecimalField(max_digits=6, decimal_places=2)
    unit = models.CharField(max_length=10, default="mg/dL")
    reading_type = models.CharField(max_length=20, default="before_meal")
    notes = models.TextField(blank=True, null=True)
    recorded_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = "glucose_readings"
        ordering = ["-recorded_at"]


class HealthCard(models.Model):
    """Health tracking card (water, pills, activity, etc.)"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="health_cards")
    card_type = models.CharField(max_length=20)
    value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    unit = models.CharField(max_length=20)
    recorded_date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = "health_cards"
        ordering = ["-recorded_date"]
        unique_together = ["user", "card_type", "recorded_date"]
