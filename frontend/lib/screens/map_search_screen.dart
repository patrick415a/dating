import 'package:flutter/material.dart';
// 💡 [경로 수정 완료] main.dart에 있는 DatingHomeScreen으로 넘어가기 위해 불러옵니다.

// gps 위치권한 패키지
import 'package:geolocator/geolocator.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // 카카오지도 웹뷰

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final Color bgColor = const Color(0xFF12121A);
  final Color cardColor = const Color(0xFF22222E);
  final Color pinkAccent = const Color(0xFFFF4B93);
  final Color subTextColor = const Color(0xFFA0A0B0);

  // 필터 상태 관리
  int _selectedCategoryIndex = 0;
  final List<String> categories = ['동네 친구', '커피 한잔', '술 한잔', '영화/문화'];
  
  String _selectedRadius = '반경 3km';
  final List<String> radiusOptions = ['반경 1km', '반경 3km', '반경 5km', '반경 10km'];
  
  // String _selectedAge = '20대 초중반';
  final List<String> ageOptions = ['20대 초중반', '20대 후반', '30대 초반', '상관없음'];

  Position? _currentPosition;
  bool _isLoadingLocation = true;

  // 화면진입 시 위치기반 권한 확인 및 가져오기
  @override
  void initState(){
    super.initState();
    // 화면이 그려진 직 후에 예쁜 스낵바를 띄우기 위해 
    // _getCurrentLocation(); 
    WidgetsBinding.instance.addPostFrameCallback((_){
      _checkAndRequestPermitionWithSnackbar();
    });
  }

  // 새로 추가되면서 1단계
  Future<void> _checkAndRequestPermitionWithSnackbar() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if(!serviceEnabled) {
      _showErrorSnackbar('휴대폰의 GPS기능이 꺼져있습니다');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.denied){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: 
            Text(
              '원활한 주변 인연 매칭을 위해 위치 권한이 필요해요 💘', 
              style: TextStyle(fontWeight: FontWeight.bold)
            ),
            backgroundColor: pinkAccent,
            duration: const Duration(days: 365),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: '권한 허용하기', 
              textColor: Colors.white,
              onPressed: () async {
                permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.whileInUse || permission == LocationPermission.always){
                  _getActualLocaiton(); // 허용되면 위치 가져오기
                }else {
                  _showErrorSnackbar('위치 권한이 거부 되었습니다');
                }
              }
            ),
          ),
        );
      }
    }else if(permission == LocationPermission.deniedForever){
      _showErrorSnackbar('위치 권한이 영구 차단되었습니다. 브라우저 설정에서 허용해주세요');
    }else {
      _getActualLocaiton();
    }
  }

  // gps 위치 권한 요청 및 현재 위치 가져오기
  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();

  //   if(!serviceEnabled){
  //     return Future.error('위치 서비스가 비활성화되어 있습니다');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if(permission == LocationPermission.denied){
  //     permission = await Geolocator.requestPermission();
      
  //     if(permission == LocationPermission.denied){
  //       return Future.error('위치 권한이 거부되었습니다');
  //     }
  //   }

  //   if(permission == LocationPermission.deniedForever){
  //     return Future.error('위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요');
  //   }

  //   Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //   setState((){
  //     _currentPosition = position;
  //     _isLoadingLocation = false;
  //   });
  // }

  Future<void> _getActualLocaiton() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState((){
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    }catch(e){
      _showErrorSnackbar('위치를 가져오는데 실패하였습니다');
    }
  }

  void _showErrorSnackbar(String message) {
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        )
      );

      setState(() => _isLoadingLocation = false);
    }
  }

  // 하단 대기 유저 더미 데이터
  final List<Map<String, dynamic>> nearbyUsers = [
    {'distance': '800m', 'gender': '여', 'name': '지은', 'interest': '카페 탐방'},
    {'distance': '1.2km', 'gender': '남', 'name': '민준', 'interest': '한강 산책'},
    {'distance': '2.5km', 'gender': '여', 'name': '수연', 'interest': '영화 보기'},
  ];

  // 👥 [핵심 추가] 거리별 가짜 회원 리스트 (필터링을 위해 distanceValue 추가)
  final List<Map<String, dynamic>> _allDummyUsers = [
    {'id': 1, 'distanceValue': 0.3, 'distance': '300m', 'gender': '여', 'name': '지은', 'interest': '카페 탐방', 'status': 'NONE'},
    {'id': 2, 'distanceValue': 0.8, 'distance': '800m', 'gender': '남', 'name': '민준', 'interest': '한강 산책', 'status': 'NONE'},
    {'id': 3, 'distanceValue': 1.2, 'distance': '1.2km', 'gender': '여', 'name': '수연', 'interest': '영화 보기', 'status': 'SENT'},
    {'id': 4, 'distanceValue': 2.5, 'distance': '2.5km', 'gender': '남', 'name': '동현', 'interest': '술 한잔', 'status': 'NONE'},
    {'id': 5, 'distanceValue': 2.8, 'distance': '2.8km', 'gender': '여', 'name': '서연', 'interest': '맛집 탐방', 'status': 'NONE'},
    {'id': 6, 'distanceValue': 3.5, 'distance': '3.5km', 'gender': '남', 'name': '지훈', 'interest': '코딩 스터디', 'status': 'RECEIVED'},
    {'id': 7, 'distanceValue': 4.1, 'distance': '4.1km', 'gender': '여', 'name': '유진', 'interest': '드라이브', 'status': 'SENT'},
    {'id': 8, 'distanceValue': 4.9, 'distance': '4.9km', 'gender': '남', 'name': '현우', 'interest': '동네 산책', 'status': 'SENT'},
    // 반경 5km 밖의 유저 (필터링 테스트용 - 평소엔 안 보여야 함)
    {'id': 9, 'distanceValue': 6.5, 'distance': '6.5km', 'gender': '여', 'name': '보영', 'interest': '자전거 타기', 'status': 'SENT'}, 
  ];

  // 반경에 맞게  리스트를 걸러주는 함수
  List<Map<String, dynamic>> get _filteredUsers {
    double maxDistance = 1.0;

    if(_selectedRadius == '반경 3km') maxDistance = 3.0;
    if(_selectedRadius == '반경 5km') maxDistance = 5.0;

    return _allDummyUsers.where((user) => user['distanceValue'] <= maxDistance).toList();
  }

  // 유저 상태 변경 및 스낵바 알림 함수
  void _updateUserStatus(int userId, String newStatus, String userName) {
    setState((){
      final userIndex = _allDummyUsers.indexWhere((u) => u['id'] == userId);

      if(userIndex != -1){
        _allDummyUsers[userIndex]['status'] = newStatus;
      }
    });

    String message = '';

    // 전달 받은 상태 값에 따라
    if(newStatus == 'SENT') message = '$userName님에게 매칭을 요청하였습니다';
    if(newStatus == 'MATCHED') message = '$userName님과 매칭 성사';
    if(newStatus == 'NONE') message = '$userName님 요청을 거절하였습니다';

    // 메시지 상자가 비어있지 않고 화면이 정상적으로 켜져있다면
    if(message.isNotEmpty && mounted) {
      // 알림창이 아직 안사라졌다면 겹치지 않게 숨김
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      // 새로운 알림 창 띄움
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: newStatus == 'MATCHED' ? Colors.blueAccent : pinkAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedUsers = _filteredUsers;

    return Container(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: Scaffold(
            backgroundColor: bgColor,
            // 상단바를 투명하게 만들고 지도 위에 겹치게 합니다.
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFFFF4B93), size: 24),
                  SizedBox(width: 8),
                  Text(
                    _isLoadingLocation ? '위치 찾는 중...' : '내 위치 확인완료', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildKakaoMap(),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Column(
                      children: [
                        _buildCategoryTabs(),
                        const Divider(color: Color(0xFF22222E), thickness: 1),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              _buildDropdownRow('탐색 반경', _selectedRadius, radiusOptions, (val){
                                setState(() => _selectedRadius = val!);
                              }),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pinkAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () {
                                    // 👉 백엔드로 내 위치와 반경을 보내어 근처 유저를 검색합니다.
                                  },
                                  child: const Text('주변 인연 찾기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildNearbyUsersList(displayedUsers)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKakaoMap(){
    if (_isLoadingLocation || _currentPosition == null){
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4B93),
        ),
      );
    }
    
    return InAppWebView(
      initialData: InAppWebViewInitialData(data: 
        """
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8" />
              <title>Kakao Map</title>
              <script 
                type="text/javascript" 
                src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=a0bf46b6f85adb1c911c864cba503e22">
              </script>
              <style>
                body, html {
                  margin: 0;
                  padding: 0;
                  width: 100%;
                  height: 100%;
                }
                #map {
                  width: 100%;
                  height: 100%;
                }
              </style>
            </head>
            <body>
              <div id="map"></div>
              <script>
                var container = document.getElementById('map');
                var myPosition = new kakao.maps.LatLng(
                  ${_currentPosition!.latitude},
                  ${_currentPosition!.longitude}
                );
                var options = {
                  center: new kakao.maps.LatLng(${_currentPosition!.latitude}, ${_currentPosition!.longitude}),
                  level: 3
                };
                var map = new kakao.maps.Map(container, options);
                var marker = new kakao.maps.Marker({
                  position: myPosition
                });
                marker.setMap(map);
              </script>
            </body>
          </html>
        """
      ),
    );
  }

  // 👉 [복구됨] 카테고리 가로 스크롤 탭
  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: List.generate(categories.length, (index) {
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? pinkAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : subTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 👉 [복구됨] 드롭다운 행 조립기
  Widget _buildDropdownRow(String title, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: subTextColor.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: cardColor,
              icon: Icon(Icons.expand_more, color: subTextColor),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // 👉 [복구됨] 주변 대기 유저 리스트 UI
  Widget _buildNearbyUsersList(List<Map<String, dynamic>> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
          child: Text(
            '근처 접속 중인 유저 $_selectedRadius(총 ${users.length}명)',
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            itemCount: users.length,
            separatorBuilder: (context, index) => Divider(color: cardColor, thickness: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50, 
                      child: Text(user['distance'], style: TextStyle(color: pinkAccent, fontWeight: FontWeight.bold, fontSize: 14))
                    ),
                    SizedBox(
                      width: 30, 
                      child: Text(user['gender'], style: const TextStyle(color: Colors.white, fontSize: 14))
                    ),
                    // 💡 [수정 2] 빈 공간을 꽉 채우는 Expanded 안에 이름과 관심사를 위아래(Column)로 예쁘게 묶습니다.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(user['interest'], style: TextStyle(color: subTextColor, fontSize: 12)),
                        ],
                      ),
                    ),
                    // 💡 [수정 3] 여기서 드디어 아까 만들어둔 진짜 '상태 액션 버튼' 함수를 불러옵니다! 이 줄이 핵심입니다.
                    _buildStatusActionButtons(user),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🚀 [새로 추가/변경인 부분] 기존 박스를 진짜 '버튼' 위젯들로 UI를 업그레이드한 구역입니다.
  Widget _buildStatusActionButtons(Map<String, dynamic> user) {
    final status = user['status'];
    final userId = user['id'];
    final userName = user['name'];

    if (status == 'NONE') {
      // 1. [아무 상태 아님 -> 요청 가능]
      return SizedBox(
        height: 32,
        // 👉 [추가됨] 단순 박스 대신 터치 효과가 있는 진짜 버튼(ElevatedButton)을 적용했습니다.
        child: ElevatedButton(
          // 👉 [추가됨] 버튼의 배경색(핑크), 글자색(흰색), 모서리 둥글기 등을 깔끔하게 세팅합니다.
          style: ElevatedButton.styleFrom(
            backgroundColor: pinkAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0, // 👉 [추가됨] 그림자를 없애서 요즘 유행하는 깔끔한 플랫 디자인으로 만듭니다.
          ),
          onPressed: () => _updateUserStatus(userId, 'SENT', userName),
          child: const Text('요청', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (status == 'SENT') {
      // 2. [내가 이미 요청을 보낸 상태]
      return SizedBox(
        height: 32,
        // 👉 [추가됨] 이미 눌러서 비활성화된 느낌을 주기 위해 버튼 색을 어두운 회색(cardColor)으로 바꿨습니다.
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: cardColor,
            foregroundColor: subTextColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // 👉 [추가됨] 얇은 테두리(BorderSide)를 줘서 어두운 배경에 묻히지 않고 버튼처럼 보이게 구분해줍니다.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: subTextColor.withOpacity(0.3)),
            ),
            elevation: 0,
          ),
          // 👉 [추가됨] onPressed에 기능을 아예 안 넣으면(null), 버튼이 회색으로 '비활성화'되어 안 눌리게 됩니다!
          onPressed: null, 
          child: const Text('요청됨', style: TextStyle(fontSize: 13)),
        ),
      );
    } else if (status == 'RECEIVED') {
      // 3. [상대방이 나에게 요청을 보낸 상태]
      // 👉 [추가됨] 수락과 거절 버튼 2개를 나란히 띄우기 위해 Row(가로 정렬 위젯)로 묶었습니다.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            // 👉 [추가됨] '수락'은 눈에 띄어야 하므로 파란색 바탕의 일반 버튼(ElevatedButton)으로 만들었습니다.
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () => _updateUserStatus(userId, 'MATCHED', userName),
              child: const Text('수락', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 6), // 👉 [추가됨] 수락 버튼과 거절 버튼 사이의 띄어쓰기 간격입니다.
          SizedBox(
            height: 32,
            // 👉 [추가됨] '거절'은 덜 강조하기 위해 배경색이 투명하고 테두리만 있는 버튼(OutlinedButton)을 썼습니다!
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: subTextColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: subTextColor.withOpacity(0.5)),
              ),
              onPressed: () => _updateUserStatus(userId, 'NONE', userName),
              child: const Text('거절', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      );
    } else if (status == 'MATCHED') {
      // 4. [서로 매칭이 성사된 상태]
      return SizedBox(
        height: 32,
        // 👉 [추가됨] 글자 옆에 예쁜 하트나 전화기 모양의 '아이콘'을 넣을 수 있는 'ElevatedButton.icon'을 썼습니다.
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: () {
            // 👉 [추가됨] 추후 여기에 백엔드 통화 기능이나 채팅창으로 이동하는 코드를 연결하면 됩니다.
          },
          // 👉 [추가됨] 버튼 왼쪽 위에 작은 하트 아이콘(Icons.favorite)을 띄워줍니다.
          icon: const Icon(Icons.favorite, size: 14),
          label: const Text('매칭됨', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}