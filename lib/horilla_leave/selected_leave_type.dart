import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../core/routes/app_routes.dart';
import '../res/consts/app_colors.dart';
import '../res/utilities/custom_bottom_nav_bar.dart';
import '../res/utilities/drawer_wrapper.dart';

class SelectedLeaveType extends StatefulWidget {
  const SelectedLeaveType({super.key});

  @override
  State<SelectedLeaveType> createState() => _SelectedLeaveTypeState();
}

class _SelectedLeaveTypeState extends State<SelectedLeaveType> {
  int? _typeId;
  String? _typeName;
  bool _didInitFromArgs = false;

  int currentIndex = 0;
  bool isLoading = true;
  bool isSubmitting = false;

  String baseUrl = '';
  String token = '';
  Map<String, dynamic> userArguments = {};
  Map<String, dynamic> typeDetails = {};

  final List<String> employeeItems = [];
  final List<int> employeeItemsId = [];
  final List<String> selectedEmployeeNames = [];
  final List<int> selectedEmployeeIds = [];

  bool permissionLeaveAssignCheck = false;
  bool permissionLeaveTypeCheck = false;
  bool permissionLeaveRequestCheck = false;
  bool permissionLeaveOverviewCheck = false;
  bool permissionMyLeaveRequestCheck = false;
  bool permissionLeaveAllocationCheck = false;

  @override
  void initState() {
    super.initState();
    fetchToken();
    getBaseUrl();
    prefetchData();
    getEmployees();
    checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args == null) return;

    _typeId = (args['selectedTypeId'] as num?)?.toInt();
    _typeName = args['selectedTypeName']?.toString();
    _didInitFromArgs = true;

