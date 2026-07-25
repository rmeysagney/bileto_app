from rest_framework import serializers
from django.contrib.auth import get_user_model

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    joined_events_count = serializers.SerializerMethodField()
    organized_events_count = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'phone', 'profile_picture', 'bio',
            'is_organizer', 'is_participant', 'is_superuser', 'is_staff',
            'joined_events_count', 'organized_events_count',
            'date_joined'
        ]
        read_only_fields = ['id', 'date_joined', 'is_organizer', 'is_participant', 'is_superuser', 'is_staff']

    def get_joined_events_count(self, obj):
        return obj.participations.filter(status='active').count()

    def get_organized_events_count(self, obj):
        return obj.organized_events.count()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'role', 'phone', 'bio'
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Şifreler eşleşmiyor."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'phone', 'profile_picture', 'bio']
