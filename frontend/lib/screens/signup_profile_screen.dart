import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
// 웹 및 플랫폼 자동 감지 도구
import 'package:flutter/foundation.dart';

// 화면에 글씨를 치거나 버튼을 눌렀을 때 '모양이 변하는' 
// 화면을 만들기 위해 StatefulWidget을 사용합니다. (👈 주석 기호 // 추가)
class SignupProfileScreen extends StatefulWidget{
  const SignupProfileScreen({super.key}); // (👈 Key 대문자를 key 소문자로 수정)
  @override
  State<SignupProfileScreen> createState() =>_SignupProfileScreenState();
}

// 실제로 화면의 모양을 그리고 상태(데이터)를 저장하는 핵심 공간입니다.
class _SignupProfileScreenState extends State<SignupProfileScreen>{

    /* 디자인 테마 색상 정의하기
    0xFF는 투명도 100%를 의미하고, 뒤의 6자리는 헥스(HEX) 16진수 표기법 색상 코드
    */
    final Color bgColor = const Color(0xFF12121A);
    final Color cardColor = const Color(0xFF22222E);
    final Color borderColor = const Color(0xFF38384A);
    final Color pinkAccent = const Color(0xFFFF4B93);
    final Color purpleAccent = const Color(0xFFB635F7);
    final Color textColor = Colors.white;
    final Color subTextColor = const Color(0xFFA0A0B0);

    // add - 사용자가 입력한 글씨를 빼오기 위한 컨트롤러
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _nicknameController = TextEditingController();
    final TextEditingController _ageController = TextEditingController();
    final TextEditingController _bioController = TextEditingController();

    // 선택한 데이터를 기억하는 변수들 (상태관리)
    String _selectedGender = '여성';
    final List<String> _selectedInterests = ['카페','영화','독서'];

    // 선택할 사진을 담을 변수
    final List<XFile?> _selectedImages = [null, null, null];
    final ImagePicker _picker = ImagePicker(

    );

    // 📋 [3] 화면에 뿌려줄 관심사 버튼 데이터 목록
    final List<Map<String, String>> _interestsData = [
        {'icon': '☕', 'label': '카페'},
        {'icon': '🎬', 'label': '영화'},
        {'icon': '🎵', 'label': '음악'},
        {'icon': '📚', 'label': '독서'},
        {'icon': '🏃', 'label': '운동'},
        {'icon': '✈️', 'label': '여행'},
        {'icon': '🍳', 'label': '요리'},
        {'icon': '🎮', 'label': '게임'},
    ];

    // 접속한 기기를 파악해 서버 주소를 맞춤
    String get _apiUrl {
        if(kIsWeb) {
            return 'http://localhost:3000/api/signup'; // 크롬용 주소
        }else if(defaultTargetPlatform == TargetPlatform.android){
            return 'http://10.0.2.2:3000/api/signup'; // 안드로이드 에뮬레이터
        }else {
            return 'http://localhost:3000/api/signup'; // 아이폰 시뮬레이터용 주소
        }
    }

    Future<void> _pickImage(int index) async {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if(pickedFile != null) {
        setState((){
          _selectedImages[index] = pickedFile;
          // 고른 사진 화면에 표시
        });
      }
    }

