from rest_framework import generics, permissions, status, filters
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied, ValidationError
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend

from .models import Category, Event, Participation, Favorite, Review
from .serializers import (
    CategorySerializer,
    EventSerializer,
    ParticipationSerializer,
    FavoriteSerializer,
    ReviewSerializer
)



class CategoryListView(generics.ListAPIView): # kategori listesi
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = (permissions.AllowAny,)


class EventListCreateView(generics.ListCreateAPIView): # etkinlik listeleme
    serializer_class = EventSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'city', 'is_free']
    search_fields = ['title', 'description', 'location_name', 'city']
    ordering_fields = ['start_datetime', 'price', 'created_at']

    def get_queryset(self):
        queryset = Event.objects.all()
        upcoming = self.request.query_params.get('upcoming', None) # yaklaşan etkinlikler
        if upcoming == 'true':
            queryset = queryset.filter(start_datetime__gte=timezone.now())
        return queryset

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def perform_create(self, serializer): # organizatör ekler
        if not self.request.user.is_organizer:
            raise PermissionDenied("Sadece Organizatör rolündeki kullanıcılar etkinlik oluşturabilir.")
        serializer.save(organizer=self.request.user)


class EventDetailView(generics.RetrieveUpdateDestroyAPIView): # etkinlik detayı
    queryset = Event.objects.all()
    serializer_class = EventSerializer

    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def perform_update(self, serializer):
        if self.get_object().organizer != self.request.user and not self.request.user.is_superuser:
            raise PermissionDenied("Sadece kendi etkinliğinizi veya Admin olarak düzenleyebilirsiniz.")
        serializer.save()

    def perform_destroy(self, instance):
        if instance.organizer != self.request.user and not self.request.user.is_superuser:
            raise PermissionDenied("Sadece kendi etkinliğinizi veya Admin olarak silebilirsiniz.")
        instance.delete()


class EventJoinView(APIView): # etkinliğe katıl
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, pk):
        try:
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return Response({"error": "Etkinlik bulunamadı."}, status=status.HTTP_404_NOT_FOUND)

        try:
            quantity = int(request.data.get('quantity', 1))
        except (ValueError, TypeError):
            quantity = 1

        if quantity < 1 or quantity > 3:
            return Response({"error": "Bir işlemde en fazla 3 bilet alınabilir."}, status=status.HTTP_400_BAD_REQUEST)

        # Kontenjan kontrolü
        if event.capacity > 0 and (event.participant_count + quantity) > event.capacity:
            remaining = max(0, event.capacity - event.participant_count)
            return Response({"error": f"Yeterli kontenjan bulunmamaktadır. Kalan bilet: {remaining} adet."}, status=status.HTTP_400_BAD_REQUEST)

        participation, created = Participation.objects.get_or_create(
            user=request.user,
            event=event,
            defaults={'status': 'active', 'quantity': quantity}
        )

        if not created:
            participation.status = 'active'
            participation.quantity = quantity
            participation.save()

        return Response({"message": f"{quantity} adet bilet başarıyla alındı.", "quantity": quantity}, status=status.HTTP_200_OK)


class EventLeaveView(APIView): # katılım iptal
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, pk):
        try:
            participation = Participation.objects.get(user=request.user, event_id=pk, status='active')
            participation.status = 'cancelled'
            participation.save()
            return Response({"message": "Etkinlik katılımınız iptal edildi."}, status=status.HTTP_200_OK)
        except Participation.DoesNotExist:
            return Response({"error": "Aktif bir katılımınız bulunamadı."}, status=status.HTTP_400_BAD_REQUEST)


class MyEventsView(generics.ListAPIView): # katıldıklarım listesi
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = EventSerializer

    def get_queryset(self): # hem katılımcı hem organizatör katıldığı etkinlikleri görür
        user = self.request.user
        active_participations = Participation.objects.filter(user=user, status='active').values_list('event_id', flat=True)
        return Event.objects.filter(id__in=active_participations)


class FavoriteToggleView(APIView): # favori ekle
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, pk):
        try:
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return Response({"error": "Etkinlik bulunamadı."}, status=status.HTTP_404_NOT_FOUND)

        favorite = Favorite.objects.filter(user=request.user, event=event).first()
        if favorite:
            favorite.delete()
            return Response({"is_favorited": False, "message": "Favorilerden çıkarıldı."}, status=status.HTTP_200_OK)
        else:
            Favorite.objects.create(user=request.user, event=event)
            return Response({"is_favorited": True, "message": "Favorilere eklendi."}, status=status.HTTP_200_OK)


class MyFavoritesView(generics.ListAPIView): # favorilerim listesi
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = FavoriteSerializer

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user)


class ReviewListCreateView(generics.ListCreateAPIView): # yorum ve puan listesi / ekleme
    serializer_class = ReviewSerializer

    def get_permissions(self):
        if self.request.method == 'POST':
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def get_queryset(self):
        event_id = self.kwargs.get('event_id')
        return Review.objects.filter(event_id=event_id)

    def perform_create(self, serializer):
        event_id = self.kwargs.get('event_id')
        try:
            event = Event.objects.get(pk=event_id)
        except Event.DoesNotExist:
            raise ValidationError("Etkinlik bulunamadı.")
        serializer.save(user=self.request.user, event=event)

