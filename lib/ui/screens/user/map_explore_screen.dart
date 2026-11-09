import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_format.dart';
import '../../../data/models/property_model.dart';
import '../../../providers/property_provider.dart';
import 'property_detail_screen.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  PropertyModel? _selectedProperty;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PropertyProvider>();
    final properties = provider.nearbyProperties.isNotEmpty
        ? provider.nearbyProperties
        : provider.allProperties;

    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('user_pos'),
        position: LatLng(provider.currentLat, provider.currentLng),
        infoWindow: const InfoWindow(title: 'Posisi Kamu Saat Ini'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      ...properties.map(
        (prop) => Marker(
          markerId: MarkerId('prop_${prop.id}'),
          position: LatLng(prop.latitude, prop.longitude),
          infoWindow: InfoWindow(
            title: prop.title,
            snippet: CurrencyFormat.toRupiah(prop.priceMonthly),
          ),
          onTap: () => setState(() => _selectedProperty = prop),
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kos & Kontrakan Terdekat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(provider.currentLat, provider.currentLng),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            onTap: (_) => setState(() => _selectedProperty = null),
          ),
          if (_selectedProperty != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedProperty!.typeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (_selectedProperty!.distanceKm != null)
                            Text(
                              '${_selectedProperty!.distanceKm!.toStringAsFixed(2)} KM dari kamu',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedProperty!.title,
                        style: AppStyles.heading2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedProperty!.address,
                        style: AppStyles.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyFormat.toRupiah(_selectedProperty!.priceMonthly)} / bln',
                            style: AppStyles.priceText,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PropertyDetailScreen(
                                    propertyId: _selectedProperty!.id,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Lihat Detail'),
                          ),
                        ],
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
