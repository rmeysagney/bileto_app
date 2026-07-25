from django.urls import path
from .views import (
    CategoryListView,
    EventListCreateView,
    EventDetailView,
    EventJoinView,
    EventLeaveView,
    MyEventsView,
    FavoriteToggleView,
    MyFavoritesView,
    ReviewListCreateView
)

urlpatterns = [
    path('categories/', CategoryListView.as_view(), name='category_list'), # kategori listesi
    path('', EventListCreateView.as_view(), name='event_list_create'), # etkinlik listeleme
    path('<int:pk>/', EventDetailView.as_view(), name='event_detail'), # etkinlik detayı
    path('<int:pk>/join/', EventJoinView.as_view(), name='event_join'), # etkinliğe katıl
    path('<int:pk>/leave/', EventLeaveView.as_view(), name='event_leave'), # katılım iptal
    path('my-events/', MyEventsView.as_view(), name='my_events'), # katıldıklarım listesi
    path('<int:pk>/favorite/', FavoriteToggleView.as_view(), name='favorite_toggle'), # favori ekle
    path('favorites/', MyFavoritesView.as_view(), name='my_favorites'), # favorilerim listesi
    path('<int:event_id>/reviews/', ReviewListCreateView.as_view(), name='event_reviews'), # yorumlar listeleme / ekleme
]

