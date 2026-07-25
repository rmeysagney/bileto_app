from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    UserProfileUpdateSerializer
)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,) # herkes kaydolabilir
    serializer_class = RegisterSerializer


class UserProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = (permissions.IsAuthenticated,) # profil görüntüleme/güncelleme

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UserProfileUpdateSerializer
        return UserSerializer


class BecomeOrganizerView(APIView): # organizatör olma başvurusu
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        user = request.user
        user.role = 'organizer'
        user.save()
        return Response({
            "message": "Tebrikler! Hesabınız Organizatör statüsüne yükseltildi.",
            "user": UserSerializer(user).data
        }, status=status.HTTP_200_OK)
