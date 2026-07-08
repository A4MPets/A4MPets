part of 'map_page.dart';

enum PanelKind {
  addRoute,
  reportSelector,
  reportHazard,
  lostPetReport,
  foundPetReport,
  lostPetReportsList,
  foundPetReportsList,
  genericReport,
  hazardDetails,
  lostPetDetails,
  foundPetDetails,
  genericReportDetails,
  hazardSettings,
  hazardComments,
  managePets,
  lostPetPetSelection,
  manageRoutes,
  profile,
  login,
  register,
  tripStart,
  tripActive,
  tripPetSelection,
  tripRouteSelection,
}

const Set<PanelKind> _reportEditorPanelKinds = <PanelKind>{
  PanelKind.reportHazard,
  PanelKind.lostPetReport,
  PanelKind.foundPetReport,
  PanelKind.genericReport,
};
const Set<PanelKind> _reportFlowPanelKinds = <PanelKind>{
  PanelKind.reportSelector,
  PanelKind.lostPetPetSelection,
  PanelKind.lostPetReportsList,
  PanelKind.foundPetReportsList,
  ..._reportEditorPanelKinds,
};
const Set<PanelKind> _reportDetailsPanelKinds = <PanelKind>{
  PanelKind.hazardDetails,
  PanelKind.lostPetDetails,
  PanelKind.foundPetDetails,
  PanelKind.genericReportDetails,
};
const Set<PanelKind> _tripFlowPanelKinds = <PanelKind>{
  PanelKind.tripActive,
  PanelKind.tripStart,
  PanelKind.tripPetSelection,
  PanelKind.tripRouteSelection,
};
const Set<PanelKind> _tripSetupPanelKinds = <PanelKind>{
  PanelKind.tripStart,
  PanelKind.tripPetSelection,
  PanelKind.tripRouteSelection,
};

class _PanelRoute {
  final PanelKind kind;
  final int transitionKey;
  final String? title;
  final PanelAnchor anchor;
  final double? width, height, maxHeight, maxHeightFactor, mobileMaxHeightFactor, desktopMaxHeightFactor;
  final bool adaptHeightToContent, expandHorizontal, expandVertical, scrollContent, canMinimize, isMinimized;
  final double minimizedHeight;
  final BorderRadius borderRadius;
  final double? contentTopPadding;
  final VoidCallback? onToggleMinimize;
  final Widget Function(BuildContext context) contentBuilder;

  _PanelRoute({
    this.kind = PanelKind.profile,
    required this.transitionKey,
    required this.contentBuilder,
    this.title,
    this.anchor = PanelAnchor.topLeft,
    this.width,
    this.height,
    this.maxHeight,
    this.maxHeightFactor,
    this.mobileMaxHeightFactor,
    this.desktopMaxHeightFactor,
    this.adaptHeightToContent = false,
    this.expandHorizontal = false,
    this.expandVertical = false,
    this.scrollContent = true,
    this.canMinimize = false,
    this.isMinimized = false,
    this.minimizedHeight = 74,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.contentTopPadding,
    this.onToggleMinimize,
  });

