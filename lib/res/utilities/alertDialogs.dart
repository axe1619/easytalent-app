import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../consts/app_colors.dart';
import '../../checkin_checkout/checkin_checkout_views/geofencing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

  class AppAlertDialogs {
    static Future<void> showSettingsDialog({
    required BuildContext context,
    required Future<bool> Function() getFaceDetection,
    required Future<bool?> Function() getGeoFence,
    required Future<void> Function() enableFaceDetection,
    required Future<void> Function() disableFaceDetection,
    required Future<void> Function() enableGeoFenceLocation,
    required Future<void> Function() disableGeoFenceLocation,
    Future<void> Function()? onSettingsChanged,
    required bool permissionGeoFencingMapViewCheck,
    required Function() navigateToMapScreen,
  }) async {
    var faceDetection = await getFaceDetection();
    var geoFencingResponse = await getGeoFence();
    final prefs = await SharedPreferences.getInstance();

    bool geoFencingSetupExists = geoFencingResponse != null;
    bool geoFencingEnabled = geoFencingSetupExists ? geoFencingResponse : false;

    prefs.remove('face_detection');
    prefs.setBool("face_detection", faceDetection);
    prefs.remove('geo_fencing');
    prefs.setBool("geo_fencing", geoFencingEnabled);

    showDialog(
      context: context,
      builder: (context) {
        bool tempFaceDetection = faceDetection;
        bool tempGeofencing = geoFencingEnabled;
        bool isGeofencingSetup = geoFencingSetupExists;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.indigo.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Configuración',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white70,
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Detección Facial',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white54,
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.white30,
                      value: tempFaceDetection,
                      onChanged: (val) {
                        setState(() {
                          tempFaceDetection = val;
                        });
                        if (val) {
                          enableFaceDetection();
                        } else {
                          disableFaceDetection();
                        }
                      },
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white70,
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Geocercas',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white54,
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.white30,
                      value: tempGeofencing,
                      onChanged: (val) async {
                        setState(() {
                          tempGeofencing = val;
                        });

                        if (!isGeofencingSetup && val) {
                          Navigator.pop(context);
                          navigateToMapScreen();
                          return;
                        }

                        if (val) {
                          await enableGeoFenceLocation();
                        } else {
                          await disableGeoFenceLocation();
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, // Color del texto del botón
                  ),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool("face_detection", tempFaceDetection);
                    await prefs.setBool("geo_fencing", tempGeofencing);

                    setState(() {
                      geoFencingEnabled = tempGeofencing;
                    });

                    Navigator.pop(context);
                    if (onSettingsChanged != null) {
                      onSettingsChanged();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

    static Future<void> showLogoutConfirmDialog({
    required BuildContext context,
    required Future<void> Function() onConfirm,
  }) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.indigo.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.exit_to_app,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // texto blanco
              ),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await onConfirm();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // texto blanco
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white, // puedes mantener rojo si quieres
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
