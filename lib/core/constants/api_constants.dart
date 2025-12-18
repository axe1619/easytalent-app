class ApiConstants {
  static const String baseUrl = 'https://www.easytalent.top';
  static const String loginEndpoint = '/api/auth/login/';
  static const String notificationsListUnreadEndpoint = '/api/notifications/notifications/list/unread';
  static const String notificationsListAllEndpoint = '/api/notifications/notifications/list/all';
  static const String notificationsBulkReadEndpoint = '/api/notifications/notifications/bulk-read/';
  static const String notificationsBulkDeleteEndpoint = '/api/notifications/notifications/bulk-delete/';
  static const String employeeEndpoint = '/api/employee/employees';
  
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String getNotificationsUnreadUrl(int page) => '$baseUrl$notificationsListUnreadEndpoint?page=$page';
  static String getNotificationsUnreadCountUrl() => '$baseUrl$notificationsListUnreadEndpoint';
  static String getNotificationsAllUrl() => '$baseUrl$notificationsListAllEndpoint';
  static String getNotificationsBulkReadUrl() => '$baseUrl$notificationsBulkReadEndpoint';
  static String getNotificationsBulkDeleteUrl() => '$baseUrl$notificationsBulkDeleteEndpoint';
  static String getNotificationDeleteUrl(int id) => '$baseUrl/api/notifications/notifications/$id/';
  static String getEmployeeUrl(int employeeId) => '$baseUrl$employeeEndpoint/$employeeId';
}