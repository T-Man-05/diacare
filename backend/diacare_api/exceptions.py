"""
=============================================================================
DiaCare API - Custom Exception Handler
=============================================================================

Provides a consistent error response format across the API.
All errors return a standardized JSON structure that the Flutter app expects.

Response Format:
{
    "success": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "Human readable message",
        "details": {} // Optional additional details
    }
}
=============================================================================
"""

from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404


# Error codes that match what the Flutter app expects
ERROR_CODES = {
    "AUTHENTICATION_FAILED": "Invalid credentials",
    "TOKEN_EXPIRED": "Authentication token has expired",
    "TOKEN_INVALID": "Invalid authentication token",
    "PERMISSION_DENIED": "You do not have permission to perform this action",
    "NOT_FOUND": "Resource not found",
    "VALIDATION_ERROR": "Invalid data provided",
    "DUPLICATE_ENTRY": "This record already exists",
    "SERVER_ERROR": "An internal server error occurred",
    "RATE_LIMITED": "Too many requests. Please try again later",
    "BAD_REQUEST": "Invalid request",
}


def custom_exception_handler(exc, context):
    """
    Custom exception handler that returns consistent error responses.
    
    This handler wraps DRF's default exception handler and formats the
    response to match the structure expected by the Flutter app.
    """
    # Call REST framework's default exception handler first
    response = exception_handler(exc, context)
    
    if response is not None:
        # Build standardized error response
        error_response = format_error_response(exc, response)
        response.data = error_response
        return response
    
    # Handle Django's native exceptions that DRF doesn't catch
    if isinstance(exc, DjangoValidationError):
        return Response(
            {
                "success": False,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": str(exc.message) if hasattr(exc, 'message') else str(exc),
                    "details": exc.message_dict if hasattr(exc, 'message_dict') else {},
                }
            },
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if isinstance(exc, Http404):
        return Response(
            {
                "success": False,
                "error": {
                    "code": "NOT_FOUND",
                    "message": "The requested resource was not found",
                    "details": {},
                }
            },
            status=status.HTTP_404_NOT_FOUND
        )
    
    # For any unhandled exception, return a generic server error
    return Response(
        {
            "success": False,
            "error": {
                "code": "SERVER_ERROR",
                "message": "An unexpected error occurred. Please try again later.",
                "details": {},
            }
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )


def format_error_response(exc, response):
    """
    Format the error response based on the exception type.
    """
    from rest_framework.exceptions import (
        AuthenticationFailed,
        NotAuthenticated,
        PermissionDenied,
        NotFound,
        ValidationError,
        Throttled,
    )
    
    error_code = "SERVER_ERROR"
    error_message = "An error occurred"
    error_details = {}
    
    # Determine error code based on exception type
    if isinstance(exc, (AuthenticationFailed, NotAuthenticated)):
        error_code = "AUTHENTICATION_FAILED"
        error_message = str(exc.detail) if hasattr(exc, 'detail') else "Authentication failed"
        
    elif isinstance(exc, PermissionDenied):
        error_code = "PERMISSION_DENIED"
        error_message = str(exc.detail) if hasattr(exc, 'detail') else "Permission denied"
        
    elif isinstance(exc, NotFound):
        error_code = "NOT_FOUND"
        error_message = str(exc.detail) if hasattr(exc, 'detail') else "Resource not found"
        
    elif isinstance(exc, ValidationError):
        error_code = "VALIDATION_ERROR"
        error_message = "Invalid data provided"
        # Include validation details
        if hasattr(exc, 'detail'):
            if isinstance(exc.detail, dict):
                error_details = exc.detail
            elif isinstance(exc.detail, list):
                error_details = {"errors": exc.detail}
            else:
                error_message = str(exc.detail)
                
    elif isinstance(exc, Throttled):
        error_code = "RATE_LIMITED"
        wait_seconds = exc.wait
        error_message = f"Request throttled. Please wait {int(wait_seconds)} seconds."
        error_details = {"wait_seconds": wait_seconds}
        
    else:
        # Generic error handling
        if hasattr(exc, 'detail'):
            if isinstance(exc.detail, str):
                error_message = exc.detail
            elif isinstance(exc.detail, dict):
                error_details = exc.detail
                error_message = error_details.pop('detail', 'An error occurred')
    
    return {
        "success": False,
        "error": {
            "code": error_code,
            "message": error_message,
            "details": error_details,
        }
    }


class APIException(Exception):
    """
    Base exception class for custom API exceptions.
    
    Usage:
        raise APIException("VALIDATION_ERROR", "Email is already registered")
    """
    
    def __init__(self, code: str, message: str, details: dict = None, status_code: int = 400):
        self.code = code
        self.message = message
        self.details = details or {}
        self.status_code = status_code
        super().__init__(message)
    
    def to_response(self):
        return Response(
            {
                "success": False,
                "error": {
                    "code": self.code,
                    "message": self.message,
                    "details": self.details,
                }
            },
            status=self.status_code
        )
