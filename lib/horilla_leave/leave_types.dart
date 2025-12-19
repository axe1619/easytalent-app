import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../core/routes/app_routes.dart';
import '../res/consts/app_colors.dart';
import '../res/utilities/custom_bottom_nav_bar.dart';
import '../res/utilities/drawer_wrapper.dart';
import 'leave_request.dart';

class LeaveTypes extends StatefulWidget {
  const LeaveTypes({super.key});

  @override
  State<LeaveTypes> createState() => _LeaveTypes();
}

class _LeaveTypes extends State<LeaveTypes> {
  List<Map<String, dynamic>> leaveType = [];
  int currentIndex = 0;
  int leaveTypeCount = 0;
  bool isLoading = true;
  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveTypeCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;
  late String baseUrl = '';
  Map<String, dynamic> arguments = {};
  late String getToken = '';

  @override
  void initState() {
    super.initState();
    getLeaveType();
    getBaseUrl();
    prefetchData();
    fetchToken();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    await permissionLeaveOverviewChecks();
    await permissionLeaveTypeChecks();
    await permissionLeaveRequestChecks();
    await permissionLeaveAssignChecks();
    setState(() {});
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    setState(() {
      getToken = token ?? '';
    });
  }


  Future<void> permissionLeaveOverviewChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-perm/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        permissionLeaveOverviewCheck = true;
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    } else {
      setState(() {
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    }
  }

  Future<void> permissionLeaveTypeChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-type/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        permissionLeaveTypeCheck = true;
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    } else {
      setState(() {
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    }
  }

  Future<void> permissionLeaveRequestChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-request/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        permissionLeaveRequestCheck = true;
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    } else {
      setState(() {
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    }
  }

  Future<void> permissionLeaveAssignChecks() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/check-assign/');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });
    if (response.statusCode == 200) {
      setState(() {
        permissionLeaveAssignCheck = true;
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    } else {
      setState(() {
        permissionMyLeaveRequestCheck = true;
        permissionLeaveAllocationCheck = true;
      });
    }
  }

  void prefetchData() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var employeeId = prefs.getInt("employee_id");
    var uri = Uri.parse('$typedServerUrl/api/employee/employees/$employeeId');
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        arguments = {
          'employee_id': responseData['id'],
          'employee_name':
              '${responseData['employee_first_name']} ${responseData['employee_last_name']}',
          'badge_id': responseData['badge_id'],
          'email': responseData['email'],
          'phone': responseData['phone'],
          'date_of_birth': responseData['dob'],
          'gender': responseData['gender'],
          'address': responseData['address'],
          'country': responseData['country'],
          'state': responseData['state'],
          'city': responseData['city'],
          'qualification': responseData['qualification'],
          'experience': responseData['experience'],
          'marital_status': responseData['marital_status'],
          'children': responseData['children'],
          'emergency_contact': responseData['emergency_contact'],
          'emergency_contact_name': responseData['emergency_contact_name'],
          'employee_work_info_id': responseData['employee_work_info_id'],
          'employee_bank_details_id': responseData['employee_bank_details_id'],
          'employee_profile': responseData['employee_profile']
        };
      });
    }
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var typedServerUrl = prefs.getString("typed_url");
    setState(() {
      baseUrl = typedServerUrl ?? '';
    });
  }

  Future<void> getLeaveType() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/leave/leave-type/');
    try {
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          leaveType = List<Map<String, dynamic>>.from(decoded['results'] ?? []);
          leaveTypeCount = decoded['count'] ?? leaveType.length;
          isLoading = false;
        });
        return;
      }
    } catch (_) {
      // No-op: se maneja abajo
    }

    if (mounted) {
      setState(() {
        leaveType = [];
        leaveTypeCount = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> leaveMenuItems = [];

    if (permissionLeaveOverviewCheck) {
      leaveMenuItems.add({
        'icon': Icons.dashboard_outlined,
        'title': 'Resumen',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.leaveOverview),
      });
    }

    if (permissionMyLeaveRequestCheck) {
      leaveMenuItems.add({
        'icon': Icons.assignment_outlined,
        'title': 'Mis Solicitudes',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.myLeaveRequest),
      });
    }

    if (permissionLeaveRequestCheck) {
      leaveMenuItems.add({
        'icon': Icons.request_quote,
        'title': 'Solicitud de Permiso',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.leaveRequest),
      });
    }

    if (permissionLeaveTypeCheck) {
      leaveMenuItems.add({
        'icon': Icons.category_outlined,
        'title': 'Tipos de Permiso',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.leaveTypes),
      });
    }

    if (permissionLeaveAllocationCheck) {
      leaveMenuItems.add({
        'icon': Icons.assignment_outlined,
        'title': 'Solicitud de Asignación',
        'onTap': () =>
            Navigator.pushNamed(context, AppRoutes.leaveAllocationRequest),
      });
    }

    if (permissionLeaveAssignCheck) {
      leaveMenuItems.add({
        'icon': Icons.assignment_ind_outlined,
        'title': 'Todos los Permisos Asignados',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.allAssignedLeave),
      });
    }

    return DrawerWrapper(
      appBarTitle: 'Tipos de Permiso',
      onNotificationTap: null,
      onLogout: null,
      onSettingsTap: null,
      userData: arguments.isNotEmpty ? arguments : null,
      customMenuItems: leaveMenuItems,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Center(
                child: isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: ListView.builder(
                          itemCount: 20,
                          itemBuilder: (context, index) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              width: 40.0,
                              height: 80.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : leaveTypeCount == 0
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.black,
                                  size: 92,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "No hay registros de tipos de permiso para mostrar",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: leaveType.length,
                            itemBuilder: (context, index) {
                              final record = leaveType[index];
                              if (record['name'] != null) {
                                return buildListItem(
                                  context,
                                  baseUrl,
                                  record,
                                  getToken,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
              ),
            ),
            // Botón flotante para crear nueva solicitud
            if (!isLoading)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LeaveRequest()),
                    );
                  },
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: currentIndex,
          arguments: arguments,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

Widget buildListItem(
    BuildContext context, String baseUrl, Map<String, dynamic> record, String token) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.selectedLeaveType, arguments: {
          'selectedTypeId': record['id'],
          'selectedTypeName': record['name'],
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[50]!),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400.withAlpha(77),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          tileColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 1.0),
            ),
            child: Stack(
              children: [
                if (record['icon'] != null && record['icon'].isNotEmpty)
                  Positioned.fill(
                    child: ClipOval(
                      child: Image.network(
                        baseUrl + record['icon'],
                        headers: {
                          "Authorization": "Bearer $token",
                        },
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return const Icon(Icons.calendar_month_outlined,
                              color: Colors.grey);
                        },
                      ),
                    ),
                  ),
                if (record['icon'] == null || record['icon'].isEmpty)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[400],
                      ),
                      child: const Icon(Icons.calendar_month_outlined),
                    ),
                  ),
              ],
            ),
          ),
          title: Text(
            record['name'],
            style: const TextStyle(
              fontSize: 18.0,
            ),
          ),
          trailing: const Icon(Icons.keyboard_arrow_right),
        ),
      ),
    ),
  );
}
