"""
Reminder API Views
==================
Handles HTTP requests for reminder operations.
"""

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from apps.reminders.models import Reminder
from apps.reminders.serializers import ReminderSerializer
from services.reminder_service import ReminderService
from utils.api_responses import error_response


class ReminderViewSet(viewsets.ModelViewSet):
    """
    Reminder CRUD operations
    
    Provides full CRUD + complete action
    """
    serializer_class = ReminderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Reminder.objects.filter(user=self.request.user).order_by('scheduled_time')
    
    def list(self, request):
        """List all reminders for the user"""
        service = ReminderService()
        reminders = service.get_user_reminders(request.user)
        return Response({'success': True, 'data': reminders})
    
    def create(self, request):
        """Create a new reminder"""
        try:
            service = ReminderService()
            reminder = service.create_reminder(request.user, request.data)
            return Response({'success': True, 'data': reminder}, status=status.HTTP_201_CREATED)
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
    
    def update(self, request, pk=None):
        """Update a reminder"""
        try:
            service = ReminderService()
            reminder = service.update_reminder(pk, request.data)
            if not reminder:
                return error_response(
                    code="not_found",
                    ui_message="We couldn't find the reminder you're trying to update. It may have been deleted.",
                    status_code=status.HTTP_404_NOT_FOUND,
                )
            return Response({'success': True, 'data': reminder})
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
    
    def partial_update(self, request, pk=None):
        """Partial update a reminder"""
        return self.update(request, pk)
    
    def destroy(self, request, pk=None):
        """Delete a reminder"""
        service = ReminderService()
        service.delete_reminder(pk)
        return Response({'success': True, 'message': 'Reminder deleted'}, status=status.HTTP_204_NO_CONTENT)
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark reminder as completed"""
        service = ReminderService()
        reminder = service.mark_as_completed(pk)
        if not reminder:
            return error_response(
                code="not_found",
                ui_message="We couldn't find the reminder you're trying to update. It may have been deleted.",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        return Response({'success': True, 'data': reminder})
    
    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        """Toggle reminder active state"""
        service = ReminderService()
        reminder = service.toggle_active(pk)
        if not reminder:
            return error_response(
                code="not_found",
                ui_message="We couldn't find the reminder you're trying to update. It may have been deleted.",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        return Response({'success': True, 'data': reminder})
    
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get upcoming reminders"""
        limit = int(request.query_params.get('limit', 10))
        service = ReminderService()
        reminders = service.get_upcoming_reminders(request.user, limit)
        return Response({'success': True, 'data': reminders})
