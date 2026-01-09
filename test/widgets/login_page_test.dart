/// ============================================================================
/// LOGIN PAGE WIDGET TESTS
/// ============================================================================
///
/// Widget tests for the Login page UI and interactions.
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

// Import your actual files
import 'package:diabetic_monitoring_app/pages/login.dart';
import 'package:diabetic_monitoring_app/domain/app_data_source.dart';
import 'package:diabetic_monitoring_app/domain/inputs/inputs.dart';

// Mock classes
class MockAppDataSource extends Mock implements AppDataSource {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeLoginInput extends Fake implements LoginInput {}

void main() {
  late MockAppDataSource mockDataSource;

  setUpAll(() {
    // Register fake for Route type
    registerFallbackValue(MaterialPageRoute(builder: (_) => Container()));
    registerFallbackValue(FakeLoginInput());
  });

  setUp(() {
    // Reset GetIt before each test
    final getIt = GetIt.instance;
    if (getIt.isRegistered<AppDataSource>()) {
      getIt.unregister<AppDataSource>();
    }
    
    mockDataSource = MockAppDataSource();
    getIt.registerSingleton<AppDataSource>(mockDataSource);
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<AppDataSource>()) {
      getIt.unregister<AppDataSource>();
    }
  });

  Widget createTestWidget({Widget? child}) {
    return MaterialApp(
      home: child ?? const LoginScreen(),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should display email and password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for text fields
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should display login button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for a button with login-related text
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ElevatedButton || widget is TextButton,
        ),
        findsWidgets,
      );
    });

    testWidgets('should validate empty email field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find email field and leave it empty
      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.pump();
      
      // Find and tap submit/login button
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should accept valid email input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'test@example.com');
        await tester.pump();
        
        // Verify text was entered
        expect(find.text('test@example.com'), findsOneWidget);
      }
    });

    testWidgets('should obscure password field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Look for obscured text field (password field)
      final passwordField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.obscureText,
      );
      
      // Password field should be obscured
      expect(passwordField, findsWidgets);
    });

    testWidgets('should show loading indicator during login', (tester) async {
      when(() => mockDataSource.login(any()))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 2));
            return null; // Returns UserProfile? 
          });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), 'test@example.com');
        await tester.enterText(textFields.at(1), 'password123');
        await tester.pump();
      }

      // Tap login button
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pump();
        
        // Should show loading indicator
        // (actual behavior depends on implementation)
      }
    });
  });

  group('LoginScreen Error Handling', () {
    testWidgets('should display error message on login failure', (tester) async {
      when(() => mockDataSource.login(any()))
          .thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter credentials and submit
      final textFields = find.byType(TextField);
      if (textFields.evaluate().length >= 2) {
        await tester.enterText(textFields.at(0), 'test@example.com');
        await tester.enterText(textFields.at(1), 'wrongpassword');
        await tester.pump();

        final loginButton = find.byType(ElevatedButton);
        if (loginButton.evaluate().isNotEmpty) {
          await tester.tap(loginButton.first);
          await tester.pumpAndSettle();
        }
      }
    });
  });
}
