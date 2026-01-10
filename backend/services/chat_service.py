"""
Service Layer - AI Chat Business Logic
=======================================
Handles AI chat functionality using Groq API for diabetes assistance.
"""

import os
from groq import Groq
from django.conf import settings
from apps.chat.models import ChatSession, ChatMessage


class ChatService:
    """Business logic for AI chat operations"""
    
    def __init__(self):
        self.groq_client = Groq(api_key=settings.GROQ_API_KEY)
        self.model = getattr(settings, 'GROQ_MODEL', 'llama-3.3-70b-versatile')
        self.system_prompt = self._build_system_prompt()
    
    def _build_system_prompt(self):
        """Build the system prompt for the AI assistant"""
        return """You are DiaCare AI, a knowledgeable and compassionate diabetes management assistant. 

Your role:
- Help users understand their blood glucose readings
- Provide guidance on diabetes management
- Answer questions about diet, exercise, and medication
- Offer emotional support and motivation
- Explain medical terms in simple language

Guidelines:
- Always be empathetic and supportive
- Provide evidence-based information
- Never diagnose or replace medical advice
- Encourage users to consult healthcare professionals for medical decisions
- Use simple, clear language
- Be concise but informative

Remember: You're a helpful assistant, not a replacement for medical professionals."""
    
    def send_message(self, user, message, conversation_history=None):
        """
        Send a message to the AI and get a response
        
        Args:
            user: Django User object
            message: User's message text
            conversation_history: List of previous messages (optional)
        
        Returns:
            dict: {
                'response': str,
                'conversation_id': str,
                'timestamp': str
            }
        """
        # Get or create chat session
        session = self._get_or_create_session(user)
        
        # Build conversation context
        messages = self._build_conversation_context(conversation_history, message)
        
        try:
            # Call Groq API
            completion = self.groq_client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=0.7,
                max_tokens=1024,
                top_p=1,
                stream=False
            )
            
            ai_response = completion.choices[0].message.content
            
            # Save messages to database
            user_msg = ChatMessage.objects.create(
                session=session,
                role='user',
                content=message
            )
            
            ai_msg = ChatMessage.objects.create(
                session=session,
                role='assistant',
                content=ai_response
            )
            
            return {
                'response': ai_response,
                'conversation_id': str(session.id),
                'timestamp': ai_msg.created_at.isoformat(),
                'message_id': str(ai_msg.id)
            }
            
        except Exception as e:
            # Log error and return friendly message
            print(f"Groq API Error: {e}")
            payload = {
                'response': "I'm sorry, I'm having trouble connecting right now. Please try again in a moment.",
                'conversation_id': str(session.id),
            }
            if getattr(settings, 'DEBUG', False):
                payload['error'] = str(e)
            return payload
    
    def _get_or_create_session(self, user):
        """Get the latest active session or create a new one"""
        # Get latest session from today
        from django.utils import timezone
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        session = ChatSession.objects.filter(
            user=user,
            created_at__gte=today_start
        ).first()
        
        if not session:
            session = ChatSession.objects.create(
                user=user,
                title=f"Chat {timezone.now().strftime('%B %d, %Y')}"
            )
        
        return session
    
    def _build_conversation_context(self, history, current_message):
        """Build the full conversation context for Groq API"""
        messages = [
            {"role": "system", "content": self.system_prompt}
        ]
        
        # Add conversation history if provided
        if history:
            for msg in history:
                messages.append({
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                })
        
        # Add current message
        messages.append({
            "role": "user",
            "content": current_message
        })
        
        return messages
    
    def get_conversation_history(self, user, session_id=None, limit=50):
        """Get conversation history for a user"""
        if session_id:
            messages = ChatMessage.objects.filter(
                session_id=session_id
            ).order_by('created_at')[:limit]
        else:
            # Get latest session
            session = self._get_or_create_session(user)
            messages = ChatMessage.objects.filter(
                session=session
            ).order_by('created_at')[:limit]
        
        return [
            {
                'id': str(msg.id),
                'role': msg.role,
                'content': msg.content,
                'timestamp': msg.created_at.isoformat()
            }
            for msg in messages
        ]
    
    def get_user_sessions(self, user, limit=10):
        """Get all chat sessions for a user"""
        sessions = ChatSession.objects.filter(user=user).order_by('-created_at')[:limit]
        
        return [
            {
                'id': str(session.id),
                'title': session.title,
                'created_at': session.created_at.isoformat(),
                'message_count': session.messages.count()
            }
            for session in sessions
        ]
    
    def delete_session(self, session_id):
        """Delete a chat session and all its messages"""
        ChatSession.objects.filter(id=session_id).delete()
