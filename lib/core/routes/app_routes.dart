import 'package:flutter/material.dart';
import '../../attendance_views/attendance_attendance.dart';
import '../../attendance_views/attendance_overview.dart';
import '../../attendance_views/attendance_request.dart';
import '../../attendance_views/hour_account.dart';
import '../../attendance_views/my_attendance_view.dart';
import '../../checkin_checkout/checkin_checkout_views/checkin_checkout_form.dart';
import '../../employee_views/employee_form.dart';
import '../../employee_views/employee_list.dart';
import '../../horilla_leave/all_assigned_leave.dart';
import '../../horilla_leave/leave_allocation_request.dart';
import '../../horilla_leave/leave_overview.dart';
import '../../horilla_leave/leave_request.dart';
import '../../horilla_leave/leave_types.dart';
import '../../horilla_leave/my_leave_request.dart';
import '../../horilla_leave/selected_leave_type.dart';
import '../../horilla_main/login.dart';
import '../../horilla_main/home.dart';
import '../../horilla_main/notifications_list.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String employeesList = '/employees_list';
  static const String employeesForm = '/employees_form';
  static const String attendanceOverview = '/attendance_overview';
  static const String attendanceAttendance = '/attendance_attendance';
  static const String attendanceRequest = '/attendance_request';
  static const String myAttendanceView = '/my_attendance_view';
  static const String employeeHourAccount = '/employee_hour_account';
  static const String employeeCheckinCheckout = '/employee_checkin_checkout';
  static const String leaveOverview = '/leave_overview';
  static const String leaveTypes = '/leave_types';
  static const String myLeaveRequest = '/my_leave_request';
  static const String leaveRequest = '/leave_request';
  static const String leaveAllocationRequest = '/leave_allocation_request';
  static const String allAssignedLeave = '/all_assigned_leave';
  static const String selectedLeaveType = '/selected_leave_type';
  static const String notificationsList = '/notifications_list';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginPage(),
      home: (context) => const HomePage(),
      employeesList: (context) => EmployeeListPage(),
      employeesForm: (context) => EmployeeFormPage(),
      attendanceOverview: (context) => AttendanceOverview(),
      attendanceAttendance: (context) => AttendanceAttendance(),
      attendanceRequest: (context) => AttendanceRequest(),
      myAttendanceView: (context) => MyAttendanceViews(),
      employeeHourAccount: (context) => HourAccountFormPage(),
      employeeCheckinCheckout: (context) => CheckInCheckOutFormPage(),
      leaveOverview: (context) => LeaveOverview(),
      leaveTypes: (context) => LeaveTypes(),
      myLeaveRequest: (context) => MyLeaveRequest(),
      leaveRequest: (context) => LeaveRequest(),
      leaveAllocationRequest: (context) => LeaveAllocationRequest(),
      allAssignedLeave: (context) => AllAssignedLeave(),
      selectedLeaveType: (context) => SelectedLeaveType(),
      notificationsList: (context) => NotificationsList(),
    };
  }
}
