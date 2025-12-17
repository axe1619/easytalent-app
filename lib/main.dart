import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:flutter_face_api_beta/flutter_face_api.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_views/attendance_attendance.dart';
import 'attendance_views/attendance_overview.dart';
import 'attendance_views/attendance_request.dart';
import 'attendance_views/hour_account.dart';
import 'attendance_views/my_attendance_view.dart';
import 'checkin_checkout/checkin_checkout_views/checkin_checkout_form.dart';
import 'employee_views/employee_form.dart';
import 'employee_views/employee_list.dart';
import 'horilla_leave/all_assigned_leave.dart';
import 'horilla_leave/leave_allocation_request.dart';
import 'horilla_leave/leave_overview.dart';
import 'horilla_leave/leave_request.dart';
import 'horilla_leave/leave_types.dart';
import 'horilla_leave/my_leave_request.dart';
import 'horilla_leave/selected_leave_type.dart';
import 'horilla_main/login.dart';
import 'horilla_main/home.dart';
import 'horilla_main/notifications_list.dart';
import 'horilla_main/splash_screen.dart';
import 'core/routes/app_routes.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/services/notification_service.dart';
import 'data/services/notification_manager_service.dart';
import 'data/services/local_storage_service.dart';
import 'domain/usecases/fetch_notifications_usecase.dart';
import 'domain/usecases/get_unread_count_usecase.dart';
import 'domain/usecases/mark_all_read_usecase.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isAuthenticated = false;
late NotificationManagerService notificationManagerService;

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse notificationResponse) async {
  // Esta función se ejecuta en otro isolate, así que solo lógica ligera
  debugPrint(
    'Notificación en background: id=${notificationResponse.id}, payload=${notificationResponse.payload}',
  );

  // En muchos casos no es seguro navegar aquí; la navegación se hace
  // en onDidReceiveNotificationResponse (foreground) cuando la app se abre.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await NotificationService.instance.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    ),
    onDidReceiveNotificationResponse: (NotificationResponse details) async {
      final context = navigatorKey.currentState?.context;
      if (context != null && isAuthenticated) {
        Navigator.pushNamed(context, AppRoutes.notificationsList);
        await notificationManagerService.markAllAsRead();
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  final prefs = await SharedPreferences.getInstance();
  isAuthenticated = prefs.getString('token') != null;

  // Inicializar servicios de notificaciones
  final notificationRepository = NotificationRepositoryImpl();
  final fetchNotificationsUseCase = FetchNotificationsUseCase(notificationRepository);
  final getUnreadCountUseCase = GetUnreadCountUseCase(notificationRepository);
  final markAllReadUseCase = MarkAllReadUseCase(notificationRepository);
  final localStorageService = LocalStorageService();

  notificationManagerService = NotificationManagerService(
    fetchNotificationsUseCase: fetchNotificationsUseCase,
    getUnreadCountUseCase: getUnreadCountUseCase,
    markAllReadUseCase: markAllReadUseCase,
    localStorageService: localStorageService,
  );

  if (isAuthenticated) {
    await notificationManagerService.initialize();
  }

  runApp(LoginApp());
  clearSharedPrefs();
}

void clearSharedPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('clockCheckedIn');
  await prefs.remove('checkout');
  await prefs.remove('checkin');
}

class LoginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      navigatorKey: navigatorKey,
      home: FutureBuilderPage(),
      routes: AppRoutes.getRoutes(),
    );
  }
}

class FutureBuilderPage extends StatefulWidget {
  const FutureBuilderPage({super.key});

  @override
  State<FutureBuilderPage> createState() => _FutureBuilderPageState();
}

class _FutureBuilderPageState extends State<FutureBuilderPage> {
  late Future<bool> _futurePath;

  @override
  void initState() {
    super.initState();
    _futurePath = _initialize();
  }

  Future<bool> _initialize() async {
    // Simular un pequeño delay para mostrar el splash
    await Future.delayed(const Duration(seconds: 20));
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _futurePath,
      builder: (context, snapshot) {
        // Mientras carga, mostrar el splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Cuando termine de cargar, decidir a dónde ir
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data == true) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        }
        
        return const SplashScreen();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
