import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/category_model.dart';

class ApiService {
  // iOS Simülatör / macOS veya Web için: http://127.0.0.1:8000
  // Android Emülatör için: http://10.0.2.2:8000
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- AUTH İŞLEMLERİ ---

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/users/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access']);
      return {'success': true, 'token': data['access']};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['detail'] ?? 'Giriş başarısız.'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String role,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
  }) async {
    final url = Uri.parse('$baseUrl/users/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
        'role': role,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'phone': phone ?? '',
        'bio': bio ?? '',
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      final errors = jsonDecode(response.body);
      String msg = 'Kayıt başarısız.';
      if (errors is Map && errors.isNotEmpty) {
        msg = errors.values.first is List
            ? errors.values.first[0]
            : errors.values.first.toString();
      }
      return {'success': false, 'message': msg};
    }
  }

  static Future<UserModel?> getProfile() async {
    final url = Uri.parse('$baseUrl/users/profile/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<Map<String, dynamic>> becomeOrganizer() async {
    final url = Uri.parse('$baseUrl/users/become-organizer/');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'user': UserModel.fromJson(data['user']),
        'message': data['message'],
      };
    } else {
      return {'success': false, 'message': 'Organizatör başvurusu tamamlanamadı.'};
    }
  }

  // --- KATEGORİ VE ETKİNLİK İŞLEMLERİ ---

  static Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('$baseUrl/events/categories/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<EventModel>> getEvents({
    String? search,
    int? categoryId,
    String? city,
    bool? isFree,
    bool? upcoming,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null) queryParams['category'] = categoryId.toString();
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (isFree != null) queryParams['is_free'] = isFree.toString();
    if (upcoming == true) queryParams['upcoming'] = 'true';

    final uri = Uri.parse('$baseUrl/events/').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => EventModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<EventModel?> getEventDetail(int id) async {
    final url = Uri.parse('$baseUrl/events/$id/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  static Future<Map<String, dynamic>> joinEvent(int eventId, {int quantity = 1}) async {
    final url = Uri.parse('$baseUrl/events/$eventId/join/');
    final headers = await _getHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'quantity': quantity}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['error'] ?? 'İşlem başarısız.'};
    }
  }

  static Future<Map<String, dynamic>> leaveEvent(int eventId) async {
    final url = Uri.parse('$baseUrl/events/$eventId/leave/');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['error'] ?? 'İşlem başarısız.'};
    }
  }

  static Future<Map<String, dynamic>> toggleFavorite(int eventId) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite/');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'is_favorited': data['is_favorited']};
    }
    return {'success': false};
  }

  static Future<List<EventModel>> getMyEvents() async {
    final url = Uri.parse('$baseUrl/events/my-events/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => EventModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<EventModel>> getMyFavorites() async {
    final url = Uri.parse('$baseUrl/events/favorites/');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final List<EventModel> list = [];
      for (var item in data) {
        if (item is Map && item['event'] != null) {
          list.add(EventModel.fromJson(item['event']));
        }
      }
      return list;
    }
    return [];
  }

  static Future<bool> deleteEvent(int eventId) async {
    final url = Uri.parse('$baseUrl/events/$eventId/');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 204;
  }

  static Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    final url = Uri.parse('$baseUrl/events/');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(eventData));

    if (response.statusCode == 201) {
      return {'success': true, 'event': EventModel.fromJson(jsonDecode(response.body))};
    } else {
      return {'success': false, 'message': 'Etkinlik oluşturulamadı.'};
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    return _getHeaders();
  }

  static Future<bool> patchEvent(Uri url, Map<String, String> headers, Map<String, dynamic> body) async {
    final response = await http.patch(url, headers: headers, body: jsonEncode(body));
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getReviews(int eventId) async {
    final url = Uri.parse('$baseUrl/events/$eventId/reviews/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  static Future<bool> addReview(int eventId, int rating, String comment) async {
    final url = Uri.parse('$baseUrl/events/$eventId/reviews/');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return response.statusCode == 201;
  }
}
