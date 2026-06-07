import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../config/theme.dart';

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
  late String _viewId;
  StreamSubscription? _msgSub;
  double? _userLat;
  double? _userLng;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
          math.cos(lat1 * p) * math.cos(lat2 * p) * 
          (1 - math.cos((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  void initState() {
    super.initState();
    _viewId = 'osm-map-view-${DateTime.now().millisecondsSinceEpoch}';
    
    // Create HTML iframe
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      // Build stations JS array
      final stationsJs = widget.stations
          .map((s) => '{name: "${s['name']}", lat: ${s['latitude'] ?? -6.8}, lng: ${s['longitude'] ?? 39.28}}')
          .join(',');

      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    body { margin: 0; padding: 0; }
    #map { height: 100vh; width: 100vw; }
    .custom-popup button {
      background: #0D1B2A;
      color: white;
      border: none;
      padding: 6px 12px;
      border-radius: 4px;
      font-weight: bold;
      cursor: pointer;
      margin-top: 5px;
      width: 100%;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <button onclick="locateUser()" style="position: absolute; bottom: 20px; right: 20px; z-index: 1000; background: #FFD700; color: #0D1B2A; border: none; padding: 12px; border-radius: 50%; font-size: 18px; font-weight: bold; cursor: pointer; box-shadow: 0 4px 6px rgba(0,0,0,0.3); width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;">
    📍
  </button>
  <script>
    var map = L.map('map').setView([-6.81, 39.27], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap'
    }).addTo(map);

    var stations = [$stationsJs];
    stations.forEach(function(s) {
      var marker = L.marker([s.lat, s.lng]).addTo(map);
      var popupContent = "<b>" + s.name + "</b><br>" +
                         "<button class='refuel-btn' onclick='window.parent.postMessage(\"refuel:\" + encodeURIComponent(s.name), \"*\")'>Refuel Here</button>";
      marker.bindPopup(popupContent, {className: 'custom-popup'});
    });

    var userMarker = null;
    function locateUser() {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function(position) {
          var lat = position.coords.latitude;
          var lng = position.coords.longitude;
          if (userMarker) {
            map.removeLayer(userMarker);
          }
          userMarker = L.circleMarker([lat, lng], {
            radius: 8,
            fillColor: "#2A9D8F",
            color: "#fff",
            weight: 2,
            opacity: 1,
            fillOpacity: 0.8
          }).addTo(map);
          userMarker.bindPopup("<b>Upo Hapa / You are here</b>").openPopup();
          map.setView([lat, lng], 14);
          window.parent.postMessage("location:" + lat + "," + lng, "*");
        }, function(error) {
          console.log("Geolocation error: " + error.message);
        });
      }
    }
    // Auto locate on start
    setTimeout(locateUser, 500);
  </script>
</body>
</html>
      ''';

      iframe.srcdoc = htmlContent;
      return iframe;
    });

    // Listen to messages from iframe
    _msgSub = html.window.onMessage.listen((event) {
      final String data = event.data.toString();
      if (data.startsWith('refuel:')) {
        final stationName = Uri.decodeComponent(data.substring(7));
        widget.onStationSelected(stationName);
      } else if (data.startsWith('location:')) {
        final parts = data.substring(9).split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null) {
            if (mounted) {
              setState(() {
                _userLat = lat;
                _userLng = lng;
              });
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Dynamic sorting based on live location coordinates
    final sortedStations = List.from(widget.stations);
    if (_userLat != null && _userLng != null) {
      sortedStations.sort((a, b) {
        final latA = double.tryParse(a['latitude']?.toString() ?? '') ?? 0.0;
        final lngA = double.tryParse(a['longitude']?.toString() ?? '') ?? 0.0;
        final latB = double.tryParse(b['latitude']?.toString() ?? '') ?? 0.0;
        final lngB = double.tryParse(b['longitude']?.toString() ?? '') ?? 0.0;
        final distA = _calculateDistance(_userLat!, _userLng!, latA, lngA);
        final distB = _calculateDistance(_userLat!, _userLng!, latB, lngB);
        return distA.compareTo(distB);
      });
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: HtmlElementView(viewType: _viewId),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: sortedStations.length,
            itemBuilder: (context, i) {
              final s = sortedStations[i];
              final name = s['name'] as String? ?? '';
              
              String distStr = '';
              if (_userLat != null && _userLng != null) {
                final lat = double.tryParse(s['latitude']?.toString() ?? '') ?? 0.0;
                final lng = double.tryParse(s['longitude']?.toString() ?? '') ?? 0.0;
                final dist = _calculateDistance(_userLat!, _userLng!, lat, lng);
                distStr = '${dist.toStringAsFixed(1)} km';
              } else {
                distStr = '${(1.5 + i * 0.8).toStringAsFixed(1)} km';
              }

              final isSelected = widget.selectedStationName == name;
              
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
    );
  }
}
