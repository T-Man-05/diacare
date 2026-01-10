"""JWT authentication helpers for plain Django async views.

We use SimpleJWT's JWTAuthentication to authenticate requests without relying on
DRF's Request/permission wrappers.

This keeps streaming endpoints lightweight and compatible with
StreamingHttpResponse.
"""

from __future__ import annotations

from dataclasses import dataclass

from django.contrib.auth import get_user_model
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.settings import api_settings


@dataclass(frozen=True)
class AuthResult:
    user: object
    token: object


def authenticate_request(request) -> AuthResult:
    """Authenticate an incoming request using Authorization: Bearer <token>.

    Raises:
        AuthenticationFailed: if the header/token is missing or invalid.
    """

    auth = JWTAuthentication()
    result = auth.authenticate(request)
    if result is None:
        raise AuthenticationFailed("Authentication credentials were not provided.")
    user, token = result
    return AuthResult(user=user, token=token)


async def authenticate_request_async(request) -> AuthResult:
    """Async variant of authenticate_request.

    SimpleJWT's default authenticate() loads the User via the synchronous ORM,
    which raises SynchronousOnlyOperation inside async views.

    This implementation:
    - Parses the Authorization header
    - Validates the token
    - Loads the user via Django's async ORM (aget)
    """

    auth = JWTAuthentication()
    header = auth.get_header(request)
    if header is None:
        raise AuthenticationFailed("Authentication credentials were not provided.")

    raw_token = auth.get_raw_token(header)
    if raw_token is None:
        raise AuthenticationFailed("Invalid Authorization header.")

    validated_token = auth.get_validated_token(raw_token)

    user_id = validated_token.get(api_settings.USER_ID_CLAIM)
    if user_id is None:
        raise AuthenticationFailed("Token contained no recognizable user identification")

    User = get_user_model()
    try:
        user = await User.objects.aget(**{api_settings.USER_ID_FIELD: user_id})
    except User.DoesNotExist as e:
        raise AuthenticationFailed("User not found") from e

    if not getattr(user, "is_active", True):
        raise AuthenticationFailed("User is inactive")

    return AuthResult(user=user, token=validated_token)
