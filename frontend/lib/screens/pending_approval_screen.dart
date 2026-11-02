import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/footer_wave.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  // 테마 핑크톤 컬러 정의
  final Color pinkAccent = AppColors.primary;
  final Color purpleAccent = AppColors.primaryEnd;
  final Color subTextColor = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas, // PC 환경 좌우 배경색
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // 📱 메인 콘텐츠 영역
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 64,
                          height: 56,
                          child: Center(child: BrandMark(size: 64)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '프로필 검사 진행 중',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '꼼꼼하게 프로필을 심사하고 있습니다.\n가입 승인까지 조금만 기다려주세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 48),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: pinkAccent,
                            side: BorderSide(color: pinkAccent, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text(
                            '로그인 화면으로 돌아가기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FooterWave(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
