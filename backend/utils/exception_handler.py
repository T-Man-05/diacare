"""utils.exception_handler

Global Django REST Framework exception handling.

Goal: return consistent, user-friendly errors and hide raw stack traces/SQL.

Standard response schema:
{
  "success": false,
  "error": {
    "code": "specific_error_code",
    "ui_message": "Human friendly message",
    "dev_message": "Internal/debug message (optional)",
    "field_errors": {"field": ["msg"]}
  }
}

Notes:
- `dev_message` is only included when `settings.DEBUG` is True.
- `field_errors` is included for validation-type errors.
"""

from __future__ import annotations

import re
import socket
from typing import Any, Dict, Optional

from django.conf import settings
from django.core.exceptions import ObjectDoesNotExist, ValidationError as DjangoValidationError
from django.db import IntegrityError
from django.http import Http404
from rest_framework import status
from rest_framework.exceptions import (
    APIException as DRFAPIException,
    AuthenticationFailed,
    NotAuthenticated,
    PermissionDenied,
    Throttled,
    ValidationError,
)
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler


def custom_exception_handler(exc: Exception, context: Dict[str, Any]) -> Response:
    """Catch *all* exceptions and return standardized error JSON."""

    # 1) Let DRF handle known exceptions first (it sets proper status codes).
    response = drf_exception_handler(exc, context)
    if response is not None:
        return _format_drf_exception(exc, response)

    # 2) Django / DB exceptions not handled by DRF.
    if isinstance(exc, Http404) or isinstance(exc, ObjectDoesNotExist):
        return _error_response(
            http_status=status.HTTP_404_NOT_FOUND,
            code="not_found",
            ui_message=(
                "We couldn't find the information you were looking for. "
                "It may have been deleted."
            ),
            dev_message=_dev_message(exc),
        )

    if isinstance(exc, DjangoValidationError):
        field_errors = _coerce_field_errors(getattr(exc, "message_dict", None))
        return _error_response(
            http_status=status.HTTP_400_BAD_REQUEST,
            code="validation_error",
            ui_message=(
                "Some information seems to be missing or incorrect. "
                "Please check the highlighted fields."
            ),
            dev_message=_dev_message(exc),
            field_errors=field_errors,
        )

    if isinstance(exc, IntegrityError):
        return _handle_integrity_error(exc)

    if _is_timeout(exc):
        return _error_response(
            http_status=status.HTTP_504_GATEWAY_TIMEOUT,
            code="timeout",
            ui_message="We couldn't load your data in time. Please try refreshing.",
            dev_message=_dev_message(exc),
        )

    if _is_connection_problem(exc):
        return _error_response(
            http_status=status.HTTP_503_SERVICE_UNAVAILABLE,
            code="service_unavailable",
            ui_message=(
                "We're having trouble connecting to the server right now. "
                "We are working on fixing it."
            ),
            dev_message=_dev_message(exc),
        )

    # 3) Fallback: generic 500.
    return _error_response(
        http_status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        code="server_error",
        ui_message=(
            "We're having trouble connecting to the server right now. "
            "We are working on fixing it."
        ),
        dev_message=_dev_message(exc),
    )


def _format_drf_exception(exc: Exception, response: Response) -> Response:
    """Convert DRF's default error shapes into our standardized schema."""
    http_status = response.status_code

    # Defaults
    code = "bad_request" if 400 <= http_status < 500 else "server_error"
    ui_message = "Something went wrong. Please try again."
    field_errors: Optional[Dict[str, list[str]]] = None

    # Common DRF auth/permission cases.
    if isinstance(exc, AuthenticationFailed):
        code = "auth_invalid_credentials"
        ui_message = "The email or password you entered is incorrect. Please try again."

    elif isinstance(exc, NotAuthenticated):
        code = "auth_not_authenticated"
        ui_message = "Your session has expired. Please log in again to continue."

    elif isinstance(exc, PermissionDenied):
        code = "auth_permission_denied"
        ui_message = "You don't have permission to perform this action."

    elif isinstance(exc, Throttled):
        code = "rate_limited"
        ui_message = "Too many requests. Please try again later."

    elif isinstance(exc, ValidationError) or http_status == status.HTTP_400_BAD_REQUEST:
        code = "validation_error"
        ui_message = (
            "Some information seems to be missing or incorrect. "
            "Please check the highlighted fields."
        )
        field_errors = _extract_field_errors_from_response_data(response.data)

    elif http_status == status.HTTP_404_NOT_FOUND:
        code = "not_found"
        ui_message = (
            "We couldn't find the information you were looking for. "
            "It may have been deleted."
        )

    elif http_status in (status.HTTP_500_INTERNAL_SERVER_ERROR, status.HTTP_503_SERVICE_UNAVAILABLE):
        code = "service_unavailable"
        ui_message = (
            "We're having trouble connecting to the server right now. "
            "We are working on fixing it."
        )

    # If the response includes a `detail` string, treat it as developer-only.
    dev = _dev_message(exc)

    response.data = {
        "success": False,
        "error": {
            "code": code,
            "ui_message": ui_message,
            **({"dev_message": dev} if dev is not None else {}),
            **({"field_errors": field_errors} if field_errors else {}),
        },
    }

    return response


