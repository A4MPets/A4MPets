part of 'map_page.dart';

class _PanelRoute {
  final int transitionKey;
  final String? title;
  final PanelAnchor anchor;
  final double? width;
  final double? height;
  final double? maxHeight;
  final double? maxHeightFactor;
  final double? mobileMaxHeightFactor;
  final double? desktopMaxHeightFactor;
  final bool adaptHeightToContent;
  final bool expandHorizontal;
  final bool expandVertical;
  final bool scrollContent;
  final bool isAddRoutePanel;
  final bool isReportSelectorPanel;
  final bool isReportHazardPanel;
  final bool isLostPetReportPanel;
  final bool isFoundPetReportPanel;
  final bool isGenericReportPanel;
  final bool isHazardDetailsPanel;
  final bool isLostPetDetailsPanel;
  final bool isFoundPetDetailsPanel;
  final bool isGenericReportDetailsPanel;
  final bool isHazardSettingsPanel;
  final bool isHazardCommentsPanel;
  final bool isManagePetsPanel;
  final bool isManageRoutesPanel;
  final bool isProfilePanel;
  final bool isLoginPanel;
  final bool isRegisterPanel;
  final bool isTripStartPanel;
  final bool isTripPanel;
  final bool isTripPetSelectionPanel;
  final bool isTripRouteSelectionPanel;
  final bool canMinimize;
  final bool isMinimized;
  final double minimizedHeight;
  final BorderRadius borderRadius;
  final double? contentTopPadding;
  final VoidCallback? onToggleMinimize;
  final Widget Function(BuildContext context) contentBuilder;

  _PanelRoute({
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
    this.isAddRoutePanel = false,
    this.isReportSelectorPanel = false,
    this.isReportHazardPanel = false,
    this.isLostPetReportPanel = false,
    this.isFoundPetReportPanel = false,
    this.isGenericReportPanel = false,
    this.isHazardDetailsPanel = false,
    this.isLostPetDetailsPanel = false,
    this.isFoundPetDetailsPanel = false,
    this.isGenericReportDetailsPanel = false,
    this.isHazardSettingsPanel = false,
    this.isHazardCommentsPanel = false,
    this.isManagePetsPanel = false,
    this.isManageRoutesPanel = false,
    this.isProfilePanel = false,
    this.isLoginPanel = false,
    this.isRegisterPanel = false,
    this.isTripStartPanel = false,
    this.isTripPanel = false,
    this.isTripPetSelectionPanel = false,
    this.isTripRouteSelectionPanel = false,
    this.canMinimize = false,
    this.isMinimized = false,
    this.minimizedHeight = 74,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.contentTopPadding,
    this.onToggleMinimize,
  });
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

