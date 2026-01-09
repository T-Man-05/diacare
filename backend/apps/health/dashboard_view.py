"""Dashboard BFF View - One endpoint for entire dashboard"""

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema
from services.dashboard_service import DashboardService


class DashboardView(APIView):
    """
    BFF (Backend for Frontend) endpoint for Dashboard screen
    
    Returns ALL data needed for the dashboard in a single API call:
    - User info
    - Latest glucose reading with status
    - 7-day glucose trend
    - Statistics (avg, min, max)
    - Range analysis
    - Health cards (water, pills, activity)
    - Today's reminders
    - Goals and progress
    
    This approach reduces API calls from 8-10 down to 1!
    """
    permission_classes = [IsAuthenticated]
    
    @extend_schema(
        description="Get complete dashboard data in one API call",
        responses={
            200: {
                'type': 'object',
                'properties': {
                    'user': {'type': 'object'},
                    'glucose': {'type': 'object'},
                    'health_cards': {'type': 'object'},
                    'reminders': {'type': 'array'},
                    'goals': {'type': 'object'},
                    'timestamp': {'type': 'string', 'format': 'date-time'}
                }
            }
        }
    )
    def get(self, request):
        """Get dashboard data"""
        dashboard_data = DashboardService.get_dashboard_data(request.user.id)
        return Response(dashboard_data)
