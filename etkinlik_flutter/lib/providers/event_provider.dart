import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<EventModel> _events = [];
  List<EventModel> _myEvents = [];
  List<EventModel> _myFavorites = [];

  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedCity;
  bool? _selectedIsFree;

  List<CategoryModel> get categories => _categories;
  List<EventModel> get events => _events;
  List<EventModel> get myEvents => _myEvents;
  List<EventModel> get myFavorites => _myFavorites;
  bool get isLoading => _isLoading;

  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCity => _selectedCity;
  bool? get selectedIsFree => _selectedIsFree;
  String get searchQuery => _searchQuery;

  EventProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    await fetchCategories();
    await fetchEvents();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _categories = await ApiService.getCategories();
    notifyListeners();
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    notifyListeners();

    _events = await ApiService.getEvents(
      search: _searchQuery,
      categoryId: _selectedCategoryId,
      city: _selectedCity,
      isFree: _selectedIsFree,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyEvents() async {
    _myEvents = await ApiService.getMyEvents();
    notifyListeners();
  }

  Future<void> fetchMyFavorites() async {
    _myFavorites = await ApiService.getMyFavorites();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchEvents();
  }

  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null;
    } else {
      _selectedCategoryId = categoryId;
    }
    fetchEvents();
  }

  void setFilterCity(String? city) {
    _selectedCity = city;
    fetchEvents();
  }

  void setFilterIsFree(bool? isFree) {
    _selectedIsFree = isFree;
    fetchEvents();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedCity = null;
    _selectedIsFree = null;
    fetchEvents();
  }

  Future<Map<String, dynamic>> joinEvent(EventModel event, {int quantity = 1}) async {
    final result = await ApiService.joinEvent(event.id, quantity: quantity);
    if (result['success'] == true) {
      event.isJoined = true;
      await fetchEvents();
      await fetchMyEvents();
    }
    return result;
  }

  Future<Map<String, dynamic>> leaveEvent(EventModel event) async {
    final result = await ApiService.leaveEvent(event.id);
    if (result['success'] == true) {
      event.isJoined = false;
      await fetchEvents();
      await fetchMyEvents();
    }
    return result;
  }

  Future<void> toggleFavorite(EventModel event) async {
    final result = await ApiService.toggleFavorite(event.id);
    if (result['success'] == true) {
      event.isFavorited = result['is_favorited'];
      notifyListeners();
      await fetchMyFavorites();
    }
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.createEvent(eventData);
    if (result['success'] == true) {
      await fetchEvents();
      await fetchMyEvents();
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }
}
