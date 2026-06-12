import 'package:beer_tracker/main.dart';
import 'package:beer_tracker/services/beer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the beer tracker shell', (tester) async {
    await tester.pumpWidget(BeerTrackerApp(repository: BeerRepository()));

    expect(find.text('PintDex'), findsOneWidget);
  });
}
