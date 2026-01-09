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
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def diabetic_profile_read(request):
    """GET /api/v1/auth/diabetic-profile/ - Get diabetic profile"""
    try:
        service = SettingsService()
        data = service.get_settings_data(request.user)
        return Response({'success': True, 'data': data['diabetic_profile']})
    except Exception as e:
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'success': False, 'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
