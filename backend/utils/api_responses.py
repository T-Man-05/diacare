"""utils.api_responses

Small helpers for consistent API responses.

Only error responses are strictly standardized; success responses can vary.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

from django.conf import settings
from rest_framework.response import Response


def error_response(
    *,
    code: str,
    ui_message: str,
    status_code: int,
    exc: Optional[BaseException] = None,
    field_errors: Optional[Dict[str, list[str]]] = None,
    dev_message: Optional[str] = None,
) -> Response:
    """Return a standardized error response.

    `dev_message` is only included in DEBUG.
    """

    error: Dict[str, Any] = {
        "code": code,
        "ui_message": ui_message,
    }

    if field_errors:
        error["field_errors"] = field_errors

    if settings.DEBUG:
        dm = dev_message
        if dm is None and exc is not None:
            dm = f"{exc.__class__.__name__}: {exc}"
        if dm:
            error["dev_message"] = dm

    return Response({"success": False, "error": error}, status=status_code)
