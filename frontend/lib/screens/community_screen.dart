import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  // 🎨 테마 색상
  final Color bgColor = AppColors.background;
  final Color cardColor = AppColors.surface;
  final Color pinkAccent = AppColors.primary;
  final Color purpleAccent = AppColors.primaryEnd;
  final Color subTextColor = AppColors.textSecondary;

  // 🚀 순차적 슬라이드 다운 애니메이션을 위한 컨트롤러
  late final AnimationController _animController;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  // 탭 카테고리 상태 관리
  int _selectedCategoryIndex = 0;
  final List categories = ['전체', '연애 고민', '데이트 코스', '자유'];

  // 📝 커뮤니티 게시글 더미 데이터 (꺾쇠 에러 원천 차단형)
  final List posts = [
    {
      'name': '별빛소나타',
      'time': '2분 전',
      'avatar': '🌸',
      'avatarColor': AppColors.primarySoft,
      'category': '연애 고민',
      'categoryColor': AppColors.primarySoft,
      'categoryTextColor': AppColors.primary,
      'content': '첫 데이트 장소 추천해주세요! 홍대 근처에서 조용하고 분위기 좋은 카페 아시는 분 💕',
      'hasImage': true,
      'likes': 24,
      'comments': 8,
    },
    {
      'name': '파란하늘',
      'time': '15분 전',
      'avatar': '🌊',
      'avatarColor': AppColors.blueSoft,
      'category': '데이트 코스',
      'categoryColor': AppColors.blueSoft,
      'categoryTextColor': AppColors.blue,
      'content': '성수동 데이트 코스 공유해요 🗺️ 카페 → 전시회 → 한강 피크닉 완벽한 하루였어요!',
      'hasImage': false,
      'likes': 47,
      'comments': 12,
    },
    {
      'name': '초록바람',
      'time': '1시간 전',
      'avatar': '🌿',
      'avatarColor': AppColors.sageSoft,
      'category': '자유',
      'categoryColor': AppColors.sageSoft,
      'categoryTextColor': AppColors.sage,
      'content': '다들 주말에 보통 뭐하시나요? 날씨가 좋아서 어디든 나가고 싶네요 ☀️',
      'hasImage': false,
      'likes': 15,
      'comments': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnim = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          '커뮤니티',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pinkAccent, purpleAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  print("글쓰기 클릭됨");
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Center(
                    child: Text(
                      '✏️ 글쓰기',
                      style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnim.value),
            child: Opacity(
              opacity: _fadeAnim.value,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            _buildCategoryFilters(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: posts.length,
                separatorBuilder: (context, index) => Divider(
                  color: AppColors.border,
                  thickness: 1,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  return _buildPostItem(posts[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: List.generate(categories.length, (index) {
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryIndex = index);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [pinkAccent, purpleAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isSelected ? null : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : subTextColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? AppColors.onPrimary : subTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPostItem(Map post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: post['avatarColor'],
                child: Text(post['avatar'].toString(), style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['name'].toString(),
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post['time'].toString(),
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: post['categoryColor'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post['category'].toString(),
                  style: TextStyle(
                    color: post['categoryTextColor'],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post['content'].toString(),
            style: const TextStyle(color: AppColors.text, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (post['hasImage'] == true) ...[
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.primarySoft, AppColors.peachSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text('☕', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.favorite, color: pinkAccent, size: 18),
              const SizedBox(width: 4),
              Text(post['likes'].toString(),
                  style: TextStyle(color: pinkAccent, fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, color: subTextColor, size: 18),
              const SizedBox(width: 4),
              Text(post['comments'].toString(),
                  style: TextStyle(color: subTextColor, fontSize: 13)),
              const SizedBox(width: 16),
              Icon(Icons.link, color: subTextColor, size: 18),
              const SizedBox(width: 4),
              Text('공유', style: TextStyle(color: subTextColor, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
