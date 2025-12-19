import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:horilla/checkin_checkout/checkin_checkout_views/setup_imageface.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'checkin_checkout_form.dart';
import '../controllers/face_detection_controller.dart';
import '../../res/consts/app_colors.dart';

class FaceScanner extends StatefulWidget {
  final Map userDetails;
  final String? attendanceState;
  final Position? userLocation;

  const FaceScanner({
    Key? key,
    required this.userDetails,
    required this.attendanceState,
    required this.userLocation,
  }) : super(key: key);

  @override
  State<FaceScanner> createState() => _FaceScannerState();
}

class _FaceScannerState extends State<FaceScanner> with SingleTickerProviderStateMixin {
  late FaceScannerController _controller;
  bool _isCameraInitialized = false;
  bool _isComparing = false;
  String? _employeeImageBase64;
  bool _isDetectionPaused = false;
  bool _isFetchingImage = false;

  late AnimationController _animationController;
  late Animation _rotationAnimation;
  late Animation _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = FaceScannerController();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _rotationAnimation = Tween(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _scaleAnimation = Tween(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  Future<void> _initializeApp() async {
    try {
      await _fetchBiometricImage();
      if (_employeeImageBase64 != null && mounted) {
        await _initializeCamera();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo inicializar: $e')),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _controller.initializeCamera();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
      _startRealTimeFaceDetection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo inicializar la cámara: $e')),
        );
      }
    }
  }

  Future<void> _fetchBiometricImage() async {
    if (_isFetchingImage) return;
    setState(() => _isFetchingImage = true);

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");
    final String? typedServerUrl = prefs.getString("typed_url");
    final String? faceDetectionImage = prefs.getString("face_detection_image");
    final String? imagePath = prefs.getString("imagePath");

    if (token == null ||
        typedServerUrl == null ||
        ((faceDetectionImage == null || faceDetectionImage.isEmpty) &&
            (imagePath == null || imagePath.isEmpty))) {
      if (mounted) showImageAlertDialog(context);
      return;
    }

    try {
      // --- Build image URL ---
      String? imageUrl;
      final cleanedServerUrl = typedServerUrl.endsWith('/')
          ? typedServerUrl.substring(0, typedServerUrl.length - 1)
          : typedServerUrl;

      if (faceDetectionImage != null && faceDetectionImage.isNotEmpty) {
        final cleanedPath = faceDetectionImage.startsWith('/')
            ? faceDetectionImage.substring(1)
            : faceDetectionImage;
        imageUrl = '$cleanedServerUrl/$cleanedPath';
      } else if (imagePath != null && imagePath.isNotEmpty) {
        final cleanedPath = imagePath.startsWith('/')
            ? imagePath.substring(1)
            : imagePath;
        imageUrl = '$cleanedServerUrl/media/$cleanedPath';
      }

      if (imageUrl == null) {
        if (mounted) showImageAlertDialog(context);
        return;
      }

      debugPrint("Obteniendo imagen biométrica: $imageUrl");

      // --- Correct usage of HttpClient + IOClient ---
      final httpClient = HttpClient();
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      httpClient.autoUncompress = false;

      final ioClient = IOClient(httpClient);

      final response = await ioClient.get(
        Uri.parse(imageUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "image/*",
          "Accept-Encoding": "identity",
          "User-Agent": "FlutterApp/1.0",
          "Connection": "keep-alive",
        },
      );

      debugPrint("Estado: ${response.statusCode}");

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        setState(() {
          _employeeImageBase64 = base64Encode(response.bodyBytes);
        });
        debugPrint("Imagen descargada: ${response.bodyBytes.length} bytes");
      } else {
        debugPrint("Respuesta inválida o imagen vacía");
        if (mounted) showImageAlertDialog(context);
      }

      ioClient.close();
    } catch (e) {
      debugPrint("Error al obtener la imagen biométrica: $e");
      if (mounted) showImageAlertDialog(context);
    } finally {
      if (mounted) setState(() => _isFetchingImage = false);
    }
  }