  const _ProximityAlertCard({
    required this.isDarkMode,
    required this.onAcknowledge,
    required this.onOpenComments,
  });

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
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '¡Cuidado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estás dentro del radio de afectación de un peligro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onAcknowledge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.primaryBlue,
                        foregroundColor: AppPalette.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'De acuerdo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onOpenComments,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.primaryBlue,
                        side: const BorderSide(color: AppPalette.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Desmentir o Confirmar',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

class _TripStartPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final _TripTransportMethod selectedTransport;
  final Set<String> selectedHazardRiskFilters;
  final int selectedPetsCount;
  final String? selectedRouteName;
  final String? errorText;
  final VoidCallback onSelectPets;
  final VoidCallback onSelectRoute;
  final VoidCallback? onEditSelectedRoute;
  final ValueChanged<_TripTransportMethod> onTransportChanged;
  final void Function(String riskLevelCode, bool value)
  onToggleHazardRiskFilter;
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
    final Color titleColor = isDarkMode
        ? AppPalette.textMutedDark
        : AppPalette.iconGray;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, contentTopPadding, 0, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TripFieldTitle(label: 'Mascotas', color: titleColor),
                const SizedBox(height: 6),
                _TripGrayActionButton(
                  label: selectedPetsCount == 0
                      ? 'Seleccionar'
                      : 'Mascotas seleccionadas: $selectedPetsCount',
                  backgroundColor: grayButton,
                  textColor: textColor,
                  onPressed: onSelectPets,
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(
                  label: 'Método de transporte',
                  color: titleColor,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _TripTransportButton(
                        label: 'A pie',
                        isDarkMode: isDarkMode,
                        isSelected:
                            selectedTransport == _TripTransportMethod.walking,
                        onPressed: () => onTransportChanged(
                          _TripTransportMethod.walking,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TripTransportButton(
                        label: 'En vehículo',
                        isDarkMode: isDarkMode,
                        isSelected:
                            selectedTransport == _TripTransportMethod.vehicle,
                        onPressed: () => onTransportChanged(
                          _TripTransportMethod.vehicle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(label: 'Evitar peligros', color: titleColor),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: grayButton,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _TripRiskFilterCheckbox(
                        label: 'Bajo',
                        value: selectedHazardRiskFilters.contains('low'),
                        textColor: textColor,
                        onChanged: (bool value) =>
                            onToggleHazardRiskFilter('low', value),
                      ),
                      _TripRiskFilterCheckbox(
                        label: 'Medio',
                        value: selectedHazardRiskFilters.contains('medium'),
                        textColor: textColor,
                        onChanged: (bool value) =>
                            onToggleHazardRiskFilter('medium', value),
                      ),
                      _TripRiskFilterCheckbox(
                        label: 'Alto',
                        value: selectedHazardRiskFilters.contains('high'),
                        textColor: textColor,
                        onChanged: (bool value) =>
                            onToggleHazardRiskFilter('high', value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(label: 'Ruta', color: titleColor),
                const SizedBox(height: 6),
                _TripGrayActionButton(
                  label: selectedRouteName == null
                      ? 'Seleccionar'
                      : 'Ruta: $selectedRouteName',
                  backgroundColor: grayButton,
                  textColor: textColor,
                  onPressed: onSelectRoute,
                ),
                if (selectedRouteName != null &&
                    onEditSelectedRoute != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: onEditSelectedRoute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.primaryBlue,
                        side: const BorderSide(
                          color: AppPalette.primaryBlue,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text(
                        'Editar ruta seleccionada',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (errorText != null && errorText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppPalette.dangerRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onStartTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Iniciar Viaje',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _TripPetSelectionPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final AsyncValue<List<PetRecord>> petsValue;
  final Set<int> selectedPetIds;
  final VoidCallback onAddPetPressed;
  final ValueChanged<int> onTogglePet;
  final VoidCallback onDone;

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
              if (pets.isEmpty) {
                return Center(
                  child: Text(
                    'No hay mascotas registradas',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                itemCount: pets.length,
                itemBuilder: (BuildContext context, int index) {
                  final PetRecord pet = pets[index];
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
                              : Colors.transparent,
                          width: selected ? 2 : 0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    pet.photoPath == null ||
                                        pet.photoPath!.trim().isEmpty
                                    ? Container(
                                        color: AppPalette.placeholderGray,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.pets,
                                          color: AppPalette.iconGray,
                                          size: 28,
                                        ),
                                      )
                                    : buildLocalImageWidget(
                                        source: pet.photoPath,
                                        fit: BoxFit.cover,
                                        fallback: Container(
                                          color: AppPalette.placeholderGray,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.pets,
                                            color: AppPalette.iconGray,
                                            size: 28,
                                          ),
                                        ),
                                        errorBuilder:
                                            (
                                              BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace,
                                            ) {
                                              return Container(
                                                color:
                                                    AppPalette.placeholderGray,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.pets,
                                                  color: AppPalette.iconGray,
                                                  size: 28,
                                                ),
                                              );
                                            },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pet.name,
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
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) => Center(
              child: Text(
                'No se pudieron cargar las mascotas',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: _TripGrayActionButton(
            label: 'Agregar mascota',
            backgroundColor: bgColor,
            textColor: textColor,
            onPressed: onAddPetPressed,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Listo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
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
    final Color titleColor = isDarkMode
        ? AppPalette.textMutedDark
        : AppPalette.iconGray;

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
                isSelected:
                    selectedTransport == _TripTransportMethod.walking,
                onPressed: () =>
                    onTransportChanged(_TripTransportMethod.walking),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TripTransportButton(
                label: 'En vehículo',
                isDarkMode: isDarkMode,
                isSelected:
                    selectedTransport == _TripTransportMethod.vehicle,
                onPressed: () =>
                    onTransportChanged(_TripTransportMethod.vehicle),
              ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onFinishTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Terminar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _TripArrivalPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onAcknowledge;

  const _TripArrivalPanelContent({
    required this.isDarkMode,
    required this.onAcknowledge,
  });

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
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: onAcknowledge,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'De acuerdo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
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
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _TripGrayActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TripTransportButton extends StatelessWidget {
  final String label;
  final bool isDarkMode;
  final bool isSelected;
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
          backgroundColor: isSelected
              ? AppPalette.primaryBlue
              : AppPalette.cardBackground(isDarkMode),
          foregroundColor: isSelected
              ? AppPalette.white
              : AppPalette.primaryBlue,
          elevation: 0,
          side: BorderSide(
            color: isSelected
                ? AppPalette.primaryBlue
                : AppPalette.primaryBlue.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
