"""Async + NDJSON streaming endpoints for Users app (BFF style).

Currently used as examples for progressive loading on Android.
"""

from __future__ import annotations

import asyncio
import json
from typing import Any, AsyncIterator

from asgiref.sync import sync_to_async
from django.http import JsonResponse, StreamingHttpResponse
from django.utils import timezone
from rest_framework import status
from rest_framework.exceptions import AuthenticationFailed

from apps.users.models import User
from repositories.user_repository import DiabeticProfileRepository, UserPreferencesRepository
from utils.async_serialization import ensure_json_safe
from utils.jwt_auth import authenticate_request_async


def _ndjson_line(obj: dict[str, Any]) -> bytes:
    return (json.dumps(ensure_json_safe(obj), ensure_ascii=False) + "\n").encode("utf-8")


def _json_error(*, code: str, ui_message: str, http_status: int) -> JsonResponse:
    return JsonResponse(
        {
            "success": False,
            "error": {"code": code, "ui_message": ui_message},
        },
        status=http_status,
    )


async def _fetch_profile(user_id: int) -> dict[str, Any]:
    try:
        user = await User.objects.aget(id=user_id)
        return {
            "type": "profile",
            "data": {
                "id": str(user.id),
                "email": user.email,
                "username": user.username or "",
                "full_name": user.full_name or "",
                "profile_image_url": user.profile_image_url or "",
                "date_of_birth": user.date_of_birth,
                "gender": user.gender or "",
                "height": user.height,
                "weight": user.weight,
            },
        }
    except Exception as e:
        return {"type": "profile", "error": "Service unavailable", "data": {}, "dev_message": f"{e}"}


async def _fetch_diabetic_profile(user_id: int) -> dict[str, Any]:
    try:
        repo = DiabeticProfileRepository()
        diabetic = await sync_to_async(repo.get_or_create_profile)(user_id)
        return {
            "type": "diabetic_profile",
            "data": {
                "diabetic_type": diabetic.diabetic_type,
                "treatment_type": diabetic.treatment_type,
                "min_glucose": diabetic.min_glucose,
                "max_glucose": diabetic.max_glucose,
                "diagnosis_date": diabetic.diagnosis_date,
            },
        }
    except Exception as e:
        return {
            "type": "diabetic_profile",
            "error": "Service unavailable",
            "data": {},
            "dev_message": f"{e}",
        }


async def _fetch_preferences(user_id: int) -> dict[str, Any]:
    try:
        repo = UserPreferencesRepository()
        prefs = await sync_to_async(repo.get_or_create_preferences)(user_id)
        return {
            "type": "preferences",
            "data": {
                "theme": prefs.theme,
                "locale": prefs.locale,
                "units": prefs.units,
                "notifications_enabled": prefs.notifications_enabled,
                "biometric_enabled": prefs.biometric_enabled,
                "onboarding_complete": prefs.onboarding_complete,
            },
        }
    except Exception as e:
        return {"type": "preferences", "error": "Service unavailable", "data": {}, "dev_message": f"{e}"}


async def settings_stream_generator(user_id: int) -> AsyncIterator[bytes]:
    yield _ndjson_line({"type": "stream_start", "data": {"timestamp": timezone.now()}})

    tasks: list[asyncio.Task[dict[str, Any]]] = [
        asyncio.create_task(_fetch_profile(user_id)),
        asyncio.create_task(_fetch_preferences(user_id)),
        asyncio.create_task(_fetch_diabetic_profile(user_id)),
    ]

    for fut in asyncio.as_completed(tasks):
        chunk = await fut
        yield _ndjson_line(chunk)

    yield _ndjson_line({"type": "stream_end", "data": {"timestamp": timezone.now()}})


async def settings_stream_view(request):
    """GET /api/v1/auth/settings/stream/ (NDJSON streaming)."""

    try:
        auth = await authenticate_request_async(request)
    except AuthenticationFailed:
        return _json_error(
            code="not_authenticated",
            ui_message="Your session has expired. Please log in again to continue.",
            http_status=status.HTTP_401_UNAUTHORIZED,
        )

    response = StreamingHttpResponse(
        settings_stream_generator(auth.user.id),
        content_type="application/x-ndjson",
    )
    response["Cache-Control"] = "no-cache"
    return response
