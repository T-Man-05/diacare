"""
Service Layer - Settings Business Logic
========================================
Handles all settings-related business logic including:
- Reading user settings (profile, preferences, diabetic profile)
- Updating individual settings (theme, locale, units, notifications)
- Validation and formatting
"""

from repositories.user_repository import (
    UserRepository,
    DiabeticProfileRepository,
    UserPreferencesRepository
)


class SettingsService:
    """Business logic for settings operations"""
    
    def __init__(self):
        self.user_repo = UserRepository()
        self.diabetic_repo = DiabeticProfileRepository()
        self.prefs_repo = UserPreferencesRepository()
    
    def get_settings_data(self, user):
        """
        Get all settings for the settings screen
        Returns a dictionary with profile, diabetic_profile, and preferences
        """
        # Get user profile
        profile_data = {
            'id': str(user.id),
            'email': user.email,
            'username': user.username or '',
            'full_name': user.full_name or '',
            'profile_image_url': user.profile_image_url or '',
            'date_of_birth': user.date_of_birth.isoformat() if user.date_of_birth else None,
            'gender': user.gender or '',
            'height': float(user.height) if user.height else None,
            'weight': float(user.weight) if user.weight else None,
        }
        
        # Get diabetic profile
        diabetic_profile = self.diabetic_repo.get_or_create_profile(user.id)
        diabetic_data = {
            'diabetic_type': diabetic_profile.diabetic_type,
            'treatment_type': diabetic_profile.treatment_type,
            'min_glucose': diabetic_profile.min_glucose,
            'max_glucose': diabetic_profile.max_glucose,
            'diagnosis_date': diabetic_profile.diagnosis_date.isoformat() if diabetic_profile.diagnosis_date else None,
        }
        
        # Get user preferences
        preferences = self.prefs_repo.get_or_create_preferences(user.id)
        prefs_data = {
            'theme': preferences.theme,
            'locale': preferences.locale,
            'units': preferences.units,
            'notifications_enabled': preferences.notifications_enabled,
            'biometric_enabled': preferences.biometric_enabled,
            'onboarding_complete': preferences.onboarding_complete,
        }
        
        return {
            'profile': profile_data,
            'diabetic_profile': diabetic_data,
            'preferences': prefs_data
        }
    
    def update_theme(self, user, theme):
        """Update theme preference"""
        # Validate theme
        valid_themes = ['light', 'dark', 'system']
        if theme not in valid_themes:
            raise ValueError(f"Invalid theme: {theme}. Must be one of {valid_themes}")
        
        self.prefs_repo.update_theme(user.id, theme)
        return {'theme': theme}
    
    def update_locale(self, user, locale):
        """Update locale preference"""
        # Validate locale
        valid_locales = ['en', 'fr', 'ar']
        if locale not in valid_locales:
            raise ValueError(f"Invalid locale: {locale}. Must be one of {valid_locales}")
        
        self.prefs_repo.update_locale(user.id, locale)
        return {'locale': locale}
    
    def update_units(self, user, units):
        """Update glucose units preference"""
        # Validate units
        valid_units = ['mg/dL', 'mmol/L']
        if units not in valid_units:
            raise ValueError(f"Invalid units: {units}. Must be one of {valid_units}")
        
        self.prefs_repo.update_units(user.id, units)
        return {'units': units}
    
    def update_notifications(self, user, enabled):
        """Update notifications preference"""
        if not isinstance(enabled, bool):
            raise ValueError("notifications_enabled must be a boolean")
        
        self.prefs_repo.update_notifications(user.id, enabled)
        return {'notifications_enabled': enabled}
    
    def update_biometric(self, user, enabled):
        """Update biometric preference"""
        if not isinstance(enabled, bool):
            raise ValueError("biometric_enabled must be a boolean")
        
        self.prefs_repo.update_preferences(user.id, biometric_enabled=enabled)
        return {'biometric_enabled': enabled}
    
    def update_profile(self, user, **data):
        """Update user profile information"""
        # Filter allowed fields
        allowed_fields = ['username', 'full_name', 'profile_image_url', 
                         'date_of_birth', 'gender', 'height', 'weight']
        
        update_data = {k: v for k, v in data.items() if k in allowed_fields}
        
        if update_data:
            self.user_repo.update_user(user.id, **update_data)
        
        return update_data
    
    def update_diabetic_profile(self, user, **data):
        """Update diabetic profile information"""
        # Filter allowed fields
        allowed_fields = ['diabetic_type', 'treatment_type', 'min_glucose', 
                         'max_glucose', 'diagnosis_date']
        
        update_data = {k: v for k, v in data.items() if k in allowed_fields}
        
        # Validate glucose ranges
        if 'min_glucose' in update_data and update_data['min_glucose'] < 0:
            raise ValueError("min_glucose must be positive")
        if 'max_glucose' in update_data and update_data['max_glucose'] < 0:
            raise ValueError("max_glucose must be positive")
        if 'min_glucose' in update_data and 'max_glucose' in update_data:
            if update_data['min_glucose'] >= update_data['max_glucose']:
                raise ValueError("min_glucose must be less than max_glucose")
        
        if update_data:
            self.diabetic_repo.update_profile(user.id, **update_data)
        
        return update_data
