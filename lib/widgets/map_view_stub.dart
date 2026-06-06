import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../providers/language_provider.dart';
import 'package:provider/provider.dart';

class ActiveMapView extends StatefulWidget {
  final List<dynamic> stations;
  final Function(String) onStationSelected;
  final String? selectedStationName;

  const ActiveMapView({
    super.key,
    required this.stations,
    required this.onStationSelected,
    this.selectedStationName,
  });

  @override
  State<ActiveMapView> createState() => _ActiveMapViewState();
}

class _ActiveMapViewState extends State<ActiveMapView> {
  bool _useLiveLocation = false;

  // Simulated live location coordinates (near central Dar es Salaam)
  static const double _simulatedLat = -6.812;
  static const double _simulatedLng = 39.278;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
          math.cos(lat1 * p) * math.cos(lat2 * p) * 
          (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Copy and sort based on simulated coordinates
    final sortedStations = List.from(widget.stations);
    if (_useLiveLocation) {
      sortedStations.sort((a, b) {
        final latA = (a['latitude'] as num?)?.toDouble() ?? 0.0;
        final lngA = (a['longitude'] as num?)?.toDouble() ?? 0.0;
        final latB = (b['latitude'] as num?)?.toDouble() ?? 0.0;
        final lngB = (b['longitude'] as num?)?.toDouble() ?? 0.0;
        final distA = _calculateDistance(_simulatedLat, _simulatedLng, latA, lngA);
        final distB = _calculateDistance(_simulatedLat, _simulatedLng, latB, lngB);
        return distA.compareTo(distB);
      });
    }

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Simulated interactive visual grid representing Dar es Salaam
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blueGrey,
                    image: DecorationImage(
                      image: NetworkImage('https://tile.openstreetmap.org/12/2275/2464.png'), // Sample OSM tile background
                      fit: BoxFit.cover,
                      opacity: 0.3,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GridPaper(
                    color: Colors.white.withOpacity(0.1),
                    divisions: 4,
                    subdivisions: 4,
                  ),
                ),
                
                // Place fuel station pins
                ...widget.stations.map((s) {
                  final name = s['name'] as String? ?? '';
                  final lat = s['latitude'] != null ? (s['latitude'] as num).toDouble() : 0.0;
                  final lng = s['longitude'] != null ? (s['longitude'] as num).toDouble() : 0.0;
                  
                  // Scale coordinates to fit visual screen center
                  final double xOffset = ((lng - 39.2) * 1200).clamp(20.0, 350.0);
                  final double yOffset = ((-lat - 6.7) * 1200).clamp(20.0, 250.0);
                  
                  final isSelected = widget.selectedStationName == name;
                  
                  return Positioned(
                    left: xOffset,
                    top: yOffset,
                    child: GestureDetector(
                      onTap: () => widget.onStationSelected(name),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: isSelected ? 48 : 36,
                            color: isSelected ? Colors.red : AppTheme.gold,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.navy,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Live simulated driver coordinates
                if (_useLiveLocation)
                  Positioned(
                    left: ((_simulatedLng - 39.2) * 1200).clamp(20.0, 350.0),
                    top: ((-_simulatedLat - 6.7) * 1200).clamp(20.0, 250.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 8, spreadRadius: 2)],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 24),
                    ),
                  ),

                // Geolocation control button
                Positioned(
                  right: 12,
                  top: 12,
                  child: FloatingActionButton.small(
                    backgroundColor: _useLiveLocation ? Colors.green : AppTheme.navy,
                    tooltip: 'Use Live Location / Tumia Mahali Ulipo',
                    child: Icon(_useLiveLocation ? Icons.gps_fixed : Icons.gps_not_fixed, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _useLiveLocation = !_useLiveLocation;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: sortedStations.length,
              itemBuilder: (context, i) {
                final s = sortedStations[i];
                final name = s['name'] as String? ?? '';
                final isSelected = widget.selectedStationName == name;

                String distStr = '';
                if (_useLiveLocation) {
                  final lat = (s['latitude'] as num?)?.toDouble() ?? 0.0;
                  final lng = (s['longitude'] as num?)?.toDouble() ?? 0.0;
                  final dist = _calculateDistance(_simulatedLat, _simulatedLng, lat, lng);
                  distStr = '${dist.toStringAsFixed(1)} km';
                } else {
                  distStr = '${(1.5 + i * 0.8).toStringAsFixed(1)} km';
                }
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: isSelected ? Colors.amber[50] : Colors.white,
                  shape: isSelected
                      ? RoundedRectangleBorder(
                          side: const BorderSide(color: AppTheme.gold, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.navy,
                      child: Icon(Icons.local_gas_station, color: Colors.white),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s['district'] ?? ''} - ${lang.translate('station_distance')}: $distStr'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () => widget.onStationSelected(name),
                            child: Text(lang.translate('station_select_btn')),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
