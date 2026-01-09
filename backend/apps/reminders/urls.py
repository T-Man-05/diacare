"""Reminder app URL configuration"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.reminders.views import ReminderViewSet

router = DefaultRouter()
router.register(r'', ReminderViewSet, basename='reminder')

urlpatterns = [
    path('', include(router.urls)),
]
