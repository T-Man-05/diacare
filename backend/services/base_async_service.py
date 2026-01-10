"""Async base service for outbound HTTP calls.

Use this for any integration with external services (microservices, AI
providers, etc.) in async/streaming endpoints.

- Uses httpx.AsyncClient (connection pooling)
- Provides a single place for timeouts, headers, retries, and error mapping

Important:
- This is safe to use from async Django views running under ASGI.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx


@dataclass(frozen=True)
class AsyncHTTPError(Exception):
    """Raised for outbound HTTP failures."""

    message: str
    status_code: int | None = None
    url: str | None = None


class BaseAsyncService:
    """Base class providing a shared AsyncClient and JSON helpers."""

    _client: httpx.AsyncClient | None = None

    @classmethod
    def _get_timeout(cls) -> httpx.Timeout:
        # Keep per-phase values explicit.
        return httpx.Timeout(connect=3.0, read=10.0, write=10.0, pool=3.0)

    @classmethod
    def client(cls) -> httpx.AsyncClient:
        """Get or create the shared AsyncClient."""

        if cls._client is None:
            cls._client = httpx.AsyncClient(timeout=cls._get_timeout())
        return cls._client

    @classmethod
    async def aclose_client(cls) -> None:
        """Close the shared client (useful in tests/shutdown hooks)."""

        if cls._client is not None:
            await cls._client.aclose()
            cls._client = None

    async def request_json(
        self,
        method: str,
        url: str,
        *,
        headers: dict[str, str] | None = None,
        params: dict[str, Any] | None = None,
        json: Any | None = None,
    ) -> Any:
        """Perform an HTTP request and return parsed JSON.

        Raises AsyncHTTPError for network errors or non-2xx.
        """

        try:
            resp = await self.client().request(
                method,
                url,
                headers=headers,
                params=params,
                json=json,
            )
        except (httpx.ConnectError, httpx.ReadTimeout, httpx.ConnectTimeout) as e:
            raise AsyncHTTPError(message="Upstream service unavailable", url=url) from e
        except httpx.HTTPError as e:
            raise AsyncHTTPError(message="HTTP client error", url=url) from e

        if resp.status_code >= 400:
            raise AsyncHTTPError(
                message=f"Upstream returned {resp.status_code}",
                status_code=resp.status_code,
                url=str(resp.request.url),
            )

        # If response isn't JSON, this will raise; callers can catch.
        return resp.json()
