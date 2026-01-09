"""
Chat API Views
==============
Handles HTTP requests for AI chat operations.
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from services.chat_service import ChatService


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def chat_send_message(request):
    """
    POST /api/v1/chat/
    
    Send a message to the AI assistant and get a response.
    
    Body:
    {
        "message": "What should my blood sugar be?",
        "history": [  // Optional
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi! How can I help?"}
        ]
    }
    
    Response:
    {
        "success": true,
        "data": {
            "response": "AI response text",
            "conversation_id": "uuid",
            "timestamp": "ISO timestamp",
            "message_id": "uuid"
        }
    }
    """
    try:
        service = ChatService()
        
        message = request.data.get('message')
        if not message:
            return Response({
                'success': False,
                'error': 'message is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        history = request.data.get('history', [])
        
        result = service.send_message(request.user, message, history)
        
        return Response({
            'success': True,
            'data': result
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_get_history(request):
    """
    GET /api/v1/chat/history/
    
    Get conversation history for the current user.
    Query params:
    - session_id: Optional UUID of specific session
    - limit: Number of messages to return (default: 50)
    """
    try:
        service = ChatService()
        
        session_id = request.query_params.get('session_id')
        limit = int(request.query_params.get('limit', 50))
        
        history = service.get_conversation_history(request.user, session_id, limit)
        
        return Response({
            'success': True,
            'data': {
                'messages': history,
                'count': len(history)
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def chat_get_sessions(request):
    """
    GET /api/v1/chat/sessions/
    
    Get all chat sessions for the current user.
    """
    try:
        service = ChatService()
        
        limit = int(request.query_params.get('limit', 10))
        sessions = service.get_user_sessions(request.user, limit)
        
        return Response({
            'success': True,
            'data': {
                'sessions': sessions,
                'count': len(sessions)
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def chat_delete_session(request, session_id):
    """
    DELETE /api/v1/chat/sessions/{session_id}/
    
    Delete a chat session and all its messages.
    """
    try:
        service = ChatService()
        service.delete_session(session_id)
        
        return Response({
            'success': True,
            'message': 'Session deleted successfully'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
