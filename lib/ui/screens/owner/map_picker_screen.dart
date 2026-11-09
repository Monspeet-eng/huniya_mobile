import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geser Peta ke Titik Lokasi Kos'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onCameraMove: (pos) {
              _currentCenter = pos.target;
            },
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_on,
                size: 48,
                color: AppColors.danger,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Koordinat Terpilih: ${_currentCenter.latitude.toStringAsFixed(6)}, ${_currentCenter.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Gunakan Titik Lokasi Ini',
                      icon: Icons.check_circle_outline,
                      onPressed: () => Navigator.pop(context, _currentCenter),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
