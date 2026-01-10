"""Async + NDJSON streaming endpoints for aggregation screens.

Why separate endpoints?
- The existing BFF endpoints return a single JSON blob.
- Streaming endpoints progressively emit sections so the Android UI can render
  immediately.

NDJSON format:
Each line is a standalone JSON object.
Example:
  {"type": "user_profile", "data": {...}}
  {"type": "health_cards", "data": {...}}
  {"type": "feed", "error": "Service unavailable", "data": []}

Important deployment note:
- True parallelism requires running Django under ASGI (uvicorn/daphne).
- Under WSGI, async views are executed in a compatibility layer and will not
  achieve the same concurrency.
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
from repositories.glucose_repository import GlucoseRepository
from repositories.health_card_repository import HealthCardRepository
from repositories.reminder_repository import ReminderRepository
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


async def _fetch_user_profile(user_id: int) -> dict[str, Any]:
    try:
        user = await User.objects.select_related("diabetic_profile").aget(id=user_id)
        diabetic = getattr(user, "diabetic_profile", None)
        return {
            "type": "user_profile",
            "data": {
                "id": user.id,
                "full_name": user.full_name,
                "email": user.email,
                "profile_image_url": user.profile_image_url,
                "diabetic_profile": {
                    "min_glucose": getattr(diabetic, "min_glucose", 70),
                    "max_glucose": getattr(diabetic, "max_glucose", 180),
                },
            },
        }
    except Exception as e:
        return {
            "type": "user_profile",
            "error": "Service unavailable",
            "data": {},
            "dev_message": f"{e.__class__.__name__}: {e}",
        }


async def _fetch_next_reminder(user_id: int) -> dict[str, Any]:
    try:
        reminder = await sync_to_async(ReminderRepository.get_next_upcoming_reminder)(user_id)
        if not reminder:
            return {"type": "next_reminder", "data": None}

        return {
            "type": "next_reminder",
            "data": {
                "id": str(reminder.id),
                "title": reminder.title,
                "scheduled_time": reminder.scheduled_time,
                "reminder_type": reminder.reminder_type,
                "status": reminder.status,
                "is_enabled": reminder.is_enabled,
            },
        }
    except Exception as e:
        return {"type": "next_reminder", "error": "Service unavailable", "data": None, "dev_message": f"{e}"}


async def _fetch_health_cards(user_id: int) -> dict[str, Any]:
    try:
        cards = await sync_to_async(HealthCardRepository.get_today_cards)(user_id)
        result: dict[str, Any] = {}
        for card in cards:
            result[card.card_type] = {
                "value": float(card.value),
                "unit": card.unit,
                "recorded_date": card.recorded_date,
            }

        # Ensure common cards exist.
        for card_type in ["water", "pills", "activity", "weight"]:
            if card_type not in result:
                card = await sync_to_async(HealthCardRepository.get_or_create_card)(user_id, card_type)
                result[card_type] = {
                    "value": float(card.value),
                    "unit": card.unit,
                    "recorded_date": card.recorded_date,
                }

        return {"type": "health_cards", "data": result}
    except Exception as e:
        return {"type": "health_cards", "error": "Service unavailable", "data": {}, "dev_message": f"{e}"}


async def _fetch_glucose_latest(user_id: int, profile_task: "asyncio.Task[dict[str, Any]]") -> dict[str, Any]:
    try:
        profile_chunk = await profile_task
        min_g = (profile_chunk.get("data") or {}).get("diabetic_profile", {}).get("min_glucose", 70)
        max_g = (profile_chunk.get("data") or {}).get("diabetic_profile", {}).get("max_glucose", 180)

        latest_reading = await sync_to_async(lambda: GlucoseRepository.get_today_readings(user_id).first())()
        if not latest_reading:
            return {"type": "glucose_latest", "data": None}

        value = float(latest_reading.value)
        if value < min_g:
            status_str = "low"
        elif value > max_g:
            status_str = "high"
        else:
            status_str = "normal"

        return {
            "type": "glucose_latest",
            "data": {
                "value": value,
                "unit": latest_reading.unit,
                "status": status_str,
                "reading_type": latest_reading.reading_type,
                "recorded_at": latest_reading.recorded_at,
            },
        }
    except Exception as e:
        return {"type": "glucose_latest", "error": "Service unavailable", "data": None, "dev_message": f"{e}"}


async def _fetch_glucose_trend(user_id: int) -> dict[str, Any]:
    try:
        readings = await sync_to_async(GlucoseRepository.get_user_readings)(user_id, 7)
        trend_data = [
            {
                "id": str(r.id),
                "value": float(r.value),
                "recorded_at": r.recorded_at,
                "reading_type": r.reading_type,
            }
            for r in readings
        ]
        return {"type": "glucose_trend", "data": trend_data}
    except Exception as e:
        return {"type": "glucose_trend", "error": "Service unavailable", "data": [], "dev_message": f"{e}"}


async def _fetch_glucose_stats_and_range(
    user_id: int,
    profile_task: "asyncio.Task[dict[str, Any]]",
) -> dict[str, Any]:
    try:
        profile_chunk = await profile_task
        min_g = (profile_chunk.get("data") or {}).get("diabetic_profile", {}).get("min_glucose", 70)
        max_g = (profile_chunk.get("data") or {}).get("diabetic_profile", {}).get("max_glucose", 180)

        stats = await sync_to_async(GlucoseRepository.get_statistics)(user_id, days=7)
        range_analysis = await sync_to_async(GlucoseRepository.get_range_analysis)(user_id, min_g, max_g, days=7)

        glucose_stats = {
            "average": round(float(stats["average"]), 1) if stats.get("average") else 0.0,
            "min": float(stats["min"]) if stats.get("min") else 0.0,
            "max": float(stats["max"]) if stats.get("max") else 0.0,
            "readings_count": stats.get("count", 0),
        }

        return {
            "type": "glucose_stats",
            "data": {
                "stats": glucose_stats,
                "range_analysis": range_analysis,
                "target_range": {"min": min_g, "max": max_g},
            },
        }
    except Exception as e:
        return {
            "type": "glucose_stats",
            "error": "Service unavailable",
            "data": {"stats": {}, "range_analysis": {}, "target_range": {}},
            "dev_message": f"{e}",
        }


async def dashboard_stream_generator(user_id: int) -> AsyncIterator[bytes]:
    """Yield dashboard chunks in NDJSON as soon as each finishes."""

    yield _ndjson_line({"type": "stream_start", "data": {"timestamp": timezone.now()}})

    profile_task: asyncio.Task[dict[str, Any]] = asyncio.create_task(_fetch_user_profile(user_id))

    tasks: list[asyncio.Task[dict[str, Any]]] = [
        profile_task,
        asyncio.create_task(_fetch_next_reminder(user_id)),
        asyncio.create_task(_fetch_health_cards(user_id)),
        asyncio.create_task(_fetch_glucose_latest(user_id, profile_task)),
        asyncio.create_task(_fetch_glucose_trend(user_id)),
        asyncio.create_task(_fetch_glucose_stats_and_range(user_id, profile_task)),
    ]

    for fut in asyncio.as_completed(tasks):
        chunk = await fut
        yield _ndjson_line(chunk)

    yield _ndjson_line({"type": "stream_end", "data": {"timestamp": timezone.now()}})


async def dashboard_stream_view(request):
    """GET /api/v1/health/dashboard/stream/ (NDJSON streaming)."""

    try:
        auth = await authenticate_request_async(request)
    except AuthenticationFailed:
        return _json_error(
            code="not_authenticated",
            ui_message="Your session has expired. Please log in again to continue.",
            http_status=status.HTTP_401_UNAUTHORIZED,
        )

    response = StreamingHttpResponse(
        dashboard_stream_generator(auth.user.id),
        content_type="application/x-ndjson",
    )
    response["Cache-Control"] = "no-cache"
    return response
