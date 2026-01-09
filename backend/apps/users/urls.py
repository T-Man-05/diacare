"""URL configuration for Users app"""

from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from apps.users.views import RegisterView, UserProfileView, LogoutView, diabetic_profile_read, diabetic_profile_write
from apps.users.settings_views import settings_read, settings_write

urlpatterns = [
    # JWT Authentication
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # User Management
    path('register/', RegisterView.as_view(), name='register'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('logout/', LogoutView.as_view(), name='logout'),
    
    # Settings (BFF pattern)
    path('settings/', settings_read, name='settings-read'),
    path('settings/update/', settings_write, name='settings-write'),
    
    # Diabetic Profile
    path('diabetic-profile/', diabetic_profile_read, name='diabetic-profile-read'),
    path('diabetic-profile/update/', diabetic_profile_write, name='diabetic-profile-write'),
]
