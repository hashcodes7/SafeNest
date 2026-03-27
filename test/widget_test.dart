import 'package:flutter_test/flutter_test.dart';
import 'package:safenest/main.dart';
import 'package:safenest/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const SafeNestApp(),
      ),
    );

    // Verify that the title 'SafeNest' is shown.
    expect(find.text('SafeNest'), findsOneWidget);
  });
}
