import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:async';
// Future.delayed (타이머) 기능을 쓰기 위해 불러옵니다.

//로딩이 끝나면 넘어갈 로그인 화면을 ..
import 'login_screen.dart';

// 💡 분리한 로고 컴포넌트 임포트
import '../widgets/brand_logo.dart';
import '../widgets/footer_wave.dart';

// 💡 BgmPlayer 임포트
import '../services/bgm_player.dart';

// 화면에 로딩 바가 차오르는 '애니메이션(상태 변화)'이 있으므로 
//StatefulWidget을 사용합니다.
class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();

}

class _SplashScreenState extends State<SplashScreen>{
  // 🎨 [1] 디자인 테마 색상 정의하기
final Color bgColor = AppColors.background;
final Color pinkAccent = AppColors.primary;
final Color purpleAccent = AppColors.primaryEnd;
final Color subTextColor = AppColors.textSecondary;



  // ⏳ [2] 로딩 바 애니메이션을 위한 상태 변수
  double _loadingProgress = 0.0;
  // 처음에는 로딩 바가 0% (비어있음)

  //추가. 💡 한 글자씩 나타나는 타이핑 애니메이션용 변수
  final String _fullLogoText = AppBrand.name;
  String _typedLogoText = "";
  int _charIndex = 0;
  Timer? _typingTimer;

  @override
  void initState(){
  super.initState();

  BgmPlayer().playBgm();

    //추가
  _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_charIndex < _fullLogoText.length) {
        setState(() {
          _typedLogoText += _fullLogoText[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    Future.delayed(const Duration(milliseconds:100),(){
      if(mounted){
        setState((){
          _loadingProgress = 1.0;
        });
      }
    });

    // 2. 2.5초 동안 멋진 스플래시 화면을 보여준 뒤, 
    ///로그인 화면으로 자동으로 넘어갑니다.
    Future.delayed(const Duration(milliseconds:2500),(){
      if(mounted){
        /* Navigator.pushReplacement를 쓰면 뒤로가기를 눌러도
        다시 스플래시화면으로 돌아오지 않습니다
        */
        Navigator.pushReplacement(context,
          // 부드럽게 화면이 밝아지며 넘어가는 
          //페이드(Fade) 애니메이션 효과를 줍니다.
          PageRouteBuilder(
            pageBuilder:(context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder:(context, animation, secondaryAnimation, child){
              return FadeTransition(
                opacity: animation,
                child: child
              );
            },
            transitionDuration: const Duration(milliseconds:800),
            //0.8초 동안 부드럽게 전환
          ),
        );
      }
    });
  }

  //추가
  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  //화면을 그리는 메인함수
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:bgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth:480),
            child:Stack(
            fit: StackFit.expand,//오타
            children:[
              _buildBackgroundGlow(),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: FooterWave(),
              ),
              SafeArea(
                child:Column(
           mainAxisAlignment: MainAxisAlignment.center,  
           children:[
            _buildIconBox(), const SizedBox(height: 24),
            _buildLogoText(), const SizedBox(height: 16),
            _buildSubtext(), const SizedBox(height: 48),//오타
            _buildProgressBar(),//오타
           ],           
            ),
          ),
          ],
          ),
        ),
      ),
      ),
);
}

// 🧱 부품: 배경 정중앙에 퍼지는 은은한 빛 효과
Widget _buildBackgroundGlow(){
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.blush.withValues(alpha: 0.35),
            bgColor.withValues(alpha: 0.0),
          ],
          stops: const [0.2, 1.0],
        ),
      ),
    ),
  );
}

// 🧱 부품: 네모난 박스 배경과 테두리를 완전히 제거하고 번개 아이콘만 깔끔하게 출력
  Widget _buildIconBox(){
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: const BrandMark(size: 52),
      ),
    );
  }


// 🧱 부품: 앱 이름 타이핑 효과
Widget _buildLogoText(){
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: SizedBox(
      height: 48,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _typedLogoText,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
      ),
    ),
  );
}

// 🧱 부품: 로고 밑의 안내 문구
Widget _buildSubtext(){
  return Text(
    AppBrand.tagline,
    style:TextStyle(
      color:subTextColor,
      fontSize:15,
      fontWeight:FontWeight.w500,
      letterSpacing:0.5,
    ),
  );
}

// 🧱 부품: 스르륵 차오르는 로딩 바 애니메이션
Widget _buildProgressBar(){
  return Container(
    width:200, height:4,
    decoration:BoxDecoration(
      color:AppColors.primarySoft,
      borderRadius:BorderRadius.circular(2),
    ),
    child:Align(
      alignment:Alignment.centerLeft,
      child:AnimatedContainer(
        duration:const Duration(milliseconds:2000),
        width:200 * _loadingProgress,
        decoration:BoxDecoration(
          gradient:LinearGradient(
            colors:[pinkAccent, purpleAccent],
          ),
          borderRadius:BorderRadius.circular(2),
          boxShadow:[
            BoxShadow(
              color:AppColors.shadow,
              blurRadius:6,
              offset:const Offset(0,0),
            ),
          ],
        ),
      ),
    ),
  );
}


}//end
