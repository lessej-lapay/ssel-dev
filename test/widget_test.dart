import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soilsafe_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('unauthenticated app shows the SoilSAFE login screen', (tester) async {
    await tester.pumpWidget(const SoilSafeApp());
    await tester.pump();

    expect(find.text('SoilSAFE'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Farmer Account'), findsOneWidget);
  });
}
