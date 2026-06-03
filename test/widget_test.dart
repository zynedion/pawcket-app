import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawcket/main.dart';
import 'package:pawcket/widgets/common/mr_oyen_avatar.dart';

void main() {
  testWidgets('Onboarding welcome screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the title and subtitle are present
    expect(find.text('Welcome to Pawcket'), findsOneWidget);
    expect(
      find.text('Your lazy financial buddy who gets bossy when you overspend.'),
      findsOneWidget,
    );

    // Verify that the Get Started button is present
    expect(find.text('Get Started'), findsOneWidget);

    // Verify MrOyenAvatar is present
    expect(find.byType(MrOyenAvatar), findsOneWidget);
  });
}
