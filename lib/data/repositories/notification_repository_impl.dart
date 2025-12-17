import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<String?> _getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("typed_url");
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  @override
  Future<NotificationResponse> getUnreadNotifications(int page) async {
    try {
      final headers = await _getHeaders();
      final serverUrl = await _getServerUrl();
      
      if (serverUrl == null) {
        throw Exception('Server URL not found');
      }

      final uri = Uri.parse('$serverUrl${ApiConstants.notificationsListUnreadEndpoint}?page=$page');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return NotificationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timeout');
    } on SocketException {
      throw Exception('Connection error');
    } catch (e) {
      throw Exception('Error fetching notifications: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadNotificationsCount() async {
    try {
      final headers = await _getHeaders();
      final serverUrl = await _getServerUrl();
      
      if (serverUrl == null) {
        throw Exception('Server URL not found');
      }

      final uri = Uri.parse('$serverUrl${ApiConstants.notificationsListUnreadEndpoint}');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['count'] ?? 0;
      } else {
        throw Exception('Failed to get notifications count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting notifications count: ${e.toString()}');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final serverUrl = await _getServerUrl();
      
      if (serverUrl == null) {
        throw Exception('Server URL not found');
      }

      final uri = Uri.parse('$serverUrl${ApiConstants.notificationsBulkReadEndpoint}');
      final response = await http.post(uri, headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notifications as read: ${e.toString()}');
    }
  }

  @override
  Future<NotificationResponse> getAllNotifications() async {
    try {
      final headers = await _getHeaders();
      final serverUrl = await _getServerUrl();
      
      if (serverUrl == null) {
        throw Exception('Server URL not found');
      }

      final uri = Uri.parse('$serverUrl${ApiConstants.notificationsListAllEndpoint}');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return NotificationResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch all notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all notifications: ${e.toString()}');
    }
  }
}
