"""API Views for Users app"""

from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from drf_spectacular.utils import extend_schema
from rest_framework.decorators import api_view, permission_classes
from apps.users.serializers import UserRegistrationSerializer, UserSerializer
from services.settings_service import SettingsService
from repositories.glucose_repository import GlucoseRepository
from utils.api_responses import error_response


class RegisterView(generics.CreateAPIView):
    """User registration endpoint"""
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]
    
    @extend_schema(
        description="Register a new user account",
        request=UserRegistrationSerializer,
        responses={201: UserSerializer}
    )
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            "user": UserSerializer(user).data,
            "tokens": {
                "refresh": str(refresh),
                "access": str(refresh.access_token)
            }
        }, status=status.HTTP_201_CREATED)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Get and update user profile"""
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user


class LogoutView(APIView):
    """Logout by blacklisting refresh token"""
    permission_classes = [IsAuthenticated]
    
    @extend_schema(
        description="Logout and blacklist refresh token",
        request={'application/json': {'type': 'object', 'properties': {'refresh': {'type': 'string'}}}},
        responses={205: None}
    )
    def post(self, request):
        try:
            refresh_token = request.data.get("refresh")
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response(status=status.HTTP_205_RESET_CONTENT)
        except Exception as e:
            return error_response(
                code="logout_failed",
                ui_message="We couldn't log you out right now. Please try again.",
                status_code=status.HTTP_400_BAD_REQUEST,
                exc=e,
            )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def diabetic_profile_read(request):
    """GET /api/v1/auth/diabetic-profile/ - Get diabetic profile"""
    try:
        service = SettingsService()
        data = service.get_settings_data(request.user)
        return Response({'success': True, 'data': data['diabetic_profile']})
    except Exception as e:
        return error_response(
            code="service_unavailable",
            ui_message="We're having trouble connecting to the server right now. We are working on fixing it.",
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            exc=e,
        )


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def diabetic_profile_write(request):
    """PATCH /api/v1/auth/diabetic-profile/ - Update diabetic profile"""
    try:
        service = SettingsService()
        service.update_diabetic_profile(request.user, **request.data)
        data = service.get_settings_data(request.user)
        return Response({'success': True, 'data': data['diabetic_profile']})
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
