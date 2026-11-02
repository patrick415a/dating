import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dating_web/screens/Secondary_signup_screen.dart';
import 'package:dating_web/screens/admin_login_screen.dart';
import 'package:dating_web/screens/chat_list_screen.dart';
import 'package:dating_web/screens/community_screen.dart';
import 'package:dating_web/screens/diary_screen.dart';
import 'package:dating_web/screens/login_screen.dart';
import 'package:dating_web/screens/my_page_screen.dart';
import 'package:dating_web/screens/pending_approval_screen.dart';
import 'package:dating_web/screens/signup_profile_screen.dart';
import 'package:dating_web/theme/app_theme.dart';

Widget themed(Widget screen) => MaterialApp(
  theme: AppTheme.light,
  home: screen,
);

void main() {
  test('Light surfaces and primary actions retain readable text contrast', () {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance();
      final second = b.computeLuminance();
      return first > second
          ? (first + 0.05) / (second + 0.05)
          : (second + 0.05) / (first + 0.05);
    }

    expect(contrast(AppColors.text, AppColors.background), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.textSecondary, AppColors.surface), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.onPrimary, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.onPrimary, AppColors.primaryEnd), greaterThanOrEqualTo(4.5));
  });

  testWidgets('Login still validates and opens the original signup flow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(themed(const LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text(AppBrand.name), findsOneWidget);
    await tester.ensureVisible(find.text('로그인'));
    await tester.tap(find.text('로그인'));
    await tester.pump();
    expect(find.text('이메일과 비밀번호를 모두 입력해주세요.'), findsOneWidget);

    final signup = find.textContaining('회원가입', findRichText: true);
    await tester.ensureVisible(signup);
    await tester.tap(signup);
    await tester.pumpAndSettle();
    expect(find.text('나를 소개해요 ✨'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  final screens = <String, Widget>{
    'login': const LoginScreen(),
    'signup': const SignupProfileScreen(),
    'approval': const PendingApprovalScreen(),
    'additional details': const SecondarySignupScreen(userId: 1),
    'community': const CommunityScreen(),
    'diary': const DiaryScreen(),
    'chats': const ChatListScreen(),
    'profile placeholder': const ProfileEditScreen(),
    'photos': const PhotoManagementScreen(),
    'matching placeholder': const MatchingSettingsScreen(),
    'matching history': const MatchingHistoryScreen(),
    'diary history': const DiaryHistoryScreen(),
    'privacy': const PrivacyScreen(),
    'payments': const PaymentHistoryScreen(),
    'admin login': const AdminLoginScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders on a narrow mobile screen', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(themed(entry.value));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
