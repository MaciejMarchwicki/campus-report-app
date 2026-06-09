import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_language.dart';

// ------------------------------------------------------------
// APP STYLE - same visual style as the admin panel
// ------------------------------------------------------------
const Color appTopBarColor = Color(0xFF8B0002);
const Color appTopBarTextColor = Color(0xFFFFFFFF);

const Color appBackgroundColor = Color(0xFFF4F6FA);
const Color appCardColor = Color(0xFFFFFFFF);

const Color appPrimaryColor = Color(0xFF8B0002);
const Color appPrimaryDarkColor = Color(0xFF650001);
const Color appAccentColor = Color(0xFFF4E6E6);

const Color appTextColor = Color(0xFF1F2937);
const Color appMutedTextColor = Color(0xFF667085);
const Color appBorderColor = Color(0xFFD7DCE8);
const Color appImagePlaceholderColor = Color(0xFFEEF2F7);

const Color appDangerColor = Color(0xFFDC2626);

class AlertMePage extends StatefulWidget {
  const AlertMePage({
    super.key,
    this.language = AppLanguage.en,
    this.onLanguageChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage>? onLanguageChanged;

  @override
  State<AlertMePage> createState() => _AlertMePageState();
}

class _AlertMePageState extends State<AlertMePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  late AppLanguage _language;

  String? selectedCampus;
  String? selectedBuilding;
  LatLng? selectedCoordinates;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  bool isSaving = false;

  final List<String> buildings = [
    'A1',
    'A2',
    'A3',
    'A4',
    'A5',
    'A6',
    'B1',
    'B2',
    'B3',
    'B4',
    'B5',
    'C1',
    'C2',
    'C3',
  ];

  List<String> get filteredBuildings {
    if (selectedCampus == null) {
      return [];
    }

    return [
      ...buildings.where((building) => building.startsWith(selectedCampus!)),
      'Outside',
    ];
  }

  @override
  void initState() {
    super.initState();
    _language = widget.language;
  }

  void _changeLanguage(AppLanguage language) {
    setState(() {
      _language = language;
    });

    widget.onLanguageChanged?.call(language);
  }

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    floorController.dispose();
    roomController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
    });
  }

  String _buildLocationLabel() {
    final parts = <String>[];

    if (selectedBuilding != null && selectedBuilding!.isNotEmpty) {
      if (selectedBuilding == 'Outside') {
        parts.add(tr(_language, 'Outside', 'Na zewnątrz'));
      } else {
        parts.add('${tr(_language, 'Building', 'Budynek')} $selectedBuilding');
      }
    }

    if (floorController.text.trim().isNotEmpty) {
      parts.add('${tr(_language, 'Floor', 'Piętro')} ${floorController.text.trim()}');
    }

    if (roomController.text.trim().isNotEmpty) {
      parts.add('${tr(_language, 'Room', 'Sala')} ${roomController.text.trim()}');
    }

    if (locationController.text.trim().isNotEmpty) {
      parts.add(locationController.text.trim());
    }

    return parts.join(', ');
  }

  String _safeFileName(String originalName) {
    final sanitized = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (sanitized.trim().isEmpty) {
      return 'image.jpg';
    }

    return sanitized;
  }

  Future<String?> _uploadImageIfSelected() async {
    if (selectedImage == null || selectedImageBytes == null) {
      return null;
    }

    final fileName = _safeFileName(selectedImage!.name);
    final filePath = 'reports/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await Supabase.instance.client.storage.from('report_images').uploadBinary(
          filePath,
          selectedImageBytes!,
          fileOptions: FileOptions(
            contentType: selectedImage!.mimeType ?? 'image/jpeg',
            upsert: false,
          ),
        );

    return filePath;
  }

  Future<void> sendAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      final imagePath = await _uploadImageIfSelected();
      final locationLabel = _buildLocationLabel();

      await Supabase.instance.client.from('reports').insert({
        'description': descriptionController.text.trim(),
        'location_label': locationLabel,
        'campus': selectedCampus!,
        'latitude': selectedCoordinates?.latitude,
        'longitude': selectedCoordinates?.longitude,
        'image_path': imagePath,
        'status': null,
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr(_language, 'Report sent', 'Zgłoszenie wysłane')),
          content: Text(
            tr(
              _language,
              'Your report has been sent to the administration.',
              'Zgłoszenie zostało wysłane do administracji.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr(_language, 'Could not send report', 'Nie udało się wysłać zgłoszenia')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      appBar: AppBar(
        backgroundColor: appTopBarColor,
        foregroundColor: appTopBarTextColor,
        title: const Text('CAMPUS REPORT SYSTEM'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _LanguageToggle(
              language: _language,
              onChanged: _changeLanguage,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Container(
            width: 760,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: appCardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(_language, 'Report a malfunction', 'Zgłoś usterkę'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    tr(_language, 'Photo', 'Zdjęcie'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: pickImage,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: appImagePlaceholderColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: appTopBarColor,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: selectedImageBytes == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 48,
                                    color: appPrimaryColor,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    tr(
                                      _language,
                                      'Click to upload a photo',
                                      'Kliknij, aby dodać zdjęcie',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    tr(_language, 'Campus and building', 'Kampus i budynek'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 620;

                      final children = [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCampus,
                            hint: Text(
                              tr(_language, 'Select campus', 'Wybierz kampus'),
                            ),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: tr(_language, 'Campus', 'Kampus'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'A',
                                child: Text(
                                  tr(_language, 'Campus A', 'Kampus A'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'B',
                                child: Text(
                                  tr(_language, 'Campus B', 'Kampus B'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'C',
                                child: Text(
                                  tr(_language, 'Campus C', 'Kampus C'),
                                ),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr(
                                  _language,
                                  'Select campus.',
                                  'Wybierz kampus.',
                                );
                              }

                              return null;
                            },
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                selectedCampus = value;
                                selectedBuilding = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12, height: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedBuilding,
                            hint: Text(
                              tr(
                                _language,
                                'Select building or outside',
                                'Wybierz budynek lub teren zewnętrzny',
                              ),
                            ),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: tr(_language, 'Building', 'Budynek'),
                            ),
                            items: filteredBuildings.map((building) {
                              return DropdownMenuItem(
                                value: building,
                                child: Text(
                                  building == 'Outside'
                                      ? tr(
                                          _language,
                                          'Outside',
                                          'Na zewnątrz',
                                        )
                                      : building,
                                ),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr(
                                  _language,
                                  'Select building or outside.',
                                  'Wybierz budynek lub teren zewnętrzny.',
                                );
                              }

                              return null;
                            },
                            onChanged: selectedCampus == null
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedBuilding = value;
                                    });
                                  },
                          ),
                        ),
                      ];

                      if (isNarrow) {
                        return Column(
                          children: children,
                        );
                      }

                      return Row(
                        children: children,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: floorController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: tr(_language, 'Floor', 'Piętro'),
                            hintText: tr(_language, 'e.g. 2', 'np. 2'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: roomController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: tr(
                              _language,
                              'Room / place',
                              'Sala / miejsce',
                            ),
                            hintText: tr(_language, 'e.g. 203', 'np. 203'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    tr(_language, 'Location on map', 'Lokalizacja na mapie'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LocationField(
                    language: _language,
                    controller: locationController,
                    onCoordinatesChanged: (point) {
                      setState(() {
                        selectedCoordinates = point;
                      });
                    },
                  ),
                  const SizedBox(height: 25),
                  Text(
                    tr(_language, 'Description', 'Opis'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: tr(
                        _language,
                        'Describe the problem...',
                        'Opisz problem...',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr(
                          _language,
                          'Describe the problem.',
                          'Opisz problem.',
                        );
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appPrimaryColor,
                        foregroundColor: appTopBarTextColor,
                      ),
                      onPressed: isSaving ? null : sendAlert,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: appCardColor,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        isSaving
                            ? tr(_language, 'Sending...', 'Wysyłanie...')
                            : tr(
                                _language,
                                'Send Alert',
                                'Wyślij zgłoszenie',
                              ),
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.language,
    required this.onChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('EN'),
          selected: language == AppLanguage.en,
          showCheckmark: false,
          selectedColor: appAccentColor,
          backgroundColor: appCardColor,
          side: const BorderSide(color: appAccentColor),
          labelStyle: TextStyle(
            color: language == AppLanguage.en
                ? appPrimaryDarkColor
                : appTopBarColor,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onChanged(AppLanguage.en),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('POL'),
          selected: language == AppLanguage.pl,
          showCheckmark: false,
          selectedColor: appAccentColor,
          backgroundColor: appCardColor,
          side: const BorderSide(color: appAccentColor),
          labelStyle: TextStyle(
            color: language == AppLanguage.pl
                ? appPrimaryDarkColor
                : appTopBarColor,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onChanged(AppLanguage.pl),
        ),
      ],
    );
  }
}

class LocationField extends StatefulWidget {
  const LocationField({
    super.key,
    required this.language,
    required this.controller,
    this.onCoordinatesChanged,
  });

  final AppLanguage language;
  final TextEditingController controller;
  final ValueChanged<LatLng?>? onCoordinatesChanged;

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  bool _loading = false;

  Future<void> _useGpsLocation() async {
    setState(() {
      _loading = true;
    });

    try {
      final currentPoint = await _getCurrentLocation();

      if (!mounted) return;

      final confirmedPoint = await showDialog<LatLng>(
        context: context,
        barrierDismissible: false,
        builder: (_) => OsmMapDialog(
          language: widget.language,
          initialPoint: currentPoint,
        ),
      );

      if (confirmedPoint == null) return;

      final campusBuilding = findNearestCampusBuilding(
        confirmedPoint,
        widget.language,
      );

      final address = campusBuilding ??
          await reverseGeocodeWithNominatim(
            confirmedPoint,
            widget.language,
          );

      if (!mounted) return;

      setState(() {
        widget.controller.text = address;
      });

      widget.onCoordinatesChanged?.call(confirmedPoint);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${tr(widget.language, 'Could not get location', 'Nie udało się pobrać lokalizacji')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          tr(
            widget.language,
            'Location services are disabled.',
            'Usługi lokalizacji są wyłączone.',
          ),
        );
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        tr(
          widget.language,
          'Location permission denied.',
          'Nie udzielono zgody na lokalizację.',
        ),
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        tr(
          widget.language,
          'Location permission is permanently denied.',
          'Zgoda na lokalizację jest trwale zablokowana.',
        ),
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: tr(widget.language, 'Location', 'Lokalizacja'),
        hintText: tr(
          widget.language,
          'Use GPS/map or type additional location details',
          'Użyj GPS/mapy albo wpisz dodatkowe szczegóły lokalizacji',
        ),
        border: const OutlineInputBorder(),
        suffixIcon: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: tr(widget.language, 'Use GPS', 'Użyj GPS'),
                icon: const Icon(Icons.my_location),
                onPressed: _useGpsLocation,
              ),
      ),
      minLines: 1,
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return tr(
            widget.language,
            'Choose location with GPS/map or type location details.',
            'Wybierz lokalizację GPS/mapą albo wpisz szczegóły lokalizacji.',
          );
        }

        return null;
      },
    );
  }
}

class OsmMapDialog extends StatefulWidget {
  const OsmMapDialog({
    super.key,
    required this.language,
    required this.initialPoint,
  });

  final AppLanguage language;
  final LatLng initialPoint;

  @override
  State<OsmMapDialog> createState() => _OsmMapDialogState();
}

class _OsmMapDialogState extends State<OsmMapDialog> {
  late LatLng _point;

  @override
  void initState() {
    super.initState();
    _point = widget.initialPoint;
  }

  void _changePoint(LatLng point) {
    if (!mounted) return;

    setState(() {
      _point = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 650,
          maxHeight: 620,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr(widget.language, 'Confirm location', 'Potwierdź lokalizację'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 430,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _point,
                  initialZoom: 18,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom |
                        InteractiveFlag.scrollWheelZoom,
                  ),
                  onTap: (tapPosition, point) {
                    _changePoint(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'pl.twojanazwa.campus_fault_reporter',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point,
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          size: 52,
                          color: appDangerColor,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lat: ${_point.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_point.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(tr(widget.language, 'Cancel', 'Anuluj')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context, _point);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CampusBuilding {
  const CampusBuilding({
    required this.enName,
    required this.plName,
    required this.point,
  });

  final String enName;
  final String plName;
  final LatLng point;

  String label(AppLanguage language) {
    return tr(language, enName, plName);
  }
}

const List<CampusBuilding> campusBuildings = [
  CampusBuilding(
    enName: 'Building A',
    plName: 'Budynek A',
    point: LatLng(52.229700, 21.012200),
  ),
  CampusBuilding(
    enName: 'Building B',
    plName: 'Budynek B',
    point: LatLng(52.229950, 21.012700),
  ),
  CampusBuilding(
    enName: 'Library',
    plName: 'Biblioteka',
    point: LatLng(52.230250, 21.013100),
  ),
  CampusBuilding(
    enName: 'Dormitory',
    plName: 'Akademik',
    point: LatLng(52.229300, 21.011700),
  ),
];

String? findNearestCampusBuilding(
  LatLng userPoint,
  AppLanguage language,
) {
  const maxDistanceMeters = 80.0;

  final distance = Distance();

  CampusBuilding? nearestBuilding;
  double nearestDistance = double.infinity;

  for (final building in campusBuildings) {
    final meters = distance.as(
      LengthUnit.Meter,
      userPoint,
      building.point,
    );

    if (meters < nearestDistance) {
      nearestDistance = meters;
      nearestBuilding = building;
    }
  }

  if (nearestBuilding != null && nearestDistance <= maxDistanceMeters) {
    return nearestBuilding.label(language);
  }

  return null;
}

Future<String> reverseGeocodeWithNominatim(
  LatLng point,
  AppLanguage language,
) async {
  final fallback = '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';

  try {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': language == AppLanguage.pl ? 'pl' : 'en',
      },
    );

    final headers = <String, String>{};

    if (!kIsWeb) {
      headers['User-Agent'] = 'campus_fault_reporter/1.0';
    }

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      return fallback;
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return fallback;
    }

    final address = decoded['address'];

    if (address is Map<String, dynamic>) {
      final building = address['building'];
      final road = address['road'];
      final houseNumber = address['house_number'];
      final city = address['city'] ?? address['town'] ?? address['village'];

      if (building != null && building.toString().trim().isNotEmpty) {
        return building.toString();
      }

      if (road != null && houseNumber != null) {
        return '$road $houseNumber';
      }

      if (road != null && city != null) {
        return '$road, $city';
      }

      if (road != null) {
        return road.toString();
      }
    }

    final displayName = decoded['display_name'];

    if (displayName is String && displayName.trim().isNotEmpty) {
      return displayName;
    }

    return fallback;
  } catch (e) {
    debugPrint('Reverse geocoding error: $e');
    return fallback;
  }
}
