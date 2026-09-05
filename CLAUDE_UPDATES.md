# Claude 업데이트 메모 — russian_universe (ru)

> 기준 앱: chinese_universe(zh). 이식 세부 규격은 `zh/docs/PORTING_GUIDE_2026-09.md` 참고.
> 작성: 2026-09-05 (Claude Code 세션). 이후 변경은 git log 참고.

## 변경 이력
- (2026-09-02) GitHub 저장소 `talkverselab/talkverse-ru` 신규 생성 + 첫 푸시 (이전엔 원격 없음)
- `7bf35ef` (2026-09-03) 한글독음 전역 토글

## 변경 내용
- `core/display_settings.dart`: 기존 `showAccents`(강세) 옆에 `showReading`(ValueNotifier, SharedPreferences `show_ko_reading`) + `load()`/`toggleReading()` + 앱바용 `ReadingToggleAction`(악센트 토글과 같은 원형 버튼, `한`) 추가. `main.dart`에서 `DisplaySettings.load()`.
- `widgets/sentence_view.dart`의 `SentenceReading`(색칠 독음 줄, 전 화면 공용)을 토글에 연결 — 여기 한 곳으로 챗·플래시카드 등 SentenceReading 사용처 전부 적용.
- plain 독음 텍스트도 연결: `spoonfed_course_screen.dart`(문장 목록 reading) · `flashcard_session_screen.dart`(reading 면).
- 토글 버튼 배치: 다이얼로그 챗 · 플래시카드 세션 · 떠먹여주는 코스 앱바.

## 건드리지 않은 것
- 외우기 모드/외움 체크는 미이식(이 앱의 플래시카드 구조가 이미 앞/뒤 가림). 콘텐츠 무변경.
- `applicationId`가 `com.example.russian_universe`로 남아 있음 — 스토어 배포 전 `com.talkverse.*`로 바꿔야 함.
