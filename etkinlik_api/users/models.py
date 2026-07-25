from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser): #abstract user sayesinde
    #sistem kullanıcısı olduğunu anlar ize kullanıcı için gerekenleri otomatik verir
    ROLE_CHOICES = (
        ('participant', 'Katılımcı'),
        ('organizer', 'Organizatör'),
    )

    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='participant')
    phone = models.CharField(max_length=20, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    bio = models.TextField(blank=True, null=True)

    @property # ileride uzun uzun yazmayıp user.is_organizer şeklinde kullanmak için
    def is_organizer(self):
        return self.role == 'organizer'

    @property
    def is_participant(self):
        return self.role == 'participant'

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
