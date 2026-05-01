part of 'map_page.dart';

void _invalidateUserScopedData(WidgetRef ref) {
  ref.invalidate(localUserProfileProvider);
  ref.invalidate(petsControllerProvider);
  ref.invalidate(routesControllerProvider);
  ref.invalidate(hazardReportsControllerProvider);
  ref.invalidate(lostPetReportsControllerProvider);
  ref.invalidate(foundPetReportsControllerProvider);
  ref.invalidate(genericReportsControllerProvider);
}

extension _MapPageAuthAndProfileState on _MapPageState {
  void _openProfilePanel(bool isDarkMode) {
    if (_hasOpenPanels) {
      return;
    }

    _pushPanel(_buildProfileRoute(isDarkMode));
  }

  void _openLoginPanel(bool isDarkMode) {
    _pushPanel(_buildLoginRoute(isDarkMode));
  }

  void _openRegisterPanel(bool isDarkMode) {
    _pushPanel(_buildRegisterRoute(isDarkMode));
  }

  void _switchToLoginPanel(bool isDarkMode) {
    _replaceTopPanel(_buildLoginRoute(isDarkMode));
  }

  void _switchToRegisterPanel(bool isDarkMode) {
    _replaceTopPanel(_buildRegisterRoute(isDarkMode));
  }

  Future<void> _handleLogin(String login, String password) async {
    if (mounted) {
      _updatePageState(() {
        _isAuthRequestLoading = true;
      });
    }

    try {
      await ref
          .read(userLocalRepositoryProvider)
          .login(login: login, password: password);
      await ref.read(localMediaStorageServiceProvider).clearStoredMedia();

      _invalidateUserScopedData(ref);

      if (!mounted) {
        return;
      }

      _updatePageState(() {
        _panelStack.clear();
      });
    } finally {
      if (mounted) {
        _updatePageState(() {
          _isAuthRequestLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister(
    String username,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    if (mounted) {
      _updatePageState(() {
        _isAuthRequestLoading = true;
      });
    }

    try {
      await ref
          .read(userLocalRepositoryProvider)
          .register(
            username: username,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
          );

      _invalidateUserScopedData(ref);

      if (!mounted) {
        return;
      }

      _updatePageState(() {
        _panelStack.clear();
      });
    } finally {
      if (mounted) {
        _updatePageState(() {
          _isAuthRequestLoading = false;
        });
      }
    }
  }

  Future<String?> _handleLogout() async {
    if (mounted) {
      _updatePageState(() {
        _isAuthRequestLoading = true;
      });
    }

    try {
      await ref.read(userLocalRepositoryProvider).logout();
      await ref.read(localMediaStorageServiceProvider).clearStoredMedia();

      _invalidateUserScopedData(ref);

      if (!mounted) {
        return null;
      }

      _updatePageState(() {
        _panelStack.clear();
        _clearDraftRouteVisuals();
        _clearTripSetupState();
        _selectedHazard = null;
      });
      return null;
    } catch (error) {
      return 'No se pudo cerrar sesión: $error';
    } finally {
      if (mounted) {
        _updatePageState(() {
          _isAuthRequestLoading = false;
        });
      }
    }
  }

  void _openManagePetsPanel(bool isDarkMode) {
    _syncAndReloadData();
    _pushPanel(_buildManagePetsRoute(isDarkMode));
  }

  void _openAddPetPanel(bool isDarkMode) {
    _pushPanel(_buildAddPetRoute(isDarkMode));
  }

  void _openAddPetPanelFromTrip(bool isDarkMode) {
    _pushPanel(_buildAddPetRoute(isDarkMode, anchor: PanelAnchor.bottomRight));
  }

  void _openEditPetPanel(bool isDarkMode, PetRecord pet) {
    _pushPanel(_buildEditPetRoute(isDarkMode, pet));
  }

  Future<void> _closeAddPetPanelAfterSave(int petId) async {
    if (!_hasOpenPanels) {
      return;
    }

    final bool returningToTripPetSelection =
        _panelStack.length > 1 &&
        _panelStack[_panelStack.length - 2].isTripPetSelectionPanel;

    _updatePageState(() {
      _panelStack.removeLast();
    });

    if (!returningToTripPetSelection) {
      return;
    }

    await ref.read(petsControllerProvider.notifier).reload();
    if (!mounted) {
      return;
    }

    final bool isDarkMode = ref.read(themeModeProvider);
    _updatePageState(() {
      _selectedTripPetIds.add(petId);
    });
    _returnToTripStartPanel(isDarkMode);
  }

  _PanelRoute _buildProfileRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: null,
      anchor: PanelAnchor.topLeft,
      width: 360,
      height: 370,
      maxHeight: 400,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isProfilePanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ProfileMenuPanel(
          isDarkMode: isDarkMode,
          onLoginPressed: () => _openLoginPanel(isDarkMode),
          onRegisterPressed: () => _openRegisterPanel(isDarkMode),
          onLogoutPressed: _handleLogout,
          onManagePetsPressed: () => _openManagePetsPanel(isDarkMode),
          onManageRoutesPressed: () => _openManageRoutesPanel(isDarkMode),
        );
      },
    );
  }

  _PanelRoute _buildLoginRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Iniciar Sesión',
      anchor: PanelAnchor.topLeft,
      width: 360,
      height: 430,
      maxHeight: 520,
      adaptHeightToContent: true,
      expandHorizontal: false,
      expandVertical: false,
      isLoginPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return LoginPanelContent(
          isDarkMode: isDarkMode,
          onSwitchToRegister: () => _switchToRegisterPanel(isDarkMode),
          onSubmit: _handleLogin,
        );
      },
    );
  }

  _PanelRoute _buildRegisterRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Registrarse',
      anchor: PanelAnchor.topLeft,
      width: 360,
      height: 520,
      maxHeight: 620,
      adaptHeightToContent: true,
      expandHorizontal: false,
      expandVertical: false,
      isRegisterPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return RegisterPanelContent(
          isDarkMode: isDarkMode,
          onSwitchToLogin: () => _switchToLoginPanel(isDarkMode),
          onSubmit: _handleRegister,
        );
      },
    );
  }

  _PanelRoute _buildManagePetsRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Gestionar Mascotas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isManagePetsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ManagePetsPanelContent(
          isDarkMode: isDarkMode,
          onAddPetPressed: () => _openAddPetPanel(isDarkMode),
          onEditPetPressed: (PetRecord pet) =>
              _openEditPetPanel(isDarkMode, pet),
        );
      },
    );
  }

  _PanelRoute _buildAddPetRoute(
    bool isDarkMode, {
    PanelAnchor anchor = PanelAnchor.topLeft,
  }) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Agregar mascota',
      anchor: anchor,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return AddPetPanelContent(
          isDarkMode: isDarkMode,
          onSaved: _closeAddPetPanelAfterSave,
        );
      },
    );
  }

  _PanelRoute _buildEditPetRoute(bool isDarkMode, PetRecord pet) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Editar mascota',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return EditPetPanelContent(
          pet: pet,
          isDarkMode: isDarkMode,
          onSaved: _closeCurrentPanel,
        );
      },
    );
  }
}