  bool get isAddRoutePanel => kind == PanelKind.addRoute;
  bool get isReportSelectorPanel => kind == PanelKind.reportSelector;
  bool get isReportHazardPanel => kind == PanelKind.reportHazard;
  bool get isLostPetReportPanel => kind == PanelKind.lostPetReport;
  bool get isFoundPetReportPanel => kind == PanelKind.foundPetReport;
  bool get isGenericReportPanel => kind == PanelKind.genericReport;
  bool get isHazardDetailsPanel => kind == PanelKind.hazardDetails;
  bool get isLostPetDetailsPanel => kind == PanelKind.lostPetDetails;
  bool get isFoundPetDetailsPanel => kind == PanelKind.foundPetDetails;
  bool get isGenericReportDetailsPanel => kind == PanelKind.genericReportDetails;
  bool get isHazardSettingsPanel => kind == PanelKind.hazardSettings;
  bool get isHazardCommentsPanel => kind == PanelKind.hazardComments;
  bool get isManagePetsPanel => kind == PanelKind.managePets;
  bool get isLostPetPetSelectionPanel => kind == PanelKind.lostPetPetSelection;
  bool get isManageRoutesPanel => kind == PanelKind.manageRoutes;
  bool get isProfilePanel => kind == PanelKind.profile;
  bool get isLoginPanel => kind == PanelKind.login;
  bool get isRegisterPanel => kind == PanelKind.register;
  bool get isTripStartPanel => kind == PanelKind.tripStart;
  bool get isTripPanel => kind == PanelKind.tripActive;
  bool get isTripPetSelectionPanel => kind == PanelKind.tripPetSelection;
  bool get isTripRouteSelectionPanel => kind == PanelKind.tripRouteSelection;
  bool get isReportEditorPanel => _reportEditorPanelKinds.contains(kind);
  bool get isReportFlowPanel => _reportFlowPanelKinds.contains(kind);
  bool get isReportDetailsPanel => _reportDetailsPanelKinds.contains(kind);
  bool get isTripFlowPanel => _tripFlowPanelKinds.contains(kind);
  bool get isTripSetupPanel => _tripSetupPanelKinds.contains(kind);
  bool get isTripSelectionPanel => isTripPetSelectionPanel || isTripRouteSelectionPanel;
  bool get isAuthPanel => isLoginPanel || isRegisterPanel || isProfilePanel;
  bool get isPetDataPanel => isManagePetsPanel || isLostPetPetSelectionPanel || isTripPetSelectionPanel;
  bool get isRouteDataPanel => isManageRoutesPanel || isTripRouteSelectionPanel;
  bool get isReportDataPanel => isReportDetailsPanel || isHazardCommentsPanel || isHazardSettingsPanel;
}

class _ProximityAlertTarget {
  final String zoneKey;
  final ReportCommentSubjectType subjectType;
  final int reportId;
  final double distanceMeters;

  const _ProximityAlertTarget({
    required this.zoneKey,
    required this.subjectType,
    required this.reportId,
    required this.distanceMeters,
  });
}