def _handle_integrity_error(exc: IntegrityError) -> Response:
    message = str(exc)

    # Default: generic conflict
    code = "conflict"
    ui_message = "This information conflicts with an existing record. Please review and try again."
    field_errors: Optional[Dict[str, list[str]]] = None

    # Postgres: duplicate key value violates unique constraint "users_user_email_key"
    # SQLite: UNIQUE constraint failed: users_user.email
    lower = message.lower()

    if "unique" in lower or "duplicate" in lower:
        code = "conflict_duplicate"
        # Try to detect the affected field.
        if "email" in lower:
            ui_message = "This email address is already registered. Please log in or use a different email."
            field_errors = {"email": ["This email address is already registered."]}
        elif "username" in lower:
            ui_message = "This username is already taken. Please choose a different one."
            field_errors = {"username": ["This username is already taken."]}
        else:
            ui_message = "This value already exists. Please use a different one."

    return _error_response(
        http_status=status.HTTP_409_CONFLICT,
        code=code,
        ui_message=ui_message,
        dev_message=_dev_message(exc),
        field_errors=field_errors,
    )


def _error_response(
    *,
    http_status: int,
    code: str,
    ui_message: str,
    dev_message: Optional[str] = None,
    field_errors: Optional[Dict[str, list[str]]] = None,
) -> Response:
    payload: Dict[str, Any] = {
        "success": False,
        "error": {
            "code": code,
            "ui_message": ui_message,
        },
    }

    if dev_message is not None:
        payload["error"]["dev_message"] = dev_message

    if field_errors:
        payload["error"]["field_errors"] = field_errors

    return Response(payload, status=http_status)


def _dev_message(exc: Exception) -> Optional[str]:
    if not settings.DEBUG:
        return None
    return f"{exc.__class__.__name__}: {exc}"


def _extract_field_errors_from_response_data(data: Any) -> Optional[Dict[str, list[str]]]:
    """Try to normalize DRF's error details into `field_errors` dict."""

    if not data:
        return None

    # DRF ValidationError often returns: {"email": ["..."]}
    if isinstance(data, dict):
        # If the error is a single non-field message ("detail"), don't treat as field error.
        if set(data.keys()) == {"detail"}:
            return None

        out: Dict[str, list[str]] = {}
        for k, v in data.items():
            if isinstance(v, list):
                out[k] = [str(x) for x in v]
            else:
                out[k] = [str(v)]
        return out or None

    # Could be list of messages
    if isinstance(data, list):
        return {"non_field_errors": [str(x) for x in data]}

    return None


def _coerce_field_errors(raw: Any) -> Optional[Dict[str, list[str]]]:
    if raw is None:
        return None
    if isinstance(raw, dict):
        out: Dict[str, list[str]] = {}
        for k, v in raw.items():
            if isinstance(v, (list, tuple)):
                out[k] = [str(x) for x in v]
            else:
                out[k] = [str(v)]
        return out or None
    return {"non_field_errors": [str(raw)]}


def _is_timeout(exc: Exception) -> bool:
    # TimeoutError, socket.timeout, or wrapped timeout messages.
    if isinstance(exc, TimeoutError):
        return True
    if isinstance(exc, socket.timeout):
        return True
    msg = str(exc).lower()
    return bool(re.search(r"timed?\s*out|timeout", msg))


def _is_connection_problem(exc: Exception) -> bool:
    # A very defensive check: connection reset, refused, DNS, etc.
    if isinstance(exc, (ConnectionError, OSError)):
        # Some OS errors are not network-related; keep it conservative.
        msg = str(exc).lower()
        return any(
            s in msg
            for s in (
                "connection refused",
                "connection reset",
                "network is unreachable",
                "name or service not known",
                "temporary failure",
                "nodename nor servname",
                "failed to establish",
            )
        )
    return False
