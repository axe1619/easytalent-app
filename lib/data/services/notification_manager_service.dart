import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/usecases/fetch_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_read_usecase.dart';
import 'notification_service.dart';
import 'local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import 'dart:convert';

class NotificationManagerService {
  final FetchNotificationsUseCase _fetchNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkAllReadUseCase _markAllReadUseCase;
  final LocalStorageService _localStorageService;

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Timer? _notificationTimer;
  int _currentPage = 1;
  bool _isFirstFetch = true;
  final Set<int> _seenNotificationIds = {};
  List<NotificationModel> _notifications = [];
  int _notificationsCount = 0;
  bool _isLoading = true;
  String? _employeeName;

  NotificationManagerService({
    required FetchNotificationsUseCase fetchNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkAllReadUseCase markAllReadUseCase,
    required LocalStorageService localStorageService,
  })  : _fetchNotificationsUseCase = fetchNotificationsUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _markAllReadUseCase = markAllReadUseCase,
        _localStorageService = localStorageService;

  List<NotificationModel> get notifications => _notifications;
  int get notificationsCount => _notificationsCount;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;

  Future<void> initialize() async {
    final isAuthenticated = await _localStorageService.isAuthenticated();
    if (isAuthenticated) {
      await _loadEmployeeName();
      await unreadNotificationsCount();
      startNotificationTimer();
    }
  }

  Future<void> _loadEmployeeName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _localStorageService.getToken();
      final typedServerUrl = prefs.getString('typed_url');
      final employeeId = prefs.getInt('employee_id');

      if (token == null || typedServerUrl == null || employeeId == null) {
        return;
      }

      final uri = Uri.parse(
        '$typedServerUrl${ApiConstants.employeeEndpoint}/$employeeId',
      );

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final firstName = data['employee_first_name'] ?? '';
        final lastName = data['employee_last_name'] ?? '';
        _employeeName = '$firstName $lastName'.trim();
      }
    } catch (e) {
      print('Error cargando nombre de empleado: $e');
    }
  }

  void startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final isAuthenticated = await _localStorageService.isAuthenticated();
      if (isAuthenticated) {
        await fetchNotifications();
        await unreadNotificationsCount();
      } else {
        timer.cancel();
        _notificationTimer = null;
      }
    });
  }

  void stopNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  Future<void> fetchNotifications() async {
    final isAuthenticated = await _localStorageService.isAuthenticated();
    if (!isAuthenticated) {
      return;
    }

    try {
      _isLoading = true;
      final response = await _fetchNotificationsUseCase.execute(_currentPage);

      final filteredNotifications = response.results
          .where((notification) => !notification.deleted)
          .toList();

      if (filteredNotifications.isNotEmpty) {
        final newNotificationIds = filteredNotifications
            .map((notification) => notification.id)
            .toList();

        final hasNewNotifications =
            newNotificationIds.any((id) => !_seenNotificationIds.contains(id));

        if (!_isFirstFetch && hasNewNotifications && filteredNotifications.isNotEmpty) {
          await NotificationService.showNotificationFromModel(
            filteredNotifications[0],
            _employeeName,
          );
        }

        _seenNotificationIds.addAll(newNotificationIds);
        _notifications = filteredNotifications;
        _notificationsCount = response.count;
        unreadCountNotifier.value = _notificationsCount;
        _isFirstFetch = false;
      }

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      print('Error fetching notifications: $e');
    }
  }

  Future<void> unreadNotificationsCount() async {
    final isAuthenticated = await _localStorageService.isAuthenticated();
    if (!isAuthenticated) {
      return;
    }

    try {
      _notificationsCount = await _getUnreadCountUseCase.execute();
      unreadCountNotifier.value = _notificationsCount;
      _isLoading = false;
    } catch (e) {
      print('Error getting unread count: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final isAuthenticated = await _localStorageService.isAuthenticated();
    if (!isAuthenticated) {
      return;
    }

    try {
      await _markAllReadUseCase.execute();
      _notifications.clear();
      await unreadNotificationsCount();
      await fetchNotifications();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  void setCurrentPage(int page) {
    _currentPage = page;
  }

  void setEmployeeName(String? name) {
    _employeeName = name;
  }

  void dispose() {
    stopNotificationTimer();
    unreadCountNotifier.dispose();
  }
}
