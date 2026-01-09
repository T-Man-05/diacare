"""Chat models for DiaCare API"""

from django.db import models
from django.conf import settings
import uuid


class ChatSession(models.Model):
    """AI chat conversation session"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="chat_sessions")
    title = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_message_at = models.DateTimeField(blank=True, null=True)
    
    class Meta:
        db_table = "chat_sessions"
        ordering = ["-last_message_at"]


class ChatMessage(models.Model):
    """Individual chat message"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name="messages")
    role = models.CharField(max_length=10)
    content = models.TextField()
    model_used = models.CharField(max_length=100, blank=True, null=True)
    prompt_tokens = models.IntegerField(blank=True, null=True)
    completion_tokens = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = "chat_messages"
        ordering = ["created_at"]