    getSelectedLeaveType();
  }

  Future<void> fetchToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      token = prefs.getString("token") ?? '';
    });
  }

  Future<void> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      baseUrl = prefs.getString("typed_url") ?? '';
    });
  }

  Future<void> prefetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    final employeeId = prefs.getInt("employee_id");
    if (token == null || typedServerUrl == null || employeeId == null) return;

    final uri = Uri.parse('$typedServerUrl/api/employee/employees/$employeeId');
    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode != 200) return;

    final responseData = jsonDecode(response.body);
    final newArgs = <String, dynamic>{
      'employee_id': responseData['id'],
      'employee_name': '${responseData['employee_first_name']} ${responseData['employee_last_name']}',
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
      'employee_profile': responseData['employee_profile'],
    };

    if (!mounted) return;
    setState(() {
      userArguments = newArgs;
    });
  }

  Future<void> checkPermissions() async {
    await permissionLeaveOverviewChecks();
    await permissionLeaveTypeChecks();
    await permissionLeaveRequestChecks();
    await permissionLeaveAssignChecks();
    if (mounted) setState(() {});
  }

  Future<void> permissionLeaveOverviewChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    final uri = Uri.parse('$typedServerUrl/api/leave/check-perm/');
    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      permissionLeaveOverviewCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> permissionLeaveTypeChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    final uri = Uri.parse('$typedServerUrl/api/leave/check-type/');
    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      permissionLeaveTypeCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> permissionLeaveRequestChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    final uri = Uri.parse('$typedServerUrl/api/leave/check-request/');
    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      permissionLeaveRequestCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> permissionLeaveAssignChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    final uri = Uri.parse('$typedServerUrl/api/leave/check-assign/');
    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      permissionLeaveAssignCheck = true;
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    } else {
      permissionMyLeaveRequestCheck = true;
      permissionLeaveAllocationCheck = true;
    }
  }

  Future<void> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    employeeItems.clear();
    employeeItemsId.clear();

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final uri = Uri.parse('$typedServerUrl/api/employee/employee-selector?page=$page');
      final response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode != 200) break;

      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) break;

      if (!mounted) return;
      setState(() {
        for (final employee in results) {
          final firstName = employee['employee_first_name'] ?? '';
          final lastName = employee['employee_last_name'] ?? '';
          final fullName = ('$firstName $lastName').trim();
          employeeItems.add(fullName);
          employeeItemsId.add(employee['id']);
        }
      });

      page++;
    }
  }

  Future<void> getSelectedLeaveType() async {
    final typeId = _typeId;
    if (typeId == null) return;

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    final uri = Uri.parse('$typedServerUrl/api/leave/leave-type/$typeId');
    final response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (!mounted) return;
    if (response.statusCode == 200) {
      setState(() {
        typeDetails = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> assignLeave(List<int> selectedEmployeeIds) async {
    final typeId = _typeId;
    if (typeId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final typedServerUrl = prefs.getString("typed_url");
    if (token == null || typedServerUrl == null) return;

    final uri = Uri.parse('$typedServerUrl/api/leave/assign-leave/');
    await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "employee_ids": selectedEmployeeIds,
        "leave_type_ids": [typeId],
      }),
    );
  }

  void showAssignAnimation() {
    const imagePath = "Assets/gif22.gif";
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(imagePath, width: 180, height: 180, fit: BoxFit.cover),
                  const SizedBox(height: 16),
                  Text(
                    "Permiso asignado correctamente",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  Future<void> _mostrarDialogoAsignar() async {
    selectedEmployeeNames.clear();
    selectedEmployeeIds.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Stack(
              children: [
                AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Asignar Permiso",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Empleado"),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              for (int i = 0; i < selectedEmployeeNames.length; i++)
                                Chip(
                                  label: Text(selectedEmployeeNames[i]),
                                  onDeleted: () {
                                    setDialogState(() {
                                      selectedEmployeeNames.removeAt(i);
                                      selectedEmployeeIds.removeAt(i);
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          MultiSelectDropdown.simpleList(
                            list: employeeItems,
                            initiallySelected: const [],
                            onChange: (selectedItems) {
                              setDialogState(() {
                                selectedEmployeeNames.clear();
                                selectedEmployeeIds.clear();

                                if (selectedItems.contains('Select All')) {
                                  selectedEmployeeNames.addAll(employeeItems);
                                  selectedEmployeeIds.addAll(employeeItemsId);
                                  selectedEmployeeNames.remove('Select All');
                                } else {
                                  for (final name in selectedItems) {
                                    selectedEmployeeNames.add(name);
                                    final idx = employeeItems.indexOf(name);
                                    if (idx != -1) selectedEmployeeIds.add(employeeItemsId[idx]);
                                  }
                                }
                              });
                            },
                            includeSearch: true,
                            includeSelectAll: true,
                            isLarge: false,
                            checkboxFillColor: Colors.grey,
                            boxDecoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedEmployeeIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Selecciona al menos un empleado'),
                                backgroundColor: primaryColor,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          await assignLeave(selectedEmployeeIds);
                          setDialogState(() => isSubmitting = false);

                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop(true);
                          showAssignAnimation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Asignar'),
                      ),
                    ),
                  ],
                ),
                if (isSubmitting)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerEffect(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            width: double.infinity,
            height: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16.0, color: Colors.grey)),
            Flexible(
              child: Text(value, textAlign: TextAlign.right),
            ),
          ],
        ),
        const Divider(thickness: 0.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveMenuItems = <Map<String, dynamic>>[];

    if (permissionLeaveOverviewCheck) {
      leaveMenuItems.add({
        'icon': Icons.view_list_outlined,
        'title': 'Resumen',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.leaveOverview),
      });
    }

    if (permissionMyLeaveRequestCheck) {
      leaveMenuItems.add({
        'icon': Icons.person_outline,
        'title': 'Mis Solicitudes',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.myLeaveRequest),
      });
    }

    if (permissionLeaveRequestCheck) {
      leaveMenuItems.add({
        'icon': Icons.note_add_outlined,
        'title': 'Solicitudes de Permiso',
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
        'icon': Icons.assignment_turned_in_outlined,
        'title': 'Solicitud de Asignación',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.leaveAllocationRequest),
      });
    }

    if (permissionLeaveAssignCheck) {
      leaveMenuItems.add({
        'icon': Icons.assignment_ind_outlined,
        'title': 'Todos los Permisos Asignados',
        'onTap': () => Navigator.pushNamed(context, AppRoutes.allAssignedLeave),
      });
    }

    final appBarTitle = (typeDetails['name']?.toString().isNotEmpty ?? false)
        ? typeDetails['name'].toString()
        : (_typeName ?? 'Tipo de Permiso');

    return DrawerWrapper(
      appBarTitle: appBarTitle,
      userData: userArguments.isNotEmpty ? userArguments : null,
      customMenuItems: leaveMenuItems,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(25.0),
          child: isLoading
              ? _buildShimmerEffect(context)
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey, width: 1.0),
                                ),
                                child: Stack(
                                  children: [
                                    if (typeDetails['icon'] != null && typeDetails['icon'].isNotEmpty)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: Image.network(
                                            baseUrl + typeDetails['icon'],
                                            headers: {"Authorization": "Bearer $token"},
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, exception, stackTrace) {
                                              return const Icon(Icons.calendar_month_outlined, color: Colors.grey);
                                            },
                                          ),
                                        ),
                                      )
                                    else
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
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Text(
                                  typeDetails['name'] ?? 'Desconocido',
                                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Periodo en', '${typeDetails['period_in'] ?? "Desconocido"}'),
                          _buildInfoRow('Cantidad', '${typeDetails['count'] ?? "Desconocido"}'),
                          _buildInfoRow('Días Totales', '${typeDetails['total_days'] ?? "Desconocido"}'),
                          _buildInfoRow('Reinicio', '${typeDetails['reset'] ?? "Desconocido"}'),
                          _buildInfoRow('Tipo de acumulación', '${typeDetails['carryforward_type'] ?? "Desconocido"}'),
                          _buildInfoRow('Es pagado', '${typeDetails['payment'] ?? "Desconocido"}'),
                          _buildInfoRow('Requiere aprobación', '${typeDetails['require_approval'] ?? "Desconocido"}'),
                          _buildInfoRow('Requiere adjuntar', '${typeDetails['require_attachment'] ?? "Desconocido"}'),
                          const SizedBox(height: 16),
                          if (employeeItems.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _mostrarDialogoAsignar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Asignar'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: currentIndex,
          arguments: userArguments.isNotEmpty ? userArguments : null,
          onTap: (index) => setState(() => currentIndex = index),
        ),
      ),
    );
  }
}
