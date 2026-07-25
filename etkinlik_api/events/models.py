from django.db import models
from django.conf import settings


class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)#filtreleme için kolaylık
    icon = models.CharField(max_length=50, blank=True, null=True)


    def __str__(self):
        return self.name

class Event(models.Model):
    organizer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete = models.CASCADE,
        related_name = 'organized_events'
    )
    category = models.ForeignKey(Category,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='events'
    )
    title = models.CharField(max_length=200)
    description = models.TextField()
    image = models.ImageField(upload_to='event_images/', blank=True, null=True)
    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    location_name = models.CharField(max_length=255)
    city = models.CharField(max_length=100)
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)#konumu iğnelemek
    capacity = models.PositiveIntegerField(default=0, help_text="0 sınırsız demektir")
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    is_free = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-start_datetime']


    @property
    def participant_count(self):
        from django.db.models import Sum
        total = self.participations.filter(status='active').aggregate(Sum('quantity'))['quantity__sum']
        return total or 0

    @property
    def is_full(self):
        if self.capacity == 0:
            return False
        return self.participant_count >= self.capacity

    @property
    def average_rating(self):
        reviews = self.reviews.all()
        if not reviews.exists():
            return 5.0
        return round(sum(r.rating for r in reviews) / len(reviews), 1)

    @property
    def review_count(self):
        return self.reviews.count()

    def __str__(self):
        return self.title


class Participation(models.Model):
    STATUS_CHOICES = (
        ('active', 'Aktif'),
        ('cancelled', 'İptal'),
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='participations'
    )
    event = models.ForeignKey(
        Event,
        on_delete=models.CASCADE,
        related_name='participations'
    )
    quantity = models.PositiveIntegerField(default=1)
    registered_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')

    class Meta:
        unique_together = ('user', 'event')

    def __str__(self):
        return f"{self.user.username} -> {self.event.title} ({self.status})"


class Favorite(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='favorites'
    )
    event = models.ForeignKey(
        Event,
        on_delete=models.CASCADE,
        related_name='favorited_by'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'event')

    def __str__(self):
        return f"{self.user.username} favoriledi: {self.event.title}"


class Review(models.Model):
    event = models.ForeignKey(
        Event,
        on_delete=models.CASCADE,
        related_name='reviews'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reviews'
    )
    rating = models.PositiveSmallIntegerField(default=5)
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} -> {self.event.title} ({self.rating}★)"

