"""Admin configuration for Users app"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, DiabeticProfile, UserPreferences


class DiabeticProfileInline(admin.StackedInline):
    model = DiabeticProfile
    can_delete = False
    verbose_name_plural = "Diabetic Profile"


class UserPreferencesInline(admin.StackedInline):
    model = UserPreferences
    can_delete = False
    verbose_name_plural = "User Preferences"


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    inlines = [DiabeticProfileInline, UserPreferencesInline]
    list_display = ["email", "full_name", "is_staff", "is_active", "created_at"]
    list_filter = ["is_staff", "is_active", "created_at"]
    search_fields = ["email", "full_name"]
    ordering = ["-created_at"]
    
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        ("Personal Info", {"fields": ("full_name", "date_of_birth", "gender", "height", "weight", "profile_image_url")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("email", "full_name", "password1", "password2"),
        }),
    )
