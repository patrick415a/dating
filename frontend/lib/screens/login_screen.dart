import 'package:flutter/material.dart';
import 'signup_profile_screen.dart';
import '../main.dart';

// 백엔드와 통신하기 위한 패키지
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// 수질검사
import './pending_approval_screen.dart';
import './admin_login_screen.dart';
import './secondary_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color bgColor = const Color(0xFF12121A);
  final Color cardColor = const Color(0xFF22222E);
  final Color pinkAccent = const Color(0xFFFF4B93);
  final Color purpleAccent = const Color(0xFFB635F7);
  final Color textColor = Colors.white;
  final Color subTextColor = const Color(0xFFA0A0B0);

  // 상태관리 변수 들
  bool _stayLoggedIn = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 접속 기기에 맞춰 로그인 api 주소 자동 세팅
  String get _apiUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/login';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/login';
    } else {
      return 'http://localhost:3000/api/login';
    }
  }

  // 요청 보내도 상태 판별
  Future<void> _loginToBackend() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 플루터 특성상 스낵바가 나옴
    if(email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 모두 입력해주세요'))
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl), 
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'email': email, 'password': password})
      );
      final data = jsonDecode(response.body);
      // 성공 시
      if(response.statusCode == 200 && data['success'] == true){
        if (mounted) {
          final user = data['user'];
          if(user['phone_number'] == null || user['occupation'] == null){
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => SecondarySignupScreen(userId: user['id']))
            );
          }else {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const RootScreen())
            );
          }
        }
      }else if(response.statusCode == 403) { // 승인대기 혹은 영구정지
        if(data['message'] != null && data['message'].contains('승인')){
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PendingApprovalScreen())
            );
          }
        }else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '접근할 수 없는 계정입니다'), 
              backgroundColor: Colors.redAccent, 
              duration: const Duration(seconds: 3)
            ),
          );
        }
      }else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '이메일이나 비밀번호가 일치하지않습니다'))
        );
      }
    }catch (e){
      print("로그인 통신 에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와 연결할 수 없습니다 백엔드 연결 상태를 확인해주세요'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            _buildBackgroundGlow(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogo(), const SizedBox(height: 32),
                    _buildHeader(), const SizedBox(height: 48),
                    _buildEmailField(), const SizedBox(height: 24),
                    _buildPasswordField(), const SizedBox(height: 16),
                    _buildOptionsRow(), const SizedBox(height: 32),
                    _buildLoginButton(), const SizedBox(height: 32),
                    _buildDivider(), const SizedBox(height: 32),
                    _buildKakaoButton(), const SizedBox(height: 16),
                    _buildAppleButton(), const SizedBox(height: 48),
                    _buildSignupLink()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(){
    return GestureDetector(
      onLongPress: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginScreen()));
      },
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: pinkAccent, size: 24),
          const SizedBox(width: 8),
          Text('SPARK', style: TextStyle(color: pinkAccent, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildHeader(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('다시 만나서 \n 반가워요', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 12),
        Text('로그인하고 새로운 인연을 만나보세요', style: TextStyle(color: subTextColor, fontSize: 16)),
      ],
    );
  }

  Widget _buildEmailField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이메일', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController, hint: '이메일을 입력하세요',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress
        )
      ],
    );
  }

  Widget _buildPasswordField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('비밀번호', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _passwordController, hint: '비밀번호를 입력하세요',
          icon: Icons.lock_outline,
          isPassword: true,
        )
      ],
    );
  }

  Widget _buildOptionsRow(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap:(){
            setState(() => _stayLoggedIn = !_stayLoggedIn);
          },
          child: Row(
            children: [
              Container(
                width: 20,
                decoration: BoxDecoration(
                  color: _stayLoggedIn ? pinkAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _stayLoggedIn ? pinkAccent : subTextColor)
                ),
                child: _stayLoggedIn ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 8),
              Text('로그인 상태 유지', style: TextStyle(color: subTextColor, fontSize: 14)),
            ],
          ),
        ),
        TextButton(
          onPressed: (){
            print('비밀번호 찾기 클릭 됨');
          },
          child: Text('비밀번호 찾기', style: TextStyle(color: pinkAccent, fontSize: 14)),
        )
      ],
    );
  }

  Widget _buildLoginButton(){
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [pinkAccent, purpleAccent]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: pinkAccent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _loginToBackend,
          child: const Center(
            child: Text('로그인', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        )
      ),
    );
  }

  Widget _buildDivider(){
    return Row(
      children: [
        Expanded(child: Divider(color: cardColor, thickness: 1.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('또는', style: TextStyle(color: subTextColor, fontSize: 14)),
        ),
        Expanded(child: Divider(color: cardColor, thickness: 1.5,))
      ],
    );
  }

  Widget _buildKakaoButton(){
    return _buildSocialButton(
      text: '카카오로 로그인',
      color: const Color(0xFFFEE500),
      textColor: Colors.black87,
      icon: Icons.chat_bubble
    );
  }

  Widget _buildAppleButton(){
    return _buildSocialButton(
      text: '애플로 로그인',
      color: cardColor,
      textColor: Colors.white,
      icon: Icons.apple
    );
  }

  Widget _buildSocialButton({required String text, required Color color, required Color textColor, required IconData icon}){
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (){
            print("$text 클릭 됨");
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(text, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupLink(){
    return Center(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupProfileScreen()));
              },
              child: RichText(
                text: TextSpan(
                  text: '계정이 없으신가요? ',
                  style: TextStyle(color: subTextColor, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '회원가입',
                      style: TextStyle(color: pinkAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text
  }){
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: subTextColor),
        prefixIcon: Icon(icon, color: subTextColor, size: 20),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: pinkAccent)),
      ),
    );
  }

  Widget _buildBackgroundGlow(){
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: 
            [
              purpleAccent.withOpacity(0.3),
              bgColor.withOpacity(0.0),
            ],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }
}