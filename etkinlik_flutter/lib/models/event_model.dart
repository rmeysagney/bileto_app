import 'category_model.dart';
import 'user_model.dart';

class EventModel {
  final int id;
  final UserModel? organizer;
  final CategoryModel? category;
  final String title;
  final String description;
  final String? image;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String locationName;
  final String city;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final double price;
  final bool isFree;
  final int participantCount;
  final bool isFull;
  bool isJoined;
  bool isFavorited;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;

  EventModel({
    required this.id,
    this.organizer,
    this.category,
    required this.title,
    required this.description,
    this.image,
    required this.startDatetime,
    required this.endDatetime,
    required this.locationName,
    required this.city,
    this.latitude,
    this.longitude,
    required this.capacity,
    required this.price,
    required this.isFree,
    required this.participantCount,
    required this.isFull,
    required this.isJoined,
    required this.isFavorited,
    this.averageRating = 5.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  static String? _parseImageUrl(dynamic rawImage) {
    if (rawImage == null || rawImage.toString().isEmpty) return null;
    String img = rawImage.toString();

    // Enkodlanmış URL karakterlerini düzelt (%3A -> : , %2F -> /)
    img = img.replaceAll('%3A', ':').replaceAll('%2F', '/');
    img = img.replaceAll('https:/', 'https://').replaceAll('https:///', 'https://');
    img = img.replaceAll('http:/', 'http://').replaceAll('http:///', 'http://');

    if (img.contains('https://')) {
      return img.substring(img.indexOf('https://'));
    }
    if (img.contains('http://')) {
      final lastHttp = img.lastIndexOf('http://');
      if (lastHttp > 0) {
        return img.substring(lastHttp);
      }
      if (img.startsWith('http://')) {
        return img;
      }
    }

    if (!img.startsWith('/')) {
      img = '/$img';
    }
    return 'http://127.0.0.1:8000$img';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      organizer: json['organizer'] != null
          ? UserModel.fromJson(json['organizer'])
          : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: _parseImageUrl(json['image']),
      startDatetime: DateTime.parse(json['start_datetime']),
      endDatetime: DateTime.parse(json['end_datetime']),
      locationName: json['location_name'] ?? '',
      city: json['city'] ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      capacity: json['capacity'] ?? 0,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      isFree: json['is_free'] ?? true,
      participantCount: json['participant_count'] ?? 0,
      isFull: json['is_full'] ?? false,
      isJoined: json['is_joined'] ?? false,
      isFavorited: json['is_favorited'] ?? false,
      averageRating: json['average_rating'] != null ? (json['average_rating'] as num).toDouble() : 5.0,
      reviewCount: json['review_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
