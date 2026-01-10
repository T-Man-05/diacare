"""
Settings API Views
==================
Handles HTTP requests for settings operations following BFF pattern.
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from services.settings_service import SettingsService
from utils.api_responses import error_response


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def settings_read(request):
    """
    GET /api/v1/settings/
    
    Read all settings for the authenticated user.
    Returns profile, diabetic_profile, and preferences in one call (BFF pattern).
    """
    try:
        service = SettingsService()
        data = service.get_settings_data(request.user)
        
        return Response({
            'success': True,
            'data': data
        })
        
    except Exception as e:
        return error_response(
            code="service_unavailable",
            ui_message="We're having trouble connecting to the server right now. We are working on fixing it.",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            exc=e,
        )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def settings_write(request):
    """
    PATCH /api/v1/settings/
    
    Update settings for the authenticated user.
    Accepts multiple fields and updates them atomically.
    
    Body can contain:
    - theme: 'light' | 'dark' | 'system'
    - locale: 'en' | 'fr' | 'ar'
    - units: 'mg/dL' | 'mmol/L'
    - notifications_enabled: boolean
    - biometric_enabled: boolean
    - profile: object with user profile fields
    - diabetic_profile: object with diabetic profile fields
    """
    try:
        service = SettingsService()
        
        # Update preferences
        if 'theme' in request.data:
            service.update_theme(request.user, request.data['theme'])
        
        if 'locale' in request.data:
            service.update_locale(request.user, request.data['locale'])
        
        if 'units' in request.data:
            service.update_units(request.user, request.data['units'])
        
        if 'notifications_enabled' in request.data:
            service.update_notifications(request.user, request.data['notifications_enabled'])
        
        if 'biometric_enabled' in request.data:
            service.update_biometric(request.user, request.data['biometric_enabled'])
        
        # Update profile
        if 'profile' in request.data:
            service.update_profile(request.user, **request.data['profile'])
        
        # Update diabetic profile
        if 'diabetic_profile' in request.data:
            service.update_diabetic_profile(request.user, **request.data['diabetic_profile'])
        
        # Return updated settings
        data = service.get_settings_data(request.user)
        
        return Response({
            'success': True,
            'data': data,
            'message': 'Settings updated successfully'
        })
        
    except ValueError as e:
        return error_response(
            code="validation_error",
            ui_message=(
                "Some information seems to be missing or incorrect. "
                "Please check the highlighted fields."
            ),
            status_code=status.HTTP_400_BAD_REQUEST,
            exc=e,
        )
        
    except Exception as e:
        return error_response(
            code="service_unavailable",
            ui_message="We're having trouble connecting to the server right now. We are working on fixing it.",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            exc=e,
        )
