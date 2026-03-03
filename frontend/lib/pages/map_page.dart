import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/theme_provider.dart';
import '../widgets/map_widget.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDarkMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: Stack(
        children: [
          /// Mapa adaptable
          Positioned.fill(
            child: MapWidget(
              isDarkMode: isDarkMode,
              center: const LatLng(3.4516, -76.5320),
              zoom: 13,
            ),
          ),

          /// Botón abajo izquierda
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: "themeToggle",
              onPressed: () {
                ref.read(themeModeProvider.notifier).state = !isDarkMode;
              },
              child: Icon(
                isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
