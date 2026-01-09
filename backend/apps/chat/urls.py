"""Chat app URL configuration"""

from django.urls import path
from . import views

urlpatterns = [
    # Chat endpoints
    path('', views.chat_send_message, name='chat-send-message'),
    path('history/', views.chat_get_history, name='chat-get-history'),
    path('sessions/', views.chat_get_sessions, name='chat-get-sessions'),
    path('sessions/<uuid:session_id>/', views.chat_delete_session, name='chat-delete-session'),
]