class _ProximityAlertCard extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onAcknowledge;
  final VoidCallback onOpenComments;

  const _ProximityAlertCard({required this.isDarkMode, required this.onAcknowledge, required this.onOpenComments});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color surface = AppPalette.cardBackground(isDarkMode);

    return Center(
      child: IgnorePointer(
        ignoring: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppPalette.border(isDarkMode)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 14)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Cuidado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estás dentro del radio de afectación de un peligro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 18),
                  PanelActionButton(label: 'De acuerdo', onPressed: onAcknowledge, height: 46),
                  const SizedBox(height: 8),
                  PanelActionButton(
                    label: 'Desmentir o Confirmar',
                    onPressed: onOpenComments,
                    height: 46,
                    foregroundColor: AppPalette.primaryBlue,
                    borderColor: AppPalette.primaryBlue,
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

class _TripStartPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final _TripTransportMethod selectedTransport;
  final Set<String> selectedHazardRiskFilters;
  final int selectedPetsCount;
  final String? selectedRouteName, errorText;
  final VoidCallback onSelectPets, onSelectRoute;
  final VoidCallback? onEditSelectedRoute;
  final ValueChanged<_TripTransportMethod> onTransportChanged;
  final void Function(String riskLevelCode, bool value) onToggleHazardRiskFilter;
  final double contentTopPadding;
  final VoidCallback onStartTrip;

  const _TripStartPanelContent({
    required this.isDarkMode,
    required this.selectedTransport,
    required this.selectedHazardRiskFilters,
    required this.selectedPetsCount,
    required this.selectedRouteName,
    required this.errorText,
    required this.onSelectPets,
    required this.onSelectRoute,
    this.onEditSelectedRoute,
    required this.onTransportChanged,
    required this.onToggleHazardRiskFilter,
    this.contentTopPadding = 8,
    required this.onStartTrip,
  });

  @override
  Widget build(BuildContext context) {
    final Color grayButton = AppPalette.cardBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color titleColor = isDarkMode ? AppPalette.textMutedDark : AppPalette.iconGray;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, contentTopPadding, 0, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TripFieldTitle(label: 'Mascotas', color: titleColor),
                const SizedBox(height: 6),
                _TripGrayActionButton(
                  label: selectedPetsCount == 0 ? 'Seleccionar' : 'Mascotas seleccionadas: $selectedPetsCount',
                  semanticLabel: selectedPetsCount == 0
                      ? 'Seleccionar mascotas'
                      : 'Mascotas seleccionadas: $selectedPetsCount',
                  backgroundColor: grayButton,
                  textColor: textColor,
                  onPressed: onSelectPets,
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(label: 'Método de transporte', color: titleColor),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _TripTransportButton(
                        label: 'A pie',
                        isDarkMode: isDarkMode,
                        isSelected: selectedTransport == _TripTransportMethod.walking,
                        onPressed: () => onTransportChanged(_TripTransportMethod.walking),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TripTransportButton(
                        label: 'En vehículo',
                        isDarkMode: isDarkMode,
                        isSelected: selectedTransport == _TripTransportMethod.vehicle,
                        onPressed: () => onTransportChanged(_TripTransportMethod.vehicle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(label: 'Evitar peligros', color: titleColor),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: grayButton, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _TripRiskFilterCheckbox(
                        label: 'Bajo',
                        value: selectedHazardRiskFilters.contains('low'),
                        textColor: textColor,
                        onChanged: (bool value) => onToggleHazardRiskFilter('low', value),
                      ),
                      _TripRiskFilterCheckbox(
                        label: 'Medio',
                        value: selectedHazardRiskFilters.contains('medium'),
                        textColor: textColor,
                        onChanged: (bool value) => onToggleHazardRiskFilter('medium', value),
                      ),
                      _TripRiskFilterCheckbox(
                        label: 'Alto',
                        value: selectedHazardRiskFilters.contains('high'),
                        textColor: textColor,
                        onChanged: (bool value) => onToggleHazardRiskFilter('high', value),
                      ),
                      _TripRiskFilterCheckbox(
                        label: 'Otro',
                        value: selectedHazardRiskFilters.contains(HazardRiskFiltering.other),
                        textColor: textColor,
                        onChanged: (bool value) => onToggleHazardRiskFilter(HazardRiskFiltering.other, value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(label: 'Ruta', color: titleColor),
                const SizedBox(height: 6),
                _TripGrayActionButton(
                  label: selectedRouteName == null ? 'Seleccionar' : 'Ruta: $selectedRouteName',
                  semanticLabel: selectedRouteName == null ? 'Seleccionar ruta' : 'Ruta: $selectedRouteName',
                  backgroundColor: grayButton,
                  textColor: textColor,
                  onPressed: onSelectRoute,
                ),
                if (selectedRouteName != null && onEditSelectedRoute != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: onEditSelectedRoute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.primaryBlue,
                        side: const BorderSide(color: AppPalette.primaryBlue, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text(
                        'Editar ruta seleccionada',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
                if (errorText != null && errorText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppPalette.dangerRed, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Confirmar inicio de viaje',
          button: true,
          onTap: onStartTrip,
          child: PanelActionButton(label: 'Iniciar Viaje', onPressed: onStartTrip, height: 48, fontSize: 15),
        ),
      ],
    );
  }
}

class _TripPetSelectionPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final AsyncValue<List<PetRecord>> petsValue;
  final Set<int> selectedPetIds;
  final VoidCallback onAddPetPressed, onDone;
  final ValueChanged<int> onTogglePet;

  const _TripPetSelectionPanelContent({
    required this.isDarkMode,
    required this.petsValue,
    required this.selectedPetIds,
    required this.onAddPetPressed,
    required this.onTogglePet,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color bgColor = AppPalette.cardBackground(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: petsValue.when(
            data: (List<PetRecord> pets) {
              final List<PetRecord> availablePets = pets.where((PetRecord pet) => !pet.isLost).toList(growable: false);

              if (availablePets.isEmpty) {
                return Center(
                  child: Text(
                    pets.isEmpty ? 'No hay mascotas registradas' : 'No hay mascotas disponibles para iniciar viaje',
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                );
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemCount: availablePets.length,
                itemBuilder: (BuildContext context, int index) {
                  final PetRecord pet = availablePets[index];
                  final bool selected = selectedPetIds.contains(pet.id);

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onTogglePet(pet.id),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppPalette.primaryBlue
                              : (pet.isLost ? AppPalette.reportYellow : Colors.transparent),
                          width: selected || pet.isLost ? 2 : 0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _tripPetPhoto(pet.photoPath),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pet.displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (Object error, StackTrace stackTrace) => Center(
              child: Text(
                error.toString().contains('Debes iniciar sesion')
                    ? 'Inicia sesion para seleccionar tus mascotas'
                    : 'No se pudieron cargar las mascotas',
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: _TripGrayActionButton(
            label: 'Agregar mascota',
            semanticLabel: 'Agregar mascota para viaje',
            backgroundColor: bgColor,
            textColor: textColor,
            onPressed: onAddPetPressed,
          ),
        ),
        const SizedBox(height: 8),
        PanelActionButton(label: 'Listo', onPressed: onDone, height: 46),
      ],
    );
  }
}

Widget _tripPetPhoto(String? source) {
  if (source == null || source.trim().isEmpty) return const _TripPetFallback();
  return buildLocalImageWidget(
    source: source,
    fit: BoxFit.cover,
    fallback: const _TripPetFallback(),
    errorBuilder: (_, _, _) => const _TripPetFallback(),
  );
}

class _TripPetFallback extends StatelessWidget {
  const _TripPetFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppPalette.placeholderGray,
      child: Center(child: Icon(Icons.pets, color: AppPalette.iconGray, size: 28)),
    );
  }
}

class _TripActivePanelContent extends StatelessWidget {
  final bool isDarkMode;
  final _TripTransportMethod selectedTransport;
  final ValueChanged<_TripTransportMethod> onTransportChanged;
  final VoidCallback onFinishTrip;

  const _TripActivePanelContent({
    required this.isDarkMode,
    required this.selectedTransport,
    required this.onTransportChanged,
    required this.onFinishTrip,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDarkMode ? AppPalette.textMutedDark : AppPalette.iconGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TripFieldTitle(label: 'Método de transporte', color: titleColor),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _TripTransportButton(
                label: 'A pie',
                isDarkMode: isDarkMode,
                isSelected: selectedTransport == _TripTransportMethod.walking,
                onPressed: () => onTransportChanged(_TripTransportMethod.walking),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TripTransportButton(
                label: 'En vehículo',
                isDarkMode: isDarkMode,
                isSelected: selectedTransport == _TripTransportMethod.vehicle,
                onPressed: () => onTransportChanged(_TripTransportMethod.vehicle),
              ),
            ),
          ],
        ),
        const Spacer(),
        PanelActionButton(label: 'Terminar', onPressed: onFinishTrip, height: 48, fontSize: 15),
      ],
    );
  }
}

class _TripArrivalPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onAcknowledge;

  const _TripArrivalPanelContent({required this.isDarkMode, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¡Ha llegado a su destino!',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        PanelActionButton(label: 'De acuerdo', onPressed: onAcknowledge, height: 46),
      ],
    );
  }
}

class _TripFieldTitle extends StatelessWidget {
  final String label;
  final Color color;

  const _TripFieldTitle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}

class _TripGrayActionButton extends StatelessWidget {
  final String label;
  final String? semanticLabel;
  final Color backgroundColor, textColor;
  final VoidCallback onPressed;

  const _TripGrayActionButton({
    required this.label,
    this.semanticLabel,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Semantics(
        label: semanticLabel ?? label,
        button: true,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripTransportButton extends StatelessWidget {
  final String label;
  final bool isDarkMode, isSelected;
  final VoidCallback onPressed;

  const _TripTransportButton({
    required this.label,
    required this.isDarkMode,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppPalette.primaryBlue : AppPalette.cardBackground(isDarkMode),
          foregroundColor: isSelected ? AppPalette.white : AppPalette.primaryBlue,
          elevation: 0,
          side: BorderSide(color: isSelected ? AppPalette.primaryBlue : AppPalette.primaryBlue.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _TripRiskFilterCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  const _TripRiskFilterCheckbox({
    required this.label,
    required this.value,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: CheckboxListTile(
        value: value,
        onChanged: (bool? nextValue) => onChanged(nextValue ?? false),
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppPalette.primaryBlue,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          label,
          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
