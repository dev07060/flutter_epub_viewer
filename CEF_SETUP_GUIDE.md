# Flutter macOS CEF EPUB Viewer 설정 가이드

## 현재 완료된 작업

### ✅ 1. CEF 바이너리 설치
- CEF minimal binary distribution 다운로드 및 설치 완료
- `macos/cef_bin/` 디렉토리에 CEF 프레임워크 설치됨
- 포함 파일들:
  - `Release/Chromium Embedded Framework.framework`
  - `include/` (헤더 파일들)
  - `libcef_dll/` (DLL 래퍼 소스 코드)

### ✅ 2. Swift 코드 구현
- `CefView.swift`: CEF 브라우저 뷰 클래스 구현
- `CefViewFactory.swift`: Flutter Platform View 팩토리
- `CefManager.swift`: CEF 초기화 및 관리 클래스
- `AppDelegate.swift`: CEF 초기화 연동
- `Runner-Bridging-Header.h`: C API 브리징 헤더

### ✅ 3. Flutter 연동
- Platform View 등록 완료
- Method Channel 통신 구현
- Dart 측 `CefViewController` 클래스 구현

### ✅ 4. 권한 설정
- `Info.plist`에 필요한 권한 추가
- 네트워크 접근, 파일 시스템 접근 권한 설정

## 🔧 필요한 추가 작업

### 1. Xcode 프로젝트 설정

#### Framework 링크 설정
Xcode에서 다음 설정이 필요합니다:

1. **Framework Search Paths** 추가:
   ```
   $(PROJECT_DIR)/cef_bin/Release
   ```

2. **Linked Frameworks** 추가:
   - `Chromium Embedded Framework.framework`

3. **Header Search Paths** 추가:
   ```
   $(PROJECT_DIR)/cef_bin/include
   ```

4. **Bridging Header** 설정:
   ```
   Runner/Runner-Bridging-Header.h
   ```

5. **Other Linker Flags** 추가:
   ```
   -framework "Chromium Embedded Framework"
   -rpath @executable_path/../Frameworks
   ```

### 2. CMakeLists.txt 설정 (선택사항)

CEF의 CMake 설정을 사용하고 싶다면:

```cmake
# CEF 설정
set(CEF_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cef_bin")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")

find_package(CEF REQUIRED)

# CEF 타겟 추가
add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)
```

### 3. 빌드 스크립트 업데이트

`flutter_tools`가 CEF Framework를 앱 번들에 복사하도록 설정:

**macos/Runner.xcodeproj** Build Phases에 추가:
```bash
# CEF Framework 복사 스크립트
cp -R "${PROJECT_DIR}/cef_bin/Release/Chromium Embedded Framework.framework" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Frameworks/"
```

### 4. Runtime 설정

CEF 서브프로세스를 위한 설정:

1. **Helper 앱 생성** (선택사항):
   - CEF는 별도의 헬퍼 프로세스를 사용할 수 있음
   - 단일 프로세스 모드로도 동작 가능

2. **Resources 복사**:
   ```bash
   cp -R "${PROJECT_DIR}/cef_bin/Release/locale" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Resources/"
   ```

## 🧪 테스트 방법

### 1. 기본 빌드 테스트
```bash
cd flutter_epub_viewer
flutter build macos
```

### 2. CEF 초기화 확인
앱 실행 시 콘솔에서 다음 메시지 확인:
```
CEF initialized successfully
```

### 3. 웹뷰 테스트
Dart 코드에서 CEF 뷰 사용:
```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: UiKitView(
      viewType: 'com.example.flutter_epub_viewer/cef_view',
      creationParams: {'initialUrl': 'https://www.example.com'},
      creationParamsCodec: StandardMessageCodec(),
    ),
  );
}
```

## 🐛 일반적인 문제 해결

### 1. Framework 로딩 실패
- Framework Search Path 확인
- `@rpath` 설정 확인
- Framework가 올바른 위치에 있는지 확인

### 2. CEF 초기화 실패
- Resources 경로 확인
- 권한 설정 확인 (Info.plist)
- 메인 스레드에서 초기화하는지 확인

### 3. 브리징 헤더 오류
- 헤더 파일 경로 확인
- Include path 설정 확인
- C/C++ 컴파일러 설정 확인

## 📚 참고 자료

- [CEF Documentation](https://bitbucket.org/chromiumembedded/cef/wiki/Home)
- [CEF macOS Tutorial](https://bitbucket.org/chromiumembedded/cef/wiki/Tutorial)
- [Flutter Platform Views](https://docs.flutter.dev/platform-integration/platform-views)

## 🚀 다음 단계

1. Xcode 프로젝트 설정 완료
2. 실제 빌드 및 테스트
3. EPUB 파일 로딩 및 렌더링 구현
4. UI/UX 개선
5. 디버깅 및 최적화

## 🔍 EPUB 뷰어 특화 기능

### HTML 콘텐츠 렌더링
현재 `assets/index.html`에 있는 템플릿을 CEF에서 로드하여 EPUB 콘텐츠를 렌더링할 수 있습니다.

### JavaScript 인터페이스
CEF를 통해 JavaScript와 Dart 간의 양방향 통신이 가능합니다:
- 페이지 네비게이션
- 북마크 관리
- 텍스트 검색
- 하이라이트 기능

### 성능 최적화
- CEF의 오프스크린 렌더링 활용
- 메모리 관리 최적화
- 멀티 프로세스 아키텍처 활용