"""Admin configuration for Chat app"""

from django.contrib import admin
from .models import ChatSession, ChatMessage


class ChatMessageInline(admin.TabularInline):
    model = ChatMessage
    extra = 0
    readonly_fields = ["created_at"]
    fields = ["role", "content", "created_at"]


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    inlines = [ChatMessageInline]
    list_display = ["user", "title", "is_active", "last_message_at", "created_at"]
    list_filter = ["is_active", "created_at"]
    search_fields = ["user__email", "title"]
    ordering = ["-last_message_at"]


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ["session", "role", "model_used", "created_at"]
    list_filter = ["role", "model_used", "created_at"]
    search_fields = ["content"]
    ordering = ["-created_at"]
