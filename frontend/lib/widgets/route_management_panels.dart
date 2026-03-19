import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';

// ───────────────────────────── Gestionar Rutas ─────────────────────────────

class ManageRoutesPanelContent extends ConsumerWidget {
  final bool isDarkMode;
  final VoidCallback onAddRoutePressed;
  final void Function(RouteRecord route) onRoutePressed;
  final void Function(RouteRecord route)? onEditRoutePressed;
  final void Function(RouteRecord route)? onDeleteRoutePressed;
  final int? selectedRouteId;

  const ManageRoutesPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onAddRoutePressed,
    required this.onRoutePressed,
    this.onEditRoutePressed,
    this.onDeleteRoutePressed,
    this.selectedRouteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RouteRecord>> routesValue =
        ref.watch(routesControllerProvider);

    final Color cardBorder = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gridMaxWidth = math.min(constraints.maxWidth, 320);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: gridMaxWidth,
                  height: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder),
                  ),
                  child: routesValue.when(
                    data: (List<RouteRecord> routes) {
                      if (routes.isEmpty) {
                        return Center(
                          child: Text(
                            'Aún no has agregado rutas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: routes.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _RouteCard(
                            route: routes[index],
                            isDarkMode: isDarkMode,
                            isSelected: selectedRouteId == routes[index].id,
                            onPressed: () => onRoutePressed(routes[index]),
                            onEditPressed: onEditRoutePressed == null
                              ? null
                              : () => onEditRoutePressed!(routes[index]),
                            onDeletePressed: onDeleteRoutePressed == null
                              ? null
                              : () => onDeleteRoutePressed!(routes[index]),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(
                        'No se pudieron cargar las rutas',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onAddRoutePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryBlue,
                  foregroundColor: AppPalette.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Agregar ruta',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteRecord route;
  final bool isDarkMode;
  final bool isSelected;
  final VoidCallback onPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const _RouteCard({
    required this.route,
    required this.isDarkMode,
    required this.isSelected,
    required this.onPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemBackground = AppPalette.cardBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: itemBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppPalette.primaryBlue
                : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.expand(
                      child: _RouteCardPlaceholder(
                          pointCount: route.points.length),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onEditPressed,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppPalette.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings,
                          size: 15,
                          color: AppPalette.charcoal,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDeletePressed,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppPalette.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 15,
                          color: AppPalette.charcoal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              route.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCardPlaceholder extends StatelessWidget {
  final int pointCount;

  const _RouteCardPlaceholder({required this.pointCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.route,
              size: 46,
              color: AppPalette.primaryBlue.withValues(alpha: 0.75),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pointCount pts.',
                style: const TextStyle(
                  color: AppPalette.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Agregar Ruta ────────────────────────────────

class AddRoutePanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final List<LatLng> points;
  final bool isAddToolSelected;
  final bool isEditToolSelected;
  final VoidCallback onSelectAddTool;
  final VoidCallback onSelectEditTool;
  final int? selectedPointIndex;
  final void Function(int index) onSelectPointForMapEdit;
  final VoidCallback onRequestCurrentLocation;
  final void Function(int oldIndex, int newIndex) onReorderPoints;
  final void Function(int index) onRemovePoint;
  final bool isEditingExistingRoute;
  final String? initialRouteName;
  final int? routeId;
  final VoidCallback onSavedComplete;

  const AddRoutePanelContent({
    super.key,
    required this.isDarkMode,
    required this.points,
    required this.isAddToolSelected,
    required this.isEditToolSelected,
    required this.onSelectAddTool,
    required this.onSelectEditTool,
    required this.selectedPointIndex,
    required this.onSelectPointForMapEdit,
    required this.onRequestCurrentLocation,
    required this.onReorderPoints,
    required this.onRemovePoint,
    this.isEditingExistingRoute = false,
    this.initialRouteName,
    this.routeId,
    required this.onSavedComplete,
  });

  @override
  ConsumerState<AddRoutePanelContent> createState() =>
      _AddRoutePanelContentState();
}

class _AddRoutePanelContentState extends ConsumerState<AddRoutePanelContent> {
  late final TextEditingController _nameController;
  String _defaultRouteName = 'Ruta 1';
  bool _isSaving = false;
  String? _saveErrorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRouteName ?? '',
    );
    if (widget.initialRouteName == null) {
      _loadDefaultRouteName();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultRouteName() async {
    try {
      final int nextNum = await ref
          .read(routesControllerProvider.notifier)
          .getNextDefaultRouteNumber();
      if (!mounted) return;
      setState(() => _defaultRouteName = 'Ruta $nextNum');
    } catch (_) {
      if (!mounted) return;
      setState(() => _defaultRouteName = 'Ruta 1');
    }
  }

  Future<void> _saveWithName(String name) async {
    setState(() {
      _saveErrorText = null;
    });
    setState(() => _isSaving = true);

    final List<RoutePoint> points = widget.points
        .map((LatLng ll) =>
            RoutePoint(latitude: ll.latitude, longitude: ll.longitude))
        .toList();

    try {
      if (widget.isEditingExistingRoute && widget.routeId != null) {
        await ref.read(routesControllerProvider.notifier).updateRoute(
          routeId: widget.routeId!,
          name: name,
          points: points,
        );
      } else {
        await ref.read(routesControllerProvider.notifier).addRoute(
          name: name,
          points: points,
        );
      }
      if (!mounted) return;
      widget.onSavedComplete();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveErrorText = 'No se pudo guardar la ruta. Intenta nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showNameDialogAndSave() async {
    final TextEditingController dialogController = TextEditingController(
      text: _nameController.text.trim().isEmpty
          ? _defaultRouteName
          : _nameController.text.trim(),
    );

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppPalette.dialogBackground(widget.isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppPalette.border(widget.isDarkMode)),
          ),
          title: Text(
            widget.isEditingExistingRoute ? 'Editar nombre de ruta' : 'Nombre de ruta',
            style: TextStyle(
              color: AppPalette.dialogTitle(widget.isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: dialogController,
            autofocus: true,
            style: TextStyle(color: AppPalette.textPrimary(widget.isDarkMode)),
            decoration: InputDecoration(
              hintText: _defaultRouteName,
              hintStyle: const TextStyle(color: AppPalette.textMutedDark),
              filled: true,
              fillColor: AppPalette.fieldBackground(widget.isDarkMode),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.primaryBlue),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppPalette.dialogCancel(widget.isDarkMode),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final String resolved = dialogController.text.trim().isEmpty
                    ? _defaultRouteName
                    : dialogController.text.trim();
                Navigator.of(dialogContext).pop(resolved);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: AppPalette.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    dialogController.dispose();

    if (name == null || !mounted) {
      return;
    }

    _nameController.text = name;
    await _saveWithName(name);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(widget.isDarkMode);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.location_on,
                size: 15, color: AppPalette.primaryBlue),
            const SizedBox(width: 6),
            Text(
              'Puntos de la ruta',
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            if (widget.points.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppPalette.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.points.length}',
                  style: const TextStyle(
                      color: AppPalette.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // Points list (internal scroll only)
        Expanded(
          child: _RoutePointsContainer(
            isDarkMode: widget.isDarkMode,
            points: widget.points,
            selectedPointIndex: widget.selectedPointIndex,
            onSelectPointForMapEdit: widget.onSelectPointForMapEdit,
            onRemovePoint: widget.onRemovePoint,
            onReorderPoints: widget.onReorderPoints,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Herramientas',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        _ToolMethodRow(
          isDarkMode: widget.isDarkMode,
          isAddToolSelected: widget.isAddToolSelected,
          isEditToolSelected: widget.isEditToolSelected,
          onSelectAddTool: widget.onSelectAddTool,
          onSelectEditTool: widget.onSelectEditTool,
          onAddByLocation: widget.onRequestCurrentLocation,
        ),

        const SizedBox(height: 6),
        Divider(
            height: 1,
            color: AppPalette.border(widget.isDarkMode)
                .withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        if (_saveErrorText != null) ...[
          Text(
            _saveErrorText!,
            style: const TextStyle(
              color: AppPalette.dangerRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Save button
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed:
                (_isSaving || widget.points.isEmpty) ? null : _showNameDialogAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              disabledBackgroundColor:
                  AppPalette.primaryBlue.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppPalette.white),
                  )
                : Text(
                  'Guardar ${widget.isEditingExistingRoute ? 'Cambios' : 'Ruta'}',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Point tile ────────────────────────────────────────

class _RoutePointTile extends StatelessWidget {
  final int index;
  final LatLng point;
  final bool isDarkMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RoutePointTile({
    super.key,
    required this.index,
    required this.point,
    required this.isDarkMode,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isSelected
        ? AppPalette.primaryBlue.withValues(alpha: 0.14)
        : AppPalette.cardBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppPalette.primaryBlue, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: AppPalette.textMutedDark.withValues(alpha: 0.9),
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppPalette.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppPalette.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                style: TextStyle(color: textColor, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 14, color: AppPalette.textMutedDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutePointsContainer extends StatelessWidget {
  final bool isDarkMode;
  final List<LatLng> points;
  final int? selectedPointIndex;
  final void Function(int index) onSelectPointForMapEdit;
  final void Function(int index) onRemovePoint;
  final void Function(int oldIndex, int newIndex) onReorderPoints;

  const _RoutePointsContainer({
    required this.isDarkMode,
    required this.points,
    required this.selectedPointIndex,
    required this.onSelectPointForMapEdit,
    required this.onRemovePoint,
    required this.onReorderPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppPalette.fieldBackground(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPalette.border(isDarkMode).withValues(alpha: 0.5),
        ),
      ),
      child: points.isEmpty
          ? Center(
              child: Text(
                'Sin puntos. Toca el mapa o usa Agregar mi ubicación.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppPalette.textMutedDark,
                  fontSize: 12,
                ),
              ),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: points.length,
              onReorder: onReorderPoints,
              proxyDecorator: (
                Widget child,
                int index,
                Animation<double> animation,
              ) {
                return Material(
                  color: Colors.transparent,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? childWidget) {
                      return Transform.scale(
                        scale: 1.0 + (animation.value * 0.03),
                        child: child,
                      );
                    },
                  ),
                );
              },
              itemBuilder: (BuildContext context, int index) {
                return _RoutePointTile(
                  key: ValueKey<String>(
                    'route-point-$index-${points[index].latitude}-${points[index].longitude}',
                  ),
                  index: index,
                  point: points[index],
                  isDarkMode: isDarkMode,
                  isSelected: selectedPointIndex == index,
                  onTap: () => onSelectPointForMapEdit(index),
                  onRemove: () => onRemovePoint(index),
                );
              },
            ),
    );
  }
}

// ─────────────────────── Add point method row ──────────────────────────────

class _ToolMethodRow extends StatelessWidget {
  final bool isDarkMode;
  final bool isAddToolSelected;
  final bool isEditToolSelected;
  final VoidCallback onSelectAddTool;
  final VoidCallback onSelectEditTool;
  final VoidCallback onAddByLocation;

  const _ToolMethodRow({
    required this.isDarkMode,
    required this.isAddToolSelected,
    required this.isEditToolSelected,
    required this.onSelectAddTool,
    required this.onSelectEditTool,
    required this.onAddByLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodButton(
            icon: Icons.add_location_alt_outlined,
            label: 'Señalar en mapa',
            isActive: isAddToolSelected,
            isDarkMode: isDarkMode,
            onTap: isAddToolSelected ? null : onSelectAddTool,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _MethodButton(
            icon: Icons.edit_location_alt_outlined,
            label: 'Editar puntos',
            isActive: isEditToolSelected,
            isDarkMode: isDarkMode,
            onTap: isEditToolSelected ? null : onSelectEditTool,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _MethodButton(
            icon: Icons.my_location,
            label: 'Agregar mi ubicación',
            isActive: false,
            isDarkMode: isDarkMode,
            onTap: onAddByLocation,
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const _MethodButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = AppPalette.fieldBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppPalette.primaryBlue.withValues(alpha: 0.1)
              : bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppPalette.primaryBlue
                : AppPalette.textMutedDark.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppPalette.primaryBlue : textColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? AppPalette.primaryBlue : textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
