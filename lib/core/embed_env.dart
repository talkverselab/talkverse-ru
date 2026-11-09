/// 통합 앱(Talkverse, com.talkverse.app) 안에 패키지로 들어갔는지 — `embedInit()` 이 정한다(2026-11-09 uk `EMBED_GUIDE.md`).
/// 단독 앱(러시아어 유니버스)에서는 false 이고 모든 동작이 예전과 같다.
bool embedded = false;

/// 이 언어의 저장 이름 접두(설정 키). 다른 언어 패키지와 겹치지 않게. DB 파일 이름(russian_universe)은 이미 이 앱만의 이름이다.
const storePrefix = 'ru_';

const _pkg = 'packages/russian_universe/';

/// 에셋 경로 — 패키지로 들어가면 Flutter 가 `packages/<패키지>/` 아래에 둔다.
String assetPath(String p) => embedded ? '$_pkg$p' : p;

/// AssetManifest 의 키 → 앱 안 상대 경로(`assets/...`). 패키지 접두가 있으면 뗀다.
String stripAssetPrefix(String p) => p.startsWith(_pkg) ? p.substring(_pkg.length) : p;