    // add
    Future<void> _signUpToBackend() async {
      // 컨트롤러에서 글씨를 꺼낸다
      final email = _emailController.text;
      final password = _passwordController.text;
      final nickname = _nicknameController.text;
      final ageText = _ageController.text;
      final bio = _bioController.text;

      // 필수값 검사 (빈칸)
      if(email.isEmpty || password.isEmpty || nickname.isEmpty || ageText.isEmpty){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('닉네임과 나이를 입력해주세요'),
          ),
        );
        return;
      }

      // 사진에 대한 검사
      if(_selectedImages[0] == null){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('대표사진은 필수로 등록해야 합니다'),
          ),
        );
        return;
      }

      // 백엔드 서버 주소
      final url = Uri.parse(_apiUrl);

      // 파일 전송할때는 multipartrequest 사용
      var request = http.MultipartRequest('POST', url);

      // 백엔드 형식에 맞게 조절
      // 더미 데이터
      request.fields['email'] = email;
      request.fields['nickname'] = nickname;
      request.fields['password'] = password;
      request.fields['age'] = ageText;
      request.fields['gender'] = _selectedGender == '남성' ? 'M' : 'F';
      request.fields['bio'] = bio;

      // 이미지 파일 포장
      for(int i = 0; i < _selectedImages.length ; i++){
        if(_selectedImages[i] != null){
					final bytes = await _selectedImages[i]!.readAsBytes();
          request.files.add(
            await http.MultipartFile.fromBytes(
							'photos', 
							bytes, 
							filename: _selectedImages[i]!.name.isNotEmpty ? _selectedImages[i]!.name : 'photo_$i.jpg'
						)
          );
        }
      }
    
      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);

        if(response.statusCode == 200 && data['success'] == true){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? '가입실패'))
          );
        }else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('서버 통신 에러'))
          );
        }
      }
      catch(e){

      }
    
    }

    //// 📱 [4] 실제로 화면을 그리는 build 함수
    @override
    Widget build(BuildContext context){
        return Scaffold(
            backgroundColor:bgColor,
            body: SafeArea(// 핸드폰의 노치(카메라 파인 부분)나 하단 바에 UI가 가려지지 않게 보호해줍니다.
                child:Center(// 위에서 아래로 위젯(화면 조각)들을 차곡차곡 쌓습니다
										child: ConstrainedBox(
											constraints: const BoxConstraints(maxWidth: 480),
											child: Column(
												children: [
													_buildTopBar(),// 맨 위에 뒤로가기 버튼과 분홍색 진행률 바를 그립니다.
                        	Expanded(// 남은 화면 공간을 꽉 채우라는 뜻입니다.
														child:SingleChildScrollView(
															// 내용이 길어지면 화면을 위아래로 스크롤(드래그)할 수 있게 해줍니다.
															padding:const EdgeInsets.symmetric(horizontal:24.0, vertical:16.0),
															// 양옆과 위아래에 여백을 줍니다.
															child:Column(
																crossAxisAlignment:CrossAxisAlignment.start,
																// 글씨나 박스들을 화면 왼쪽으로 정렬합니다.
																children:[
																	_buildHeader(),
																	const SizedBox(height: 32),
																	_buildPhotoSection(),
																	const SizedBox(height: 24),
																	//추가
																	_buildSectionTitle('이메일'),
																	const SizedBox(height: 8),
																	_buildTextField(controller: _emailController, hint: 'example@test.com'),
																	const SizedBox(height: 16),
																	_buildSectionTitle('비밀번호'),
																	const SizedBox(height: 8),
																	_buildTextField(controller: _passwordController, hint: '비밀번호 입력', obscureText: true),
																	const SizedBox(height: 24),
																	//추가 끝
																	_buildNicknameSection(),
																	const SizedBox(height: 24),
																	_buildAgeAndGenderSection(),
																	const SizedBox(height: 24),
																	_buildBioSection(),
																	const SizedBox(height: 24),
																	_buildInterestsSection(),
																	const SizedBox(height: 40),
																	_buildNextButton(),
																	const SizedBox(height: 20),
																],    
															),
                            ),
                        	),
												],
											),
										),
                ),
            ),
        ); // (👈 }; 로 잘못 닫혀있던 Scaffold 괄호를 ); 로 수정)
    }

    //// 🧱 부품 1: 상단 앱바 (뒤로가기, 프로그레스 바)
    Widget _buildTopBar() {
        return Padding(
            padding:const EdgeInsets.symmetric(horizontal:20.0, vertical:16.0),
            child:Row(
                children:[
                    // 뒤로가기 동그란 버튼 만들기
                    Container(
                        width:40, height:40, 
                        decoration:BoxDecoration(color:cardColor, shape:BoxShape.circle),
                        child:IconButton(
                            icon:Icon(Icons.arrow_back, color:textColor, size:20),
                            onPressed:() => Navigator.pop(context),    
                        ),           
                    ),
                    const SizedBox(width:16),
                    // 진행 상태 표시바
                    Expanded(
                        child:Stack(
                            children:[
                                Container(
                                    height:4, 
                                    decoration:BoxDecoration(
                                        color:cardColor, 
                                        borderRadius:BorderRadius.circular(2)
                                    ),
                                ),
                                // 그 위에 덮이는 핑크/퍼플 그라데이션 선
                                FractionallySizedBox(
                                    widthFactor:0.6,
                                    child:Container(
                                        height:4,
                                        decoration:BoxDecoration(
                                            gradient:LinearGradient(colors:[pinkAccent, purpleAccent]),
                                            borderRadius:BorderRadius.circular(2),        
                                        ),
                                    ),   
                                ),         
                            ],
                        ),
                    ),
                    const SizedBox(width:16),
                    // (👈 fontWeight: 파라미터명 누락 수정)
                    Text('3 / 5', style:TextStyle(color:subTextColor, fontSize:14, fontWeight:FontWeight.bold)),
                ],
            ),
        );
    }

    // 🧱 부품 2: 헤더 타이틀 ('나를 소개해요 ✨')
    Widget _buildHeader(){
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
             Text('나를 소개해요',style:TextStyle(color:textColor, fontSize:26, fontWeight:FontWeight.w800)),
             const SizedBox(height:8),
             Text('프로필 사진과 기본 정보를 입력해주세요', style:TextStyle(color:subTextColor, fontSize:14)),
            ],
        );
    }

    // 🧱 부품 3: 프로필 사진 3장 등록하는 곳
    Widget _buildPhotoSection(){
        return SizedBox(
            height:150, child:Row(
                children:[
                    Expanded(flex:2, child: _buildPhotoBox(index: 0, isMain: true)),  
                    // 가장 큰 메인 사진 칸 (비율 2)  
                    const SizedBox(width:12),
                    Expanded(flex:1, child: _buildPhotoBox(index: 1, isMain: false)),
                    // 서브 사진 칸 1 (비율 1)
                    const SizedBox(width:12),
                    Expanded(flex:1, child: _buildPhotoBox(index: 2, isMain: false)),  
                    // 서브 사진 칸 2 (비율 1)  
                ],
            ),       
        );
    }

    // 메인 사진 등록 박스 디자인
    Widget _buildPhotoBox({required int index, required bool isMain}){
			return GestureDetector(
				onTap: () => _pickImage(index),
				child: Container(
					decoration: BoxDecoration(
						color: cardColor,
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: borderColor, width: 1.5),
						image: _selectedImages[index] != null ? DecorationImage(image: kIsWeb ? NetworkImage(_selectedImages[index]!.path) as ImageProvider : FileImage(File(_selectedImages[index]!.path)), fit: BoxFit.cover) : null
					),
					child: 
						_selectedImages[index] == null ? 
						Center(
							child: isMain ?
								Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
												Icon(Icons.camera_alt, color: subTextColor, size: 32),
												const SizedBox(
														height: 8,
												),
												Text('대표 사진', style: TextStyle(color: subTextColor, fontSize: 12)),
										],
								)
							: Icon(Icons.add, color: subTextColor, size: 28),
						) : null
				),
			); // (👈 에러 방지용 임시 빈 칸)
    }

    //서브 사진 등록 박스 디자인 (간단한 + 모양)
    // Widget _buildSubPhotoBox(){
    //     return Container(
    //         decoration: BoxDecoration(
    //             color: cardColor,
    //             borderRadius: BorderRadius.circular(16),
    //             border: Border.all(color: borderColor, width: 1.5),
    //         ),
    //         child: Center(
    //             child: Icon(Icons.add, color: subTextColor, size: 28),
    //         ),
    //     ); // (👈 에러 방지용 임시 빈 칸)
    // }

    // 🧱 부품 4: 닉네임 입력 칸
    Widget _buildNicknameSection(){
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _buildSectionTitle('닉네임'),
                const SizedBox(height: 8),
                _buildTextField(controller: _nicknameController, hint: '별빛소나타'),
            ],
        ); // (👈 에러 방지용 임시 빈 칸)
    }

    // 🧱 부품 5: 나이와 성별 입력 칸 (한 줄에 나란히 배치)
    Widget _buildAgeAndGenderSection(){
        return Row(
            children: [
                Expanded(
                    flex: 4,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            _buildSectionTitle('나이'),
                            const SizedBox(height: 8),
                            _buildTextField(controller: _ageController, hint: '27', isNumber: true),
                        ],
                    ),
                ),
                const SizedBox(width: 16),
                Expanded(
                    flex: 6,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            _buildSectionTitle('성별'),
                            const SizedBox(height: 8),
                            Row(
                                children: [
                                    Expanded(child: _buildGenderButton('여성')),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildGenderButton('남성')),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ); // (👈 에러 방지용 임시 빈 칸)
    }

    // 성별 버튼 디자인 및 클릭 시 색상 변경 로직
    Widget _buildGenderButton(String gender){
        // 현재 내가 선택한 성별인지 확인
        bool isSelected = _selectedGender == gender;
        return GestureDetector(
            onTap: (){
                setState(() => _selectedGender = gender);
            },
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: isSelected ? pinkAccent.withOpacity(0.1) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? pinkAccent : Colors.transparent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                    gender, 
                    style: TextStyle(
                        color: isSelected ? pinkAccent : subTextColor, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16
                    ),
                ),
            ),
        ); // (👈 에러 방지용 임시 빈 칸)
    }

    // 🧱 부품 6: 자기소개 입력 칸
    Widget _buildBioSection(){
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('자기소개'),
            const SizedBox(height: 8),
            _buildTextField(controller: _bioController, hint: '커피 한 잔과 함께 영화 이야기 나눌 사람을 찾아요 ☕', maxLines: 3),
          ],
        ); // (👈 에러 방지용 임시 빈 칸)
    }

    // 🧱 부품 7: 관심사 선택 칸 (Wrap 사용)
    Widget _buildInterestsSection(){
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('관심사'),
            const SizedBox(height: 12),
            Wrap( // 가로로 채우다가 알아서 다음줄로 넘김
              spacing: 10, // 가로로 나열된 버튼 사이의 틈
              runSpacing: 10, // 줄이 바뀌었을 때 세로 틈
              children: _interestsData.map((interest){
                bool isSeleted = _selectedInterests.contains(interest['label']);
                return GestureDetector( // 터치를 감지
                  onTap:(){
                    setState((){
                      if(isSeleted) {
                        _selectedInterests.remove(interest['label']);
                      }else {
                        _selectedInterests.add(interest['label']!);
                      };
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSeleted ? pinkAccent.withOpacity(0.15) : cardColor,
                      border: Border.all(color: isSeleted ? pinkAccent : Colors.transparent, width: 1.5)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(interest['icon']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(interest['label']!, style: TextStyle(color: isSeleted ? pinkAccent : subTextColor, fontWeight: isSeleted ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ); // (👈 에러 방지용 임시 빈 칸)
    }

    // 🧱 부품 8: 하단 '다음 단계' 버튼
    Widget _buildNextButton(){
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [pinkAccent, purpleAccent]),
          borderRadius: BorderRadius.circular(16)
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _signUpToBackend,
            child: const Center(
              child: Text('가입완료 (다음단계)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ); // (👈 에러 방지용 임시 빈 칸)
    }

    //공용도구
    Widget _buildSectionTitle(String title){
      return Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)); // (👈 에러 방지용 임시 빈 칸)
    }

    //공용도구2
    Widget _buildTextField({required TextEditingController controller, required String hint, int maxLines = 1, bool isNumber = false, bool obscureText = false}){
      return TextField(
				controller: controller,
        maxLines: maxLines,
        obscureText: obscureText,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: subTextColor),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: pinkAccent, width: 1.5)),
        ),
      ); // (👈 에러 방지용 임시 빈 칸)
    }

// (👈 중간에 닫혀있던 클래스 종료 괄호 `}` 를 맨 마지막으로 옮겼습니다.)
}