  void showImageAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Imagen del empleado no configurada"),
        content: const Text("¿Deseas configurar una nueva imagen facial?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final cameras = await availableCameras();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CameraSetupPage(cameras: cameras)),
                );
              }
            },
            child: const Text("Sí"),
          ),
        ],
      ),
    );
  }

  Future<void> _startRealTimeFaceDetection() async {
    while (_isCameraInitialized && !_isDetectionPaused && mounted) {
      try {
        await Future.delayed(const Duration(milliseconds: 500)); // Increased delay

        if (!mounted || !_controller.cameraController.value.isInitialized) break;

        setState(() => _isComparing = true);
        final image = await _controller.captureImage();

        if (image == null || _employeeImageBase64 == null) {
          debugPrint('No se pudo capturar la imagen o no hay imagen del empleado');
          continue;
        }

        debugPrint('Iniciando comparación facial...');
        final isMatched = await _controller.compareFaces(File(image.path), _employeeImageBase64!);
        debugPrint('Resultado de comparación: $isMatched');

        if (isMatched) {
          await _handleComparisonResult(true);
          break;
        } else {
          setState(() => _isDetectionPaused = true);
          await _showIncorrectFaceAlert();
          setState(() => _isDetectionPaused = false);
        }
      } catch (e) {
        debugPrint('Error en detección facial: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error en la detección facial. Intenta de nuevo.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isComparing = false);
      }
    }
  }

  Future<void> _showIncorrectFaceAlert() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Rostro incorrecto"),
        content: const Text("El rostro detectado no coincide. Intenta de nuevo."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => CheckInCheckOutFormPage()),
                );
              }
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleComparisonResult(bool isMatched) async {
    if (!isMatched || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    final geoFencing = prefs.getBool("geo_fencing") ?? false;

    if (geoFencing && widget.userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación no disponible. No se puede continuar.')),
      );
      return;
    }

    try {
      final endpoint = widget.attendanceState == 'NOT_CHECKED_IN'
          ? 'api/attendance/clock-in/'
          : 'api/attendance/clock-out/';

      final uri = Uri.parse('$typedServerUrl/$endpoint');
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      final body = geoFencing
          ? jsonEncode({
        "latitude": widget.userLocation!.latitude,
        "longitude": widget.userLocation!.longitude,
      })
          : jsonEncode({});

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, {
          if (widget.attendanceState == 'NOT_CHECKED_IN') 'checkedIn': true,
          if (widget.attendanceState == 'CHECKED_IN') 'checkedOut': true,
        });
      } else if (mounted) {
        final errorMessage = getErrorMessage(response.body);
        showCheckInFailedDialog(context, errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de red: $e')),
        );
      }
    }
  }

  String getErrorMessage(String responseBody) {
    try {
      final Map decoded = json.decode(responseBody);
      return decoded['message'] ?? 'Ocurrió un error desconocido';
    } catch (e) {
      return 'Error al procesar la respuesta del servidor';
    }
  }

  void showCheckInFailedDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error al marcar asistencia'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _isDetectionPaused = true;
    if (_controller.cameraController.value.isInitialized) {
      _controller.cameraController.dispose();
    }
    super.dispose();
  }

  Widget _buildImageContainer(double screenHeight, double screenWidth) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isComparing ? _scaleAnimation.value : 1.0,
              child: Container(
                height: screenHeight * 0.4,
                width: screenWidth * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isCameraInitialized && _controller.cameraController.value.isInitialized
                      ? CameraPreview(_controller.cameraController)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          },
        ),
        if (_isComparing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 50),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Detectando rostros...',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Detección facial'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.1),
            _buildImageContainer(screenHeight, screenWidth),
            SizedBox(height: screenHeight * 0.05),
            if (_isFetchingImage)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
