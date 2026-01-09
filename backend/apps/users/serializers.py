"""Serializers for Users app"""

from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.users.models import DiabeticProfile, UserPreferences

User = get_user_model()


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ['email', 'full_name', 'password', 'password_confirm']
    
    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password": "Passwords must match"})
        return data
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            full_name=validated_data.get('full_name', '')
        )
        
        # Create default diabetic profile
        DiabeticProfile.objects.create(user=user)
        
        # Create default preferences
        UserPreferences.objects.create(user=user)
        
        return user


class DiabeticProfileSerializer(serializers.ModelSerializer):
    """Serializer for DiabeticProfile"""
    
    class Meta:
        model = DiabeticProfile
        fields = ['diabetic_type', 'treatment_type', 'min_glucose', 'max_glucose', 'diagnosis_date']


class UserPreferencesSerializer(serializers.ModelSerializer):
    """Serializer for UserPreferences"""
    
    class Meta:
        model = UserPreferences
        fields = ['theme', 'locale', 'units', 'notifications_enabled', 'biometric_enabled', 'onboarding_complete']


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User profile"""
    diabetic_profile = DiabeticProfileSerializer(read_only=True)
    preferences = UserPreferencesSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'date_of_birth', 'gender', 'height', 'weight', 
                 'profile_image_url', 'diabetic_profile', 'preferences']
        read_only_fields = ['id', 'email']
