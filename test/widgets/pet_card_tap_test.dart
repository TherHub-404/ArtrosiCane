import 'package:artrosi_cane/features/home/presentation/widgets/pet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    required VoidCallback onTap,
    bool insidePageView = false,
  }) {
    final card = Center(
      child: PetCard(
        name: 'Luna',
        breed: 'Labrador',
        age: 7,
        weight: 24.5,
        imagePath: 'assets/first-dog.png',
        backgroundColor: Colors.white,
        onTap: onTap,
      ),
    );

    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 420,
          child: insidePageView ? PageView(children: [card]) : card,
        ),
      ),
    );
  }

  testWidgets('PetCard alone responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(buildHarness(onTap: () => tapped = true));
    await tester.tapAt(tester.getCenter(find.byType(PetCard).first));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('PetCard inside PageView responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      buildHarness(onTap: () => tapped = true, insidePageView: true),
    );
    await tester.tapAt(tester.getCenter(find.byType(PetCard).first));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
