from rest_framework import serializers
from .models import Category, Event, Participation, Favorite, Review
from users.serializers import UserSerializer


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'icon']


class ReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Review
        fields = ['id', 'user', 'username', 'user_name', 'event', 'rating', 'comment', 'created_at']
        read_only_fields = ['id', 'user', 'event', 'created_at']


class EventSerializer(serializers.ModelSerializer):
    organizer = UserSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True,
        required=False,
        allow_null=True
    )
    is_joined = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    reviews = ReviewSerializer(many=True, read_only=True)

    class Meta:
        model = Event
        fields = [
            'id', 'organizer', 'category', 'category_id',
            'title', 'description', 'image',
            'start_datetime', 'end_datetime',
            'location_name', 'city', 'latitude', 'longitude',
            'capacity', 'price', 'is_free',
            'participant_count', 'is_full',
            'is_joined', 'is_favorited',
            'average_rating', 'review_count', 'reviews',
            'created_at'
        ]
        read_only_fields = ['id', 'organizer', 'created_at']

    def to_internal_value(self, data):
        # image string (URL) olarak gönderilirse ImageField doğrulamasının patlamasını önle
        data_copy = data.copy() if hasattr(data, 'copy') else dict(data)
        if 'image' in data_copy and isinstance(data_copy['image'], str):
            image_str = data_copy['image']
            if 'https://' in image_str or 'http://' in image_str:
                data_copy.pop('image')
        return super().to_internal_value(data_copy)

    def create(self, validated_data):
        image_str = self.initial_data.get('image')
        instance = super().create(validated_data)
        if isinstance(image_str, str) and ('https://' in image_str or 'http://' in image_str):
            if 'https://' in image_str:
                instance.image = image_str[image_str.index('https://'):]
            else:
                instance.image = image_str
            instance.save()
        return instance

    def update(self, instance, validated_data):
        image_str = self.initial_data.get('image')
        updated_instance = super().update(instance, validated_data)
        if isinstance(image_str, str) and ('https://' in image_str or 'http://' in image_str):
            if 'https://' in image_str:
                updated_instance.image = image_str[image_str.index('https://'):]
            else:
                updated_instance.image = image_str
            updated_instance.save()
        return updated_instance

    def get_is_joined(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.participations.filter(user=request.user, status='active').exists()
        return False

    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.favorited_by.filter(user=request.user).exists()
        return False


class ParticipationSerializer(serializers.ModelSerializer):
    event = EventSerializer(read_only=True)

    class Meta:
        model = Participation
        fields = ['id', 'user', 'event', 'registered_at', 'status']
        read_only_fields = ['id', 'user', 'registered_at']


class FavoriteSerializer(serializers.ModelSerializer):
    event = EventSerializer(read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'user', 'event', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']
