"""URL configuration for Health app"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from apps.health.views import GlucoseReadingViewSet, HealthCardViewSet
from apps.health.dashboard_view import DashboardView
from apps.health.insights_view import InsightsView
from apps.health.stream_views import dashboard_stream_view

router = DefaultRouter()
router.register('glucose', GlucoseReadingViewSet, basename='glucose')
router.register('cards', HealthCardViewSet, basename='healthcard')

urlpatterns = [
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('dashboard/stream/', dashboard_stream_view, name='dashboard-stream'),
    path('insights/', InsightsView.as_view(), name='insights'),
    path('', include(router.urls)),
]
