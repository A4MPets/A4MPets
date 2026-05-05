import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class PanelEntry {
  final PanelKind kind;
  final int transitionKey;
  final bool isMinimized;

  const PanelEntry({
    required this.kind,
    required this.transitionKey,
    this.isMinimized = false,
  });

  PanelEntry copyWith({
    PanelKind? kind,
    int? transitionKey,
    bool? isMinimized,
  }) {
    return PanelEntry(
      kind: kind ?? this.kind,
      transitionKey: transitionKey ?? this.transitionKey,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

class PanelFlowState {
  final List<PanelEntry> stack;
  final int transitionSeed;

  const PanelFlowState({
    this.stack = const <PanelEntry>[],
    this.transitionSeed = 0,
  });

  PanelEntry? get activePanel => stack.isEmpty ? null : stack.last;

  bool get hasOpenPanels => stack.isNotEmpty;

  PanelFlowState copyWith({List<PanelEntry>? stack, int? transitionSeed}) {
    return PanelFlowState(
      stack: stack ?? this.stack,
      transitionSeed: transitionSeed ?? this.transitionSeed,
    );
  }
}

final panelFlowProvider = NotifierProvider<PanelFlowController, PanelFlowState>(
  PanelFlowController.new,
);

class PanelFlowController extends Notifier<PanelFlowState> {
  @override
  PanelFlowState build() {
    return const PanelFlowState();
  }

  void push(PanelKind kind) {
    final int nextSeed = state.transitionSeed + 1;
    state = state.copyWith(
      transitionSeed: nextSeed,
      stack: <PanelEntry>[
        ...state.stack,
        PanelEntry(kind: kind, transitionKey: nextSeed),
      ],
    );
  }

  void replaceTop(PanelKind kind) {
    final int nextSeed = state.transitionSeed + 1;
    final List<PanelEntry> nextStack = List<PanelEntry>.from(state.stack);
    if (nextStack.isNotEmpty) {
      nextStack.removeLast();
    }
    nextStack.add(PanelEntry(kind: kind, transitionKey: nextSeed));
    state = state.copyWith(stack: nextStack, transitionSeed: nextSeed);
  }

  void pop() {
    if (state.stack.isEmpty) {
      return;
    }
    state = state.copyWith(
      stack: state.stack.take(state.stack.length - 1).toList(growable: false),
    );
  }

  void removeWhere(bool Function(PanelEntry panel) test) {
    state = state.copyWith(
      stack: state.stack.where((PanelEntry panel) => !test(panel)).toList(),
    );
  }

  void clear() {
    state = state.copyWith(stack: const <PanelEntry>[]);
  }

  void replace(PanelFlowState nextState) {
    state = nextState;
  }

  void setActiveMinimized(bool isMinimized) {
    if (state.stack.isEmpty) {
      return;
    }
    final List<PanelEntry> nextStack = List<PanelEntry>.from(state.stack);
    nextStack[nextStack.length - 1] = nextStack.last.copyWith(
      isMinimized: isMinimized,
    );
    state = state.copyWith(stack: nextStack);
  }

  void toggleActiveMinimized() {
    final PanelEntry? activePanel = state.activePanel;
    if (activePanel == null) {
      return;
    }
    setActiveMinimized(!activePanel.isMinimized);
  }
}
