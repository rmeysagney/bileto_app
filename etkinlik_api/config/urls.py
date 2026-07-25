from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls), # admin paneli
    path('api/users/', include('users.urls')), # kullanıcı linkleri
    path('api/events/', include('events.urls')), # etkinlik linkleri
]

if settings.DEBUG: # resim yolları
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
