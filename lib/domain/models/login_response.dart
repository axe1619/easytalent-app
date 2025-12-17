class LoginResponse {
  final String access;
  final Employee? employee;
  final int companyId;
  final bool faceDetection;
  final bool geoFencing;
  final String faceDetectionImage;

  LoginResponse({
    required this.access,
    this.employee,
    required this.companyId,
    required this.faceDetection,
    required this.geoFencing,
    required this.faceDetectionImage,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      access: json['access'] ?? '',
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'])
          : null,
      companyId: json['company_id'] ?? 0,
      faceDetection: json['face_detection'] ?? false,
      geoFencing: json['geo_fencing'] ?? false,
      faceDetectionImage: json['face_detection_image']?.toString() ?? '',
    );
  }
}

class Employee {
  final int id;

  Employee({required this.id});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
    );
  }
}