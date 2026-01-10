"""API Views for Health app"""

from decimal import Decimal, InvalidOperation
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, extend_schema_view
from apps.health.models import GlucoseReading, HealthCard
from apps.health.serializers import GlucoseReadingSerializer, HealthCardSerializer
from repositories.glucose_repository import GlucoseRepository
from repositories.health_card_repository import HealthCardRepository
from services.glucose_service import GlucoseService


@extend_schema_view(
    list=extend_schema(description="List all glucose readings for authenticated user"),
    create=extend_schema(description="Create a new glucose reading"),
    retrieve=extend_schema(description="Get a specific glucose reading"),
    update=extend_schema(description="Update a glucose reading"),
    destroy=extend_schema(description="Delete a glucose reading"),
)
class GlucoseReadingViewSet(viewsets.ModelViewSet):
    """
    Glucose Reading CRUD operations
    
    Provides standard CRUD + custom endpoints for statistics and trends
    """
    serializer_class = GlucoseReadingSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return GlucoseRepository.get_user_readings(self.request.user.id, days=30)
    
    @extend_schema(
        description="Get glucose statistics (average, min, max) for specified days",
        parameters=[
            {
                'name': 'days',
                'in': 'query',
                'description': 'Number of days to calculate statistics (default: 7)',
                'required': False,
                'schema': {'type': 'integer'}
            }
        ]
    )
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get glucose statistics"""
        days = int(request.query_params.get('days', 7))
        stats = GlucoseRepository.get_statistics(request.user.id, days)
        return Response(stats)
    
    @extend_schema(
        description="Get glucose range analysis (in/below/above target)",
        parameters=[
            {
                'name': 'days',
                'in': 'query',
                'description': 'Number of days to analyze (default: 7)',
                'required': False,
                'schema': {'type': 'integer'}
            }
        ]
    )
    @action(detail=False, methods=['get'])
    def range_analysis(self, request):
        """Get range analysis"""
        days = int(request.query_params.get('days', 7))
        user = request.user
        profile = user.diabetic_profile
        
        analysis = GlucoseRepository.get_range_analysis(
            user.id,
            profile.min_glucose,
            profile.max_glucose,
            days
        )
        return Response(analysis)
    
    @action(detail=False, methods=['get'])
    def latest(self, request):
        """Get the latest glucose reading"""
        service = GlucoseService()
        reading = GlucoseRepository().get_latest_reading(request.user.id)
        if not reading:
            return Response({'message': 'No glucose readings found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Format the reading
        min_glucose = request.user.diabetic_profile.min_glucose if hasattr(request.user, 'diabetic_profile') else 70
        max_glucose = request.user.diabetic_profile.max_glucose if hasattr(request.user, 'diabetic_profile') else 180
        formatted = service._format_reading(reading, min_glucose, max_glucose)
        return Response({'success': True, 'data': formatted})
    
    @action(detail=False, methods=['get'])
    def chart(self, request):
        """Get glucose chart data for the past 7 days"""
        days = int(request.query_params.get('days', 7))
        readings = GlucoseRepository().get_readings_last_n_days(request.user.id, days)
        
        # Format for chart
        chart_data = [
            {
                'date': reading.recorded_at.strftime('%Y-%m-%d'),
                'time': reading.recorded_at.strftime('%H:%M'),
                'value': float(reading.value),
                'timestamp': reading.recorded_at.isoformat()
            }
            for reading in readings
        ]
        
        return Response({'success': True, 'data': chart_data})


@extend_schema_view(
    list=extend_schema(description="List all health cards for authenticated user"),
    create=extend_schema(description="Create or update a health card"),
    retrieve=extend_schema(description="Get a specific health card"),
    update=extend_schema(description="Update a health card"),
)
class HealthCardViewSet(viewsets.ModelViewSet):
    """
    Health Card CRUD operations
    
    Manages daily health tracking cards (water, pills, activity, etc.)
    """
    serializer_class = HealthCardSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return HealthCardRepository.get_today_cards(self.request.user.id)
    
    @extend_schema(
        description="Increment card value (useful for water glasses, pills)",
        request={
            'application/json': {
                'type': 'object',
                'properties': {
                    'card_type': {'type': 'string'},
                    'increment': {'type': 'number', 'default': 1.0}
                }
            }
        }
    )
    @action(detail=False, methods=['post'])
    def increment(self, request):
        """Increment a health card value"""
        card_type = request.data.get('card_type')
        if not card_type or not isinstance(card_type, str):
            return Response(
                {'detail': 'card_type is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        raw_increment = request.data.get('increment', 1.0)
        try:
            increment = Decimal(str(raw_increment))
        except (InvalidOperation, TypeError, ValueError):
            return Response(
                {'detail': 'increment must be a number'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        card = HealthCardRepository.increment_card_value(
            request.user.id,
            card_type,
            increment
        )
        
        serializer = self.get_serializer(card)
        return Response(serializer.data)
