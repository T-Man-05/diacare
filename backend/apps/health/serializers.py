"""Serializers for Health app"""

from rest_framework import serializers
from apps.health.models import GlucoseReading, HealthCard


class GlucoseReadingSerializer(serializers.ModelSerializer):
    """Serializer for GlucoseReading model"""
    
    class Meta:
        model = GlucoseReading
        fields = ['id', 'value', 'unit', 'reading_type', 'notes', 'recorded_at', 'created_at']
        read_only_fields = ['id', 'created_at']
    
    def create(self, validated_data):
        # Add user from request context
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class HealthCardSerializer(serializers.ModelSerializer):
    """Serializer for HealthCard model"""
    
    class Meta:
        model = HealthCard
        fields = ['id', 'card_type', 'value', 'unit', 'recorded_date', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
