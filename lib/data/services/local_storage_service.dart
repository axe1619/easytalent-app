import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/login_response.dart';

class LocalStorageService {
  static const String _tokenKey = 'token';
  static const String _typedUrlKey = 'typed_url';
  static const String _faceDetectionImageKey = 'face_detection_image';
  static const String _faceDetectionKey = 'face_detection';
  static const String _geoFencingKey = 'geo_fencing';
  static const String _employeeIdKey = 'employee_id';
  static const String _companyIdKey = 'company_id';

  Future<void> saveLoginData(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, loginResponse.access);
    await prefs.setString(_typedUrlKey, 'https://www.easytalent.top');
    await prefs.setString(
        _faceDetectionImageKey, loginResponse.faceDetectionImage);
    await prefs.setBool(_faceDetectionKey, loginResponse.faceDetection);
    await prefs.setBool(_geoFencingKey, loginResponse.geoFencing);
    if (loginResponse.employee != null) {
      await prefs.setInt(_employeeIdKey, loginResponse.employee!.id);
    }
    await prefs.setInt(_companyIdKey, loginResponse.companyId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
