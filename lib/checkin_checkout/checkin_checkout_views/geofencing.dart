import 'dart:convert';
import 'package:horilla/horilla_main/home.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import '../../res/consts/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final List<LocationWithRadius> locations = [];
  LocationWithRadius? selectedLocation;
  final PopupController _popupController = PopupController();
  late final AnimatedMapController _mapController;
  double _currentRadius = 50.0;
  Position? userLocation;
  Map<String, dynamic> responseData = {};
  bool _showCurrentLocationCircle = false;
  bool _showTappedLocationCircle = false;
  bool _isExistingGeofence = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _mapController = AnimatedMapController(vsync: this);
    getGeoFenceLocation().then((_) {
      if (mounted && selectedLocation != null) {
        _mapController.animateTo(dest: selectedLocation!.coordinates, zoom: 12.0);
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController.dispose();
    super.dispose();
  }

  Future<String> _getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String name = "${place.locality ?? ''}, ${place.country ?? ''}".trim();
        return name.isEmpty ? "Ubicación desconocida" : name;
      }
      return "Ubicación desconocida";
    } catch (e) {
      debugPrint('Error al obtener el nombre de ubicación: $e');
      return "Ubicación desconocida";
    }
  }

  Future<void> createGeoFenceLocation() async {
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    var companyId = prefs.getInt("company_id");
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/geofencing/setup/');

    try {
      var response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'latitude': selectedLocation?.coordinates.latitude,
          'longitude': selectedLocation?.coordinates.longitude,
          'radius_in_meters': selectedLocation?.radius,
          'start': true,
          'company_id': companyId
        }),
      );

      if (_isDisposed) return;

      if (response.statusCode == 201) {
        await showCreateAnimation();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al guardar'),
              duration: Duration(seconds: 2),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al guardar'),
            duration: Duration(seconds: 2),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Future<void> updateGeoFenceLocation() async {
    if (_isDisposed) return;
    var locationId = responseData['id'];
    final prefs = await SharedPreferences.getInstance();
    var companyId = prefs.getInt("company_id");
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/geofencing/setup/$locationId/');

    try {
      var response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'latitude': selectedLocation?.coordinates.latitude,
          'longitude': selectedLocation?.coordinates.longitude,
          'radius_in_meters': selectedLocation?.radius,
          'start': true,
          'company_id': companyId
        }),
      );

      if (_isDisposed) return;
      if (response.statusCode == 200) {
        await showCreateAnimation();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al guardar'),
              duration: Duration(seconds: 2),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al guardar'),
            duration: Duration(seconds: 2),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Future<void> deleteGeoFenceLocation() async {
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    var locationId = responseData['id'];
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/geofencing/setup/$locationId/');

    try {
      var response = await http.delete(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 204) {
        await showDeleteAnimation();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Error al eliminar'),
                duration: const Duration(seconds: 2),
                backgroundColor: primaryColor,
              ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al eliminar'),
              duration: const Duration(seconds: 2),
              backgroundColor: primaryColor,
            ),
        );
      }
    }
  }

  Future<void> getGeoFenceLocation() async {
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("token");
    var typedServerUrl = prefs.getString("typed_url");
    var uri = Uri.parse('$typedServerUrl/api/geofencing/setup/');

    try {
      var response = await http.get(uri, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = data['latitude'];
          final lng = data['longitude'];
          final rad = data['radius_in_meters'];

          if (lat != null && lng != null && rad != null) {
            final locationName = await _getLocationName(lat, lng);
            final location = LocationWithRadius(
              LatLng(lat, lng),
              locationName,
              (rad).toDouble(),
              isExisting: true,
            );
            if (mounted) {
              setState(() {
                responseData = data;
                locations.clear();
                locations.add(location);
                selectedLocation = location;
                _currentRadius = rad.toDouble();
                _isExistingGeofence = true;
              });
            }
          }
        }
      } else {
        debugPrint('No se pudo cargar la geocerca: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error al obtener geocerca: $e");
    }
  }

  Future<void> showCreateAnimation() async {
    if (_isDisposed) return;

    String jsonContent = '''
{
  "imagePath": "Assets/gif22.gif"
}
''';
    Map<String, dynamic> jsonData = json.decode(jsonContent);
    String imagePath = jsonData['imagePath'];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imagePath,
                        width: 180, height: 180, fit: BoxFit.cover),
                    const SizedBox(height: 16),
                    Text(
                      "Ubicación de geocerca agregada correctamente",
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
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      }
    });
  }

  Future<void> showDeleteAnimation() async {
    if (_isDisposed) return;

    String jsonContent = '''
{
  "imagePath": "Assets/gif22.gif"
}
''';
    Map<String, dynamic> jsonData = json.decode(jsonContent);
    String imagePath = jsonData['imagePath'];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imagePath,
                        width: 180, height: 180, fit: BoxFit.cover),
                    const SizedBox(height: 16),
                    Text(
                      "Ubicación de geocerca eliminada correctamente",
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
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      }
    });
  }

  Future<Position?> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: const Text('Mapa de geocercas', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController.mapController,
              options: MapOptions(
                center: selectedLocation != null
                    ? selectedLocation!.coordinates
                    : userLocation != null
                    ? LatLng(userLocation!.latitude, userLocation!.longitude)
                    : const LatLng(40.0, 0.0),
                zoom: (selectedLocation != null || userLocation != null) ? 12.0 : 2.0,
                minZoom: 2.0,
                maxZoom: 18.0,
                interactiveFlags: InteractiveFlag.all,
                onTap: (_, latLng) async {
                  String locationName = await _getLocationName(
                    latLng.latitude,
                    latLng.longitude,
                  );
                  if (mounted) {
                    setState(() {
                      locations.clear();
                      final newLocation = LocationWithRadius(
                        latLng,
                        locationName,
                        _currentRadius,
                      );
                      locations.add(newLocation);
                      selectedLocation = newLocation;
                      _showCurrentLocationCircle = false;
                      _showTappedLocationCircle = true;
                      _isExistingGeofence = false;
                    });
                    _mapController.animateTo(
                      dest: latLng,
                      zoom: 12.0,
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cybrosys.horilla',
                ),
                CircleLayer(
                  circles: [
                    if (selectedLocation != null && _showTappedLocationCircle)
                      CircleMarker(
                        point: selectedLocation!.coordinates,
                        color: secondaryColor.withOpacity(0.3),
                        borderColor: secondaryColor,
                        borderStrokeWidth: 2.0,
                        radius: selectedLocation!.radius,
                      ),
                    if (_showCurrentLocationCircle && userLocation != null)
                      CircleMarker(
                        point: LatLng(userLocation!.latitude, userLocation!.longitude),
                        color: primaryColor.withOpacity(0.3),
                        borderColor: primaryColor,
                        borderStrokeWidth: 2.0,
                        radius: _currentRadius,
                      ),
                    if (responseData.isNotEmpty && !_showCurrentLocationCircle && !_showTappedLocationCircle)
                      CircleMarker(
                        point: LatLng(responseData['latitude'], responseData['longitude']),
                        color: primaryColor.withOpacity(0.3),
                        borderColor: primaryColor,
                        borderStrokeWidth: 2.0,
                        radius: _currentRadius,
                      ),
                  ],
                ),
                PopupMarkerLayerWidget(
                  options: PopupMarkerLayerOptions(
                    popupController: _popupController,
                    markers: locations
                        .map((loc) => Marker(
                      point: loc.coordinates,
                      width: 40.0,
                      height: 40.0,
                      child: GestureDetector(
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              selectedLocation = loc;
                              _isExistingGeofence = loc.isExisting;
                              _showCurrentLocationCircle = false;
                              _showTappedLocationCircle = true;
                            });
                            _mapController.animateTo(
                              dest: loc.coordinates,
                              zoom: 12.0,
                            );
                          }
                        },
                        child: Icon(
                          Icons.location_on,
                          color: secondaryColor,
                          size: 40.0,
                        ),
                      ),
                    ))
                        .toList(),
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        final loc = locations.firstWhere(
                              (loc) => loc.coordinates == marker.point,
                        );
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                loc.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Radio: ${loc.radius.toStringAsFixed(1)} m'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ubicación: ${selectedLocation!.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              locations.remove(selectedLocation);
                              selectedLocation = null;
                              _showTappedLocationCircle = false;
                              _isExistingGeofence = false;
                            });
                          }
                        },
                        icon: Icon(Icons.close, color: primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Radio de geocerca: '),
                      Expanded(
                        child: Slider(
                          value: _currentRadius,
                          min: 1,  // Minimum value is 1 (natural number)
                          max: 10000,
                          divisions: 99,
                          label: '${_currentRadius.round()} m',  // Round to nearest integer
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _currentRadius = value.roundToDouble();  // Round to nearest integer
                                if (selectedLocation != null) {
                                  final index = locations.indexOf(selectedLocation!);
                                  locations[index] = LocationWithRadius(
                                    selectedLocation!.coordinates,
                                    selectedLocation!.name,
                                    _currentRadius,  // Now a natural number
                                    isExisting: selectedLocation!.isExisting,
                                  );
                                  selectedLocation = locations[index];
                                }
                              });
                            }
                          },
                        ),
                      ),
                      Text('${_currentRadius.toStringAsFixed(2)} m'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_isExistingGeofence)
                        ElevatedButton(
                          onPressed: () async {
                            await showGeofencingDelete(context);
                            if (mounted) {
                              setState(() {
                                locations.remove(selectedLocation);
                                selectedLocation = null;
                                _showTappedLocationCircle = false;
                                _isExistingGeofence = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor),
                          child: const Text('Eliminar'),
                        ),
                      ElevatedButton(
                        onPressed: () async {
                          await showGeofencingSetting(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newLocation = await fetchCurrentLocation();
          if (newLocation != null && mounted) {
            String locationName = await _getLocationName(
              newLocation.latitude,
              newLocation.longitude,
            );
            setState(() {
              userLocation = newLocation;
              locations.clear();
              final newLoc = LocationWithRadius(
                LatLng(newLocation.latitude, newLocation.longitude),
                locationName,
                _currentRadius,
              );
              locations.add(newLoc);
              selectedLocation = newLoc;
              _showCurrentLocationCircle = true;
              _showTappedLocationCircle = false;
              _isExistingGeofence = false;
            });
            _mapController.animateTo(
              dest: LatLng(newLocation.latitude, newLocation.longitude),
              zoom: 12.0,
            );
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> showGeofencingSetting(BuildContext context) async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Configurar ubicación de geocerca"),
          content: const Text("¿Deseas usar esta ubicación para geocercas?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                var geo_fencing = prefs.getBool("geo_fencing");
                if (geo_fencing == true) {
                  await updateGeoFenceLocation();
                }
                else {
                  await createGeoFenceLocation();
                }
              },
              child: Text("Confirmar", style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> showGeofencingDelete(BuildContext context) async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Eliminar ubicación de geocerca"),
          content: const Text("¿Deseas eliminar esta ubicación de geocercas?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await deleteGeoFenceLocation();
              },
              child: Text("Confirmar", style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }
}

class LocationWithRadius {
  final LatLng coordinates;
  final String name;
  double radius; // in meters
  bool isExisting;

  LocationWithRadius(this.coordinates, this.name, double radius, {this.isExisting = false})
      : radius = radius.roundToDouble().clamp(1, double.infinity);  // Ensure at least 1
}
