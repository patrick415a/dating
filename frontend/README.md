# dating_web

A new Flutter project.

flutter build web --base-href /group/two/1/ --dart-define=API_BASE_URL=https://date-backend-5hp4.onrender.com

## 로컬 웹 소셜 로그인

1. Dating용 Google 클라이언트의 **승인된 리디렉션 URI**와 카카오 REST API 키의 **카카오 로그인 리다이렉트 URI**에 `http://localhost:3001/`를 추가합니다.
2. 실행할 백엔드(MySQL 또는 SQLite)의 로컬 `.env`에 `DATING_OAUTH_REDIRECT_URI=http://localhost:3001/`와 `.env.example`에 있는 Google·카카오 자격 증명을 설정합니다. 아래 예시는 ERP 프론트와 포트가 겹치지 않도록 Dating 백엔드에 `PORT=3002`를 설정합니다.
3. 백엔드를 시작한 뒤 이 폴더에서 프론트를 실행합니다.

```powershell
flutter run -d chrome --web-hostname=localhost --web-port=3001 --dart-define=API_BASE_URL=http://localhost:3002
```

Dating 백엔드의 기본 포트 `3000`을 쓰는 경우 `API_BASE_URL`도 `http://localhost:3000`으로 지정합니다.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
