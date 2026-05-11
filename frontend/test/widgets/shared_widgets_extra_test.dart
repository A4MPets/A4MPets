import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/found_pet_report_record.dart';
import 'package:frontend/models/lost_pet_report_record.dart';
import 'package:frontend/models/pet_record.dart';
import 'package:frontend/models/report_comment_record.dart';
import 'package:frontend/widgets/found_pet_details_panel.dart';
import 'package:frontend/widgets/panel_modal.dart';
import 'package:frontend/widgets/reporting_form_widgets.dart';
import 'package:frontend/widgets/shared/image_preview_dialog.dart';
import 'package:frontend/widgets/shared/panel_scroll_view.dart';
import 'package:frontend/widgets/shared/user_identity_header.dart';

void main() {
  Widget app(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
    return MaterialApp(
      themeMode: themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: Scaffold(body: child),
    );
  }

  group('PanelScrollView y AppModalPanel (F2-extra-widgets)', () {
    testWidgets('PanelScrollView renderiza shrinkWrap y spacing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        app(
          const SizedBox(
            height: 180,
            child: PanelScrollView(
              padding: EdgeInsets.all(8),
              scrollbarSpacing: 12,
              shrinkWrap: true,
              child: Text('Contenido desplazable'),
            ),
          ),
        ),
      );

      expect(find.text('Contenido desplazable'), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
    });

    testWidgets('AppModalPanel muestra titulo, loading, minimizar y cerrar', (
      WidgetTester tester,
    ) async {
      int closeCount = 0;
      int minimizeCount = 0;

      await tester.pumpWidget(
        app(
          SizedBox(
            width: 500,
            height: 500,
            child: AppModalPanel(
              isDarkMode: false,
              title: 'Panel QA',
              showLoadingIndicator: true,
              canMinimize: true,
              onToggleMinimize: () => minimizeCount += 1,
              onClosePressed: () => closeCount += 1,
              child: const Text('Cuerpo del panel'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Panel QA'), findsOneWidget);
      expect(find.text('Cuerpo del panel'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Panel QA'));
      await tester.tap(find.byIcon(Icons.close));
      expect(minimizeCount, equals(1));
      expect(closeCount, equals(1));
    });
  });

  group('Reporting widgets (F2-extra-widgets)', () {
    testWidgets('campos y botones disparan callbacks y muestran errores', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String dropdown = 'low';
      String typed = '';
      bool checked = false;
      int picked = 0;
      int secondary = 0;
      int primary = 0;

      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const ReportingFieldErrorText(message: 'Campo requerido'),
                ReportingLabeledField(
                  label: 'Etiqueta',
                  child: const Text('Hijo'),
                ),
                ReportingDropdownField(
                  isDarkMode: false,
                  value: dropdown,
                  items: const <ReportingSelectionOption>[
                    ReportingSelectionOption('low', 'Bajo'),
                    ReportingSelectionOption('high', 'Alto'),
                  ],
                  onChanged: (String value) => dropdown = value,
                ),
                ReportingTextField(
                  isDarkMode: false,
                  controller: TextEditingController(),
                  hintText: 'Describe',
                  errorText: 'Error texto',
                  onChanged: (String value) => typed = value,
                ),
                ReportingPhotoField(
                  isDarkMode: false,
                  photoSource: null,
                  isBusy: false,
                  errorText: 'Error foto',
                  onPickPressed: () => picked += 1,
                ),
                ReportingCheckboxField(
                  isDarkMode: false,
                  value: checked,
                  title: 'Aceptar',
                  subtitle: 'Subtitulo',
                  onChanged: (bool value) => checked = value,
                ),
                ReportingDateField(
                  isDarkMode: false,
                  valueText: '2026-05-08',
                  onTap: () => picked += 1,
                ),
                ReportingSecondaryButton(
                  isDarkMode: false,
                  label: 'Secundario',
                  icon: Icons.add,
                  onPressed: () => secondary += 1,
                ),
                ReportingSelectionButton(
                  isDarkMode: false,
                  label: 'Seleccionar',
                  onPressed: () => secondary += 1,
                ),
                ReportingPrimaryButton(
                  label: 'Guardar',
                  isBusy: false,
                  backgroundColor: Colors.blue,
                  onPressed: () => primary += 1,
                ),
                ReportingPrimaryButton(
                  label: 'Guardando',
                  isBusy: true,
                  backgroundColor: Colors.blue,
                  onPressed: () => primary += 10,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'texto QA');
      await tester.tap(find.text('Bajo'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Alto').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(Icons.edit));
      await tester.tap(find.text('Aceptar'));
      await tester.tap(find.text('2026-05-08'));
      await tester.tap(find.text('Secundario'));
      await tester.tap(find.text('Seleccionar'));
      await tester.tap(find.text('Guardar'));

      expect(dropdown, equals('high'));
      expect(typed, equals('texto QA'));
      expect(checked, isTrue);
      expect(picked, equals(2));
      expect(secondary, equals(2));
      expect(primary, equals(1));
      expect(find.text('Campo requerido'), findsOneWidget);
      expect(find.text('Error texto'), findsOneWidget);
      expect(find.text('Error foto'), findsOneWidget);
    });
  });

  group('Imagenes y header (F2-extra-widgets)', () {
    testWidgets(
      'showImagePreviewDialog ignora fuente vacia y ExpandableImage abre/cierra dialogo',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          app(
            Builder(
              builder: (BuildContext context) {
                return Column(
                  children: <Widget>[
                    TextButton(
                      onPressed: () => showImagePreviewDialog(
                        context,
                        source: '   ',
                        isDarkMode: false,
                      ),
                      child: const Text('Vacio'),
                    ),
                    ExpandableImage(
                      source: 'missing-file.png',
                      isDarkMode: false,
                      child: const Text('Abrir imagen'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Vacio'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);

        await tester.tap(find.text('Abrir imagen'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets(
      'UserIdentityHeader muestra avatar fallback, busy y callback de edicion',
      (WidgetTester tester) async {
        int edits = 0;
        await tester.pumpWidget(
          app(
            UserIdentityHeader(
              isDarkMode: true,
              username: 'QA User',
              onEditAvatarPressed: () => edits += 1,
            ),
          ),
        );

        expect(find.text('QA User'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        await tester.tap(find.byIcon(Icons.edit));
        expect(edits, equals(1));

        await tester.pumpWidget(
          app(
            const UserIdentityHeader(
              isDarkMode: false,
              username: 'QA Busy',
              isEditingAvatar: true,
            ),
          ),
        );
        expect(find.text('QA Busy'), findsOneWidget);
      },
    );
  });

  group('FoundPetDetailsPanelContent (F2-extra-widgets)', () {
    FoundPetReportRecord foundReport() {
      final DateTime now = DateTime(2026, 5, 8);
      return FoundPetReportRecord(
        id: 1,
        localUuid: 'found',
        remoteId: null,
        syncStatus: 'synced',
        lastModifiedAt: now,
        petId: 2,
        petLocalUuid: 'pet',
        matchedLostPetReportId: 3,
        latitude: 3.45,
        longitude: -76.53,
        details: 'Encontrada cerca al parque',
        foundDate: now,
        photoUrl: '/missing-found.png',
        petPhotoUrl: null,
        phone: '3001234567',
        comments: const <ReportCommentRecord>[],
        createdAt: now,
        updatedAt: now,
        needsSync: false,
      );
    }

    PetRecord pet() {
      final DateTime now = DateTime(2026, 1, 2);
      return PetRecord(
        id: 2,
        localUuid: 'pet',
        remoteId: null,
        name: 'Luna',
        photoPath: null,
        totalWalks: 0,
        registeredAt: now,
        adoptionDate: DateTime(2026, 2, 3),
        birthDate: DateTime(2025, 4, 5),
        status: 'normal',
        isOwnerless: false,
        syncStatus: 'synced',
        lastModifiedAt: now,
        createdAt: now,
        updatedAt: now,
        needsSync: false,
      );
    }

    LostPetReportRecord lostReport() {
      final DateTime now = DateTime(2026, 5, 7);
      return LostPetReportRecord(
        id: 3,
        localUuid: 'lost',
        remoteId: null,
        syncStatus: 'synced',
        lastModifiedAt: now,
        petId: 2,
        petLocalUuid: 'pet',
        lastSeenLatitude: 3.45,
        lastSeenLongitude: -76.53,
        details: 'Perdida cerca al parque',
        disappearanceDate: now,
        photoUrl: null,
        petPhotoUrl: null,
        phone: null,
        comments: const <ReportCommentRecord>[],
        createdAt: now,
        updatedAt: now,
        needsSync: false,
      );
    }

    testWidgets('renderiza datos, vinculo, comentarios y borrado debug', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int comments = 0;
      int linked = 0;
      int deleted = 0;

      await tester.pumpWidget(
        app(
          SizedBox(
            height: 1000,
            child: FoundPetDetailsPanelContent(
              isDarkMode: false,
              report: foundReport(),
              pet: pet(),
              matchedLostPetReport: lostReport(),
              onViewMatchedLostReport: () => linked += 1,
              onViewComments: () => comments += 1,
              debugDeleteLabel: 'Eliminar QA',
              onDebugDelete: () => deleted += 1,
            ),
          ),
        ),
      );

      expect(find.text('Mascota encontrada'), findsOneWidget);
      expect(find.text('Luna'), findsWidgets);
      expect(find.text('Encontrada cerca al parque'), findsOneWidget);
      expect(find.text('3001234567'), findsOneWidget);

      await tester.tap(find.text('Ver comentarios'));
      await tester.tap(find.text('Eliminar QA'));
      await tester.tap(find.text('Reporte de perdida: 07/05/2026'));
      expect(comments, equals(1));
      expect(deleted, equals(1));
      expect(linked, equals(1));
    });
  });
}
