"""User models for DiaCare API"""

from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils import timezone


class UserManager(BaseUserManager):
    """Custom user manager for email-based authentication."""
    
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("The Email field must be set")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")
        
        return self.create_user(email, password, **extra_fields)


class User(AbstractUser):
    """Custom User model - uses email for authentication"""
    
    username = models.CharField(max_length=150, blank=True, default='')
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255, blank=True, default='')
    profile_image_url = models.URLField(max_length=500, blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    gender = models.CharField(max_length=10, blank=True, null=True)
    height = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    weight = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]
    
    objects = UserManager()
    
    class Meta:
        db_table = "users"
    
    def __str__(self):
        return self.email


class DiabeticProfile(models.Model):
    """Diabetic profile settings"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="diabetic_profile")
    diabetic_type = models.CharField(max_length=20, default="Type 1")
    treatment_type = models.CharField(max_length=30, default="Insulin")
    min_glucose = models.IntegerField(default=70)
    max_glucose = models.IntegerField(default=180)
    diagnosis_date = models.DateField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = "diabetic_profiles"


class UserPreferences(models.Model):
    """User app preferences"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="preferences")
    theme = models.CharField(max_length=10, default="light")
    locale = models.CharField(max_length=5, default="en")
    units = models.CharField(max_length=10, default="mg/dL")
    notifications_enabled = models.BooleanField(default=True)
    biometric_enabled = models.BooleanField(default=False)
    onboarding_complete = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = "user_preferences"
