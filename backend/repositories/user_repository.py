"""
Repository Layer - User Data Access
====================================
Handles all database operations for User, DiabeticProfile, and UserPreferences models.
Repositories know ONLY about database queries - no business logic, no HTTP.
"""

from django.db.models import Q
from apps.users.models import User, DiabeticProfile, UserPreferences


class UserRepository:
    """Database operations for User model"""
    
    def get_user_by_id(self, user_id):
        """Get user by ID"""
        try:
            return User.objects.select_related('diabetic_profile', 'preferences').get(id=user_id)
        except User.DoesNotExist:
            return None
    
    def get_user_by_email(self, email):
        """Get user by email"""
        try:
            return User.objects.get(email=email.lower())
        except User.DoesNotExist:
            return None
    
    def create_user(self, **data):
        """Create a new user"""
        return User.objects.create_user(**data)
    
    def update_user(self, user_id, **data):
        """Update user fields"""
        User.objects.filter(id=user_id).update(**data)
        return self.get_user_by_id(user_id)


class DiabeticProfileRepository:
    """Database operations for DiabeticProfile model"""
    
    def get_profile(self, user_id):
        """Get diabetic profile for user"""
        try:
            return DiabeticProfile.objects.get(user_id=user_id)
        except DiabeticProfile.DoesNotExist:
            return None
    
    def get_or_create_profile(self, user_id, defaults=None):
        """Get or create diabetic profile"""
        profile, created = DiabeticProfile.objects.get_or_create(
            user_id=user_id,
            defaults=defaults or {}
        )
        return profile
    
    def update_profile(self, user_id, **data):
        """Update diabetic profile"""
        DiabeticProfile.objects.filter(user_id=user_id).update(**data)
        return self.get_profile(user_id)


class UserPreferencesRepository:
    """Database operations for UserPreferences model"""
    
    def get_preferences(self, user_id):
        """Get user preferences"""
        try:
            return UserPreferences.objects.get(user_id=user_id)
        except UserPreferences.DoesNotExist:
            return None
    
    def get_or_create_preferences(self, user_id, defaults=None):
        """Get or create user preferences"""
        prefs, created = UserPreferences.objects.get_or_create(
            user_id=user_id,
            defaults=defaults or {}
        )
        return prefs
    
    def update_preferences(self, user_id, **data):
        """Update user preferences"""
        prefs, created = UserPreferences.objects.get_or_create(
            user_id=user_id,
            defaults=data
        )
        
        if not created:
            for key, value in data.items():
                setattr(prefs, key, value)
            prefs.save()
        
        return prefs
    
    def update_theme(self, user_id, theme):
        """Update theme preference"""
        return self.update_preferences(user_id, theme=theme)
    
    def update_locale(self, user_id, locale):
        """Update locale preference"""
        return self.update_preferences(user_id, locale=locale)
    
    def update_units(self, user_id, units):
        """Update units preference"""
        return self.update_preferences(user_id, units=units)
    
    def update_notifications(self, user_id, enabled):
        """Update notifications preference"""
        return self.update_preferences(user_id, notifications_enabled=enabled)
