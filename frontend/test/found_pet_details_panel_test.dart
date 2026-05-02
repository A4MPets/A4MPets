import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/found_pet_report_record.dart';
import 'package:frontend/models/lost_pet_report_record.dart';
import 'package:frontend/models/pet_record.dart';
import 'package:frontend/widgets/found_pet_details_panel.dart';

void main() {
  testWidgets('linked lost report is shown as a navigation card', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    final DateTime now = DateTime(2026, 5, 1);
    final PetRecord pet = PetRecord(
      id: 10,
      localUuid: 'pet-10',
      remoteId: '10',
      syncStatus: 'synced',
      lastModifiedAt: now,
      name: 'Luna',
      photoPath: null,
      totalWalks: 2,
      registeredAt: now,
      adoptionDate: null,
      birthDate: null,
      status: 'perdida',
      isOwnerless: false,
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );
    final LostPetReportRecord lostReport = LostPetReportRecord(
      id: 20,
      localUuid: 'lost-20',
      remoteId: '20',
      syncStatus: 'synced',
      lastModifiedAt: now,
      petId: pet.id,
      petLocalUuid: pet.localUuid,
      lastSeenLatitude: 3.45,
      lastSeenLongitude: -76.53,
      details: 'Tiene collar amarillo',
      disappearanceDate: now,
      photoUrl: null,
      phone: '3000000000',
      comments: const [],
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );
    final FoundPetReportRecord foundReport = FoundPetReportRecord(
      id: 30,
      localUuid: 'found-30',
      remoteId: '30',
      syncStatus: 'synced',
      lastModifiedAt: now,
      petId: pet.id,
      petLocalUuid: pet.localUuid,
      matchedLostPetReportId: lostReport.id,
      latitude: 3.46,
      longitude: -76.54,
      details: 'La vi cerca del parque',
      foundDate: now,
      photoUrl: null,
      phone: null,
      comments: const [],
      createdAt: now,
      updatedAt: now,
      needsSync: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 620,
            width: 380,
            child: FoundPetDetailsPanelContent(
              isDarkMode: false,
              report: foundReport,
              pet: pet,
              matchedLostPetReport: lostReport,
              onViewMatchedLostReport: () => taps += 1,
              onViewComments: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Detalles del reporte perdido'), findsNothing);
    expect(find.text('Tiene collar amarillo'), findsOneWidget);

    await tester.tap(find.text('Luna').last);
    expect(taps, 1);
  });
}
