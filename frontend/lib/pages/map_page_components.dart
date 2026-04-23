part of 'map_page.dart';

class _PanelRoute {
  final int transitionKey;
  final String? title;
  final PanelAnchor anchor;
  final double? width;
  final double? height;
  final double? maxHeight;
  final double? maxHeightFactor;
  final bool adaptHeightToContent;
  final bool expandHorizontal;
  final bool expandVertical;
  final bool scrollContent;
  final bool isAddRoutePanel;
  final bool isReportHazardPanel;
  final bool isHazardDetailsPanel;
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
  final BorderRadius borderRadius;
  final double? contentTopPadding;
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
    this.adaptHeightToContent = false,
    this.expandHorizontal = false,
    this.expandVertical = false,
    this.scrollContent = true,
    this.isAddRoutePanel = false,
    this.isReportHazardPanel = false,
    this.isHazardDetailsPanel = false,
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
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.contentTopPadding,
  });
}

class _TripStartPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final _TripTransportMethod selectedTransport;
  final bool avoidHazards;
  final int selectedPetsCount;
  final String? selectedRouteName;
  final String? errorText;
  final VoidCallback onSelectPets;
  final VoidCallback onSelectRoute;
  final VoidCallback? onEditSelectedRoute;
  final ValueChanged<_TripTransportMethod> onTransportChanged;
  final ValueChanged<bool> onAvoidHazardsChanged;
  final double contentTopPadding;
  final VoidCallback onStartTrip;

  const _TripStartPanelContent({
    required this.isDarkMode,
    required this.selectedTransport,
    required this.avoidHazards,
    required this.selectedPetsCount,
    required this.selectedRouteName,
    required this.errorText,
    required this.onSelectPets,
    required this.onSelectRoute,
    this.onEditSelectedRoute,
    required this.onTransportChanged,
    required this.onAvoidHazardsChanged,
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
                SizedBox(
                  height: 46,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: grayButton,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_TripTransportMethod>(
                        value: selectedTransport,
                        dropdownColor: grayButton,
                        isExpanded: true,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        items: const <DropdownMenuItem<_TripTransportMethod>>[
                          DropdownMenuItem<_TripTransportMethod>(
                            value: _TripTransportMethod.walking,
                            child: Text('A Pie'),
                          ),
                          DropdownMenuItem<_TripTransportMethod>(
                            value: _TripTransportMethod.vehicle,
                            child: Text('En Vehículo'),
                          ),
                        ],
                        onChanged: (_TripTransportMethod? value) {
                          if (value != null) {
                            onTransportChanged(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _TripFieldTitle(label: 'Estrategia de ruta', color: titleColor),
                const SizedBox(height: 6),
                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: grayButton,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Evitar peligros',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: avoidHazards,
                        onChanged: onAvoidHazardsChanged,
                        activeThumbColor: AppPalette.primaryBlue,
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
  final VoidCallback onFinishTrip;

  const _TripActivePanelContent({
    required this.isDarkMode,
    required this.onFinishTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
