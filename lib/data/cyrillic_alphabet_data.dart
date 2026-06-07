import '../domain/models/cyrillic_letter.dart';

/// 키릴 33자 — 학습 4단계 순서로 재배열.
///
///   1단계 모음: 경모음/연모음 짝(А-Я · О-Ё · У-Ю · Э-Е · Ы-И) — 러시아어 핵심 혼동.
///   2단계 가짜친구: 영어처럼 보이나 소리 다름 (В Н Р С Х).
///   3단계 러시아 전용: 라틴에 없는 새 자음.
///   4단계 나머지: 영어와 같은 친구 자음(К М Т) + 반모음(Й) + 부호(Ъ Ь).
/// 발음 규칙은 숨기고 [소리]만 노출.
const List<CyrillicLetter> cyrillicAlphabet = [
  // ── 1단계 · 모음 (경/연 짝) ──────────────────────────────
  CyrillicLetter(upper: 'А', lower: 'а', name: '아', roman: 'a', sound: '아', stage: AlphaStage.vowel, tip: '경모음. 영어 A처럼 [아]. 짝꿍 연모음은 Я.'),
  CyrillicLetter(upper: 'Я', lower: 'я', name: '야', roman: 'ya', sound: '야', stage: AlphaStage.vowel, tip: 'А의 연모음 [야]. 거꾸로 된 R 모양.'),
  CyrillicLetter(upper: 'О', lower: 'о', name: '오', roman: 'o', sound: '오', stage: AlphaStage.vowel, tip: '경모음 [오]. 강세 없으면 [아]로. 짝꿍은 Ё.'),
  CyrillicLetter(upper: 'Ё', lower: 'ё', name: '요', roman: 'yo', sound: '요', stage: AlphaStage.vowel, tip: 'О의 연모음 [요]. 항상 강세.'),
  CyrillicLetter(upper: 'У', lower: 'у', name: '우', roman: 'u', sound: '우', stage: AlphaStage.vowel, tip: '⚠ 영어 y 아님! 경모음 [우]. 짝꿍은 Ю.'),
  CyrillicLetter(upper: 'Ю', lower: 'ю', name: '유', roman: 'yu', sound: '유', stage: AlphaStage.vowel, tip: 'У의 연모음 [유].'),
  CyrillicLetter(upper: 'Э', lower: 'э', name: '에', roman: 'e', sound: '에', stage: AlphaStage.vowel, tip: '경모음 [에]. Е와 달리 y 없음. 짝꿍은 Е.'),
  CyrillicLetter(upper: 'Е', lower: 'е', name: '예', roman: 'ye', sound: '예', stage: AlphaStage.vowel, tip: 'Э의 연모음 [예]. 영어 E 모양에 속지 말 것.'),
  CyrillicLetter(upper: 'Ы', lower: 'ы', name: '의', roman: 'y', sound: '으', stage: AlphaStage.vowel, tip: '경모음 [으]에 가까운 깊은 이. 짝꿍은 И.'),
  CyrillicLetter(upper: 'И', lower: 'и', name: '이', roman: 'i', sound: '이', stage: AlphaStage.vowel, tip: 'Ы의 연모음 [이]. 거꾸로 된 N 모양.'),

  // ── 2단계 · 영어 가짜친구 자음 ───────────────────────────
  CyrillicLetter(upper: 'В', lower: 'в', name: '베', roman: 'v', sound: 'ㅂ(v)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 B 아님! [v] 소리.'),
  CyrillicLetter(upper: 'Н', lower: 'н', name: '엔', roman: 'n', sound: 'ㄴ', stage: AlphaStage.falseFriend, tip: '⚠ 영어 H 아님! [ㄴ] 소리.'),
  CyrillicLetter(upper: 'Р', lower: 'р', name: '에르', roman: 'r', sound: 'ㄹ(굴림)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 P 아님! 굴리는 [r].'),
  CyrillicLetter(upper: 'С', lower: 'с', name: '에스', roman: 's', sound: 'ㅅ(s)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 C 아님! [s] 소리.'),
  CyrillicLetter(upper: 'Х', lower: 'х', name: '하', roman: 'kh', sound: 'ㅎ(ㅋ)', stage: AlphaStage.falseFriend, tip: '⚠ 영어 X 아님! 목 긁는 [ㅎ].'),

  // ── 3단계 · 러시아 전용 자음 ─────────────────────────────
  CyrillicLetter(upper: 'Б', lower: 'б', name: '베', roman: 'b', sound: 'ㅂ', stage: AlphaStage.russianOnly, tip: '[ㅂ]. 소문자 б는 숫자 6처럼.'),
  CyrillicLetter(upper: 'Г', lower: 'г', name: '게', roman: 'g', sound: 'ㄱ', stage: AlphaStage.russianOnly, tip: '[ㄱ]. 거꾸로 된 ㄴ 모양.'),
  CyrillicLetter(upper: 'Д', lower: 'д', name: '데', roman: 'd', sound: 'ㄷ', stage: AlphaStage.russianOnly, tip: '[ㄷ].'),
  CyrillicLetter(upper: 'Ж', lower: 'ж', name: '줴', roman: 'zh', sound: '주(zh)', stage: AlphaStage.russianOnly, tip: '딱정벌레 모양. 영어 vision의 s.'),
  CyrillicLetter(upper: 'З', lower: 'з', name: '제', roman: 'z', sound: 'ㅈ(z)', stage: AlphaStage.russianOnly, tip: '숫자 3처럼. [z].'),
  CyrillicLetter(upper: 'Л', lower: 'л', name: '엘', roman: 'l', sound: 'ㄹ(l)', stage: AlphaStage.russianOnly, tip: '[ㄹ] 받침 느낌.'),
  CyrillicLetter(upper: 'П', lower: 'п', name: '뻬', roman: 'p', sound: 'ㅍ/ㅃ', stage: AlphaStage.russianOnly, tip: '그리스 π. [ㅍ].'),
  CyrillicLetter(upper: 'Ф', lower: 'ф', name: '에프', roman: 'f', sound: 'ㅍ(f)', stage: AlphaStage.russianOnly, tip: '[f].'),
  CyrillicLetter(upper: 'Ц', lower: 'ц', name: '쩨', roman: 'ts', sound: 'ㅉ(ts)', stage: AlphaStage.russianOnly, tip: '[ts] 한 소리.'),
  CyrillicLetter(upper: 'Ч', lower: 'ч', name: '체', roman: 'ch', sound: 'ㅊ', stage: AlphaStage.russianOnly, tip: '숫자 4처럼. [ㅊ].'),
  CyrillicLetter(upper: 'Ш', lower: 'ш', name: '샤', roman: 'sh', sound: '시(sh)', stage: AlphaStage.russianOnly, tip: '[sh] 굵게.'),
  CyrillicLetter(upper: 'Щ', lower: 'щ', name: '샤', roman: 'shch', sound: '시(부드럽게)', stage: AlphaStage.russianOnly, tip: 'Ш보다 부드러운 [sh].'),

  // ── 4단계 · 나머지 (친구 자음 · 반모음 · 부호) ───────────
  CyrillicLetter(upper: 'К', lower: 'к', name: '까', roman: 'k', sound: 'ㅋ/ㄲ', stage: AlphaStage.rest, tip: '영어 K와 같음 (친구).'),
  CyrillicLetter(upper: 'М', lower: 'м', name: '엠', roman: 'm', sound: 'ㅁ', stage: AlphaStage.rest, tip: '영어 M과 같음 (친구).'),
  CyrillicLetter(upper: 'Т', lower: 'т', name: '떼', roman: 't', sound: 'ㅌ/ㄸ', stage: AlphaStage.rest, tip: '영어 T와 같음. (단, 이탤릭 т는 m처럼!)'),
  CyrillicLetter(upper: 'Й', lower: 'й', name: '이 끄라뜨꼬예', roman: 'y', sound: '이(짧게)', stage: AlphaStage.rest, tip: '짧은 이. 반모음 [y]. И에 갈고리.'),
  CyrillicLetter(upper: 'Ъ', lower: 'ъ', name: '뜨뵤르드이 즈낙', roman: '—', sound: '(경음부호)', stage: AlphaStage.rest, tip: '소리 없음. 앞 자음을 굳힘.'),
  CyrillicLetter(upper: 'Ь', lower: 'ь', name: '먀흐끼 즈낙', roman: '—', sound: '(연음부호)', stage: AlphaStage.rest, tip: '소리 없음. 앞 자음을 부드럽게.'),
];
