"""Async-friendly helpers for turning Django ORM objects into plain dict/list.

Django REST Framework serializers are synchronous. For async/streaming endpoints we
prefer returning simple dictionaries.

These helpers run synchronous conversions in a thread pool (via sync_to_async)
so they don't block the event loop.
"""

from __future__ import annotations

from typing import Any, Iterable, Mapping

from asgiref.sync import sync_to_async
from django.db.models import Model, QuerySet
from django.forms.models import model_to_dict


@sync_to_async
def model_to_dict_async(
    instance: Model,
    *,
    fields: Iterable[str] | None = None,
    exclude: Iterable[str] | None = None,
) -> dict[str, Any]:
    """Convert a Django model instance to a plain dict in a thread.

    Notes:
    - This uses django.forms.model_to_dict, so it won't automatically expand
      relations (FK/M2M) unless you include those fields and handle them.
    """

    return model_to_dict(instance, fields=fields, exclude=exclude)


@sync_to_async
def queryset_values_list_async(
    qs: QuerySet,
    *,
    fields: Iterable[str] | None = None,
) -> list[dict[str, Any]]:
    """Convert a queryset to a list[dict] using .values() in a thread."""

    if fields:
        return list(qs.values(*fields))
    return list(qs.values())


def ensure_json_safe(obj: Any) -> Any:
    """Best-effort conversion for common non-JSON types.

    This keeps streaming endpoints robust when encountering Decimal, date,
    datetime, UUID, etc.
    """

    # Avoid importing heavy modules at import time.
    from datetime import date, datetime
    from decimal import Decimal
    from uuid import UUID

    if obj is None:
        return None
    if isinstance(obj, (str, int, float, bool)):
        return obj
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, UUID):
        return str(obj)
    if isinstance(obj, Mapping):
        return {str(k): ensure_json_safe(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple, set)):
        return [ensure_json_safe(v) for v in obj]
    return str(obj)
