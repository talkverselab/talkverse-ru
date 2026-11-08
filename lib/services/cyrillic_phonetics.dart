// 키릴 문자 33자 + 강세·약화 규칙 — 글자별 발음 정보(IPA · 조음 위치 · 한국어 화자 비교).
// 「문자와 발음」 화면(alphabet_screen.dart)과 발음 시트(cyrillic_sound_sheet.dart)가 쓴다.
// IPA 는 표준 러시아어(모스크바) 기준. 한국어 비교 설명은 이 앱의 자체 작성.
// 설명 문구는 학습 콘텐츠라 번역하지 않는다(CLAUDE.md §5).

/// 조음 위치 — 간이 옆모습 그림(articulation_diagram.dart)에서 강조할 자리.
enum Place { lips, labiodental, dental, alveolar, postalveolar, palatal, velar, none }

/// 모음 사다리꼴 좌표(x: 0 = 앞 → 1 = 뒤, y: 0 = 높음 → 1 = 낮음).
class VowelSpot {
  final double x, y;
  final String ipa, label;
  const VowelSpot(this.x, this.y, this.ipa, this.label);
}

enum LetterKind { vowelHard, vowelSoft, voiced, voiceless, sonorant, unpaired, sign, rule }

class CyrLetter {
  final String upper, lower;
  final String name; // 글자 이름(TTS 로 읽힘): бэ, вэ …
  final String lat; // 로마자
  final String ipa;
  final LetterKind kind;
  final Place place;
  final String placeText; // 소리 나는 곳·입 모양
  final String example; // 예시 낱말(강세 부호 포함)
  final String exampleKo;
  final String korSim; // 비슷한 한국어 소리
  final String korDiff; // 한국어와 다른 점
  final String pair; // 짝 글자(유성/무성 · 경/연)
  final VowelSpot? ru; // 모음이면 러시아어 위치
  final List<VowelSpot> ko; // 이웃 한국어 모음
  const CyrLetter({
    required this.upper,
    required this.lower,
    required this.name,
    required this.lat,
    required this.ipa,
    required this.kind,
    required this.place,
    required this.placeText,
    required this.example,
    required this.exampleKo,
    required this.korSim,
    required this.korDiff,
    this.pair = '',
    this.ru,
    this.ko = const [],
  });

  bool get isVowel => kind == LetterKind.vowelHard || kind == LetterKind.vowelSoft;
}

const _a = VowelSpot(0.55, 1.0, 'a', 'а');
const _koA = VowelSpot(0.45, 0.92, 'ɐ', 'ㅏ');
const _e = VowelSpot(0.12, 0.62, 'ɛ', 'э');
const _koE = VowelSpot(0.14, 0.44, 'e', 'ㅔ');
const _y = VowelSpot(0.50, 0.05, 'ɨ', 'ы');
const _koEu = VowelSpot(0.82, 0.05, 'ɯ', 'ㅡ');
const _koI = VowelSpot(0.02, 0.02, 'i', 'ㅣ');
const _o = VowelSpot(0.96, 0.50, 'o', 'о');
const _koO = VowelSpot(0.96, 0.32, 'o', 'ㅗ');
const _koEo = VowelSpot(0.80, 0.62, 'ʌ', 'ㅓ');
const _u = VowelSpot(1.0, 0.02, 'u', 'у');
const _koU = VowelSpot(0.94, 0.04, 'u', 'ㅜ');
const _i = VowelSpot(0.0, 0.0, 'i', 'и');

const kLetters = <CyrLetter>[
  // ── 모음: 경모음 5 · 연모음 5
  CyrLetter(upper: 'А', lower: 'а', name: 'а', lat: 'a', ipa: 'a', kind: LetterKind.vowelHard, place: Place.none, pair: 'я',
    placeText: '입을 크게 벌리고 혀를 낮게. 강세가 없으면 짧고 약한 「어/아」 [ɐ]·[ə].',
    example: 'ма́ма', exampleKo: '엄마', korSim: 'ㅏ', korDiff: '한국어 ㅏ보다 입이 조금 더 크게 열린다. 강세가 없으면 약해진다(아깐예).',
    ru: _a, ko: [_koA, _koEo]),
  CyrLetter(upper: 'Э', lower: 'э', name: 'э', lat: 'e', ipa: 'ɛ', kind: LetterKind.vowelHard, place: Place.none, pair: 'е',
    placeText: '입을 반쯤 벌리고 혀를 앞쪽 가운데 높이에. 앞 자음을 무르게 하지 않는다.',
    example: 'э́то', exampleKo: '이것', korSim: 'ㅔ·ㅐ', korDiff: '한국어 ㅔ보다 입이 조금 더 열린 [ɛ]. 낱말 처음·외래어에 주로 나온다.',
    ru: _e, ko: [_koE]),
  CyrLetter(upper: 'Ы', lower: 'ы', name: 'ы', lat: 'y', ipa: 'ɨ', kind: LetterKind.vowelHard, place: Place.none, pair: 'и',
    placeText: '「이」 입 모양에서 혀를 뒤로 당긴다. 입술은 둥글리지 않는다.',
    example: 'ты', exampleKo: '너', korSim: 'ㅡ와 ㅣ 사이(「의」를 한 번에)', korDiff: '「으이」로 두 번 내지 말 것. 혀를 뒤로 당긴 채 한 소리. 낱말 처음엔 오지 않는다.',
    ru: _y, ko: [_koEu, _koI]),
  CyrLetter(upper: 'О', lower: 'о', name: 'о', lat: 'o', ipa: 'o', kind: LetterKind.vowelHard, place: Place.none, pair: 'ё',
    placeText: '입술을 둥글게. 강세가 있을 때만 「오」. 강세가 없으면 「아」[ɐ]·약한 「어」[ə].',
    example: 'молоко́', exampleKo: '우유 (말라꼬)', korSim: 'ㅗ(강세) / ㅏ(비강세)', korDiff: '한국어 ㅗ보다 입이 조금 더 열린다. 강세 없는 о 를 「오」로 읽는 것이 가장 흔한 실수.',
    ru: _o, ko: [_koO, _koEo]),
  CyrLetter(upper: 'У', lower: 'у', name: 'у', lat: 'u', ipa: 'u', kind: LetterKind.vowelHard, place: Place.none, pair: 'ю',
    placeText: '입술을 앞으로 내밀어 둥글게, 혀는 뒤쪽 높이.',
    example: 'у́тро', exampleKo: '아침', korSim: 'ㅜ', korDiff: '한국어 ㅜ보다 입술을 더 내민다.',
    ru: _u, ko: [_koU]),
  CyrLetter(upper: 'Я', lower: 'я', name: 'я', lat: 'ya', ipa: 'ja / ʲa', kind: LetterKind.vowelSoft, place: Place.none, pair: 'а',
    placeText: '자음 뒤에선 그 자음을 무르게(혀를 입천장 쪽으로) 하고 「아」. 낱말 처음·모음 뒤에선 「야」.',
    example: 'я', exampleKo: '나', korSim: 'ㅑ', korDiff: '자음 뒤의 я 는 「ㅑ」 전체가 아니라 자음을 무르게 + ㅏ. 강세가 없으면 「이」에 가깝다.',
    ru: _a, ko: [_koA]),
  CyrLetter(upper: 'Е', lower: 'е', name: 'е', lat: 'ye', ipa: 'je / ʲe', kind: LetterKind.vowelSoft, place: Place.none, pair: 'э',
    placeText: '앞 자음을 무르게 하고 「에」. 낱말 처음·모음 뒤에선 「예」.',
    example: 'нет', exampleKo: '아니요 (녵)', korSim: 'ㅖ', korDiff: '강세가 없으면 「이」[ɪ]에 가깝다(сестра́ → 시스뜨라).',
    ru: _e, ko: [_koE]),
  CyrLetter(upper: 'Ё', lower: 'ё', name: 'ё', lat: 'yo', ipa: 'jo / ʲo', kind: LetterKind.vowelSoft, place: Place.none, pair: 'о',
    placeText: '앞 자음을 무르게 하고 「오」. ё 는 언제나 강세를 받는다.',
    example: 'ёж', exampleKo: '고슴도치 (요시)', korSim: 'ㅛ', korDiff: '책·간판에서는 점을 빼고 е 로 쓰는 일이 많다. 이 앱은 점을 단다.',
    ru: _o, ko: [_koO]),
  CyrLetter(upper: 'Ю', lower: 'ю', name: 'ю', lat: 'yu', ipa: 'ju / ʲu', kind: LetterKind.vowelSoft, place: Place.none, pair: 'у',
    placeText: '앞 자음을 무르게 하고 「우」. 낱말 처음·모음 뒤에선 「유」.',
    example: 'люблю́', exampleKo: '사랑해 (류블류)', korSim: 'ㅠ', korDiff: '입술을 ㅠ보다 더 내민다.',
    ru: _u, ko: [_koU]),
  CyrLetter(upper: 'И', lower: 'и', name: 'и', lat: 'i', ipa: 'i / ʲi', kind: LetterKind.vowelSoft, place: Place.none, pair: 'ы',
    placeText: '입꼬리를 옆으로, 혀는 앞쪽 가장 높이. 앞 자음을 무르게 한다.',
    example: 'и́мя', exampleKo: '이름', korSim: 'ㅣ', korDiff: 'ж·ш·ц 뒤에서는 и 를 써도 ы 처럼 들린다(жизнь → 즤즈니).',
    ru: _i, ko: [_koI]),
  // ── 유성·무성 짝 6쌍
  CyrLetter(upper: 'Б', lower: 'б', name: 'бэ', lat: 'b', ipa: 'b', kind: LetterKind.voiced, place: Place.lips, pair: 'п',
    placeText: '두 입술을 닫았다 열며, 처음부터 목청을 울린다.', example: 'ба́бушка', exampleKo: '할머니',
    korSim: '모음 사이의 ㅂ(아버지의 ㅂ)', korDiff: '낱말 처음에서도 울림을 유지(한국어 낱말 첫 ㅂ은 울리지 않는다). 낱말 끝에선 [p] 로 바뀐다.'),
  CyrLetter(upper: 'П', lower: 'п', name: 'пэ', lat: 'p', ipa: 'p', kind: LetterKind.voiceless, place: Place.lips, pair: 'б',
    placeText: '두 입술을 닫았다 열며, 바람을 거의 내지 않는다.', example: 'па́па', exampleKo: '아빠',
    korSim: 'ㅃ', korDiff: 'ㅍ처럼 바람을 세게 내지 않는다. 된소리 ㅃ에 가깝다.'),
  CyrLetter(upper: 'В', lower: 'в', name: 'вэ', lat: 'v', ipa: 'v', kind: LetterKind.voiced, place: Place.labiodental, pair: 'ф',
    placeText: '윗니를 아랫입술에 대고 울리며 바람을 낸다.', example: 'вода́', exampleKo: '물',
    korSim: '없음(ㅂ로 적지만 다른 소리)', korDiff: '두 입술이 아니라 윗니+아랫입술. 무성음 앞·낱말 끝에선 [f].'),
  CyrLetter(upper: 'Ф', lower: 'ф', name: 'эф', lat: 'f', ipa: 'f', kind: LetterKind.voiceless, place: Place.labiodental, pair: 'в',
    placeText: '윗니를 아랫입술에 대고 울림 없이 바람만.', example: 'фо́то', exampleKo: '사진',
    korSim: '없음(ㅍ로 적지만 다른 소리)', korDiff: '두 입술을 붙이지 않는다.'),
  CyrLetter(upper: 'Г', lower: 'г', name: 'гэ', lat: 'g', ipa: 'ɡ', kind: LetterKind.voiced, place: Place.velar, pair: 'к',
    placeText: '혀 뒤를 여린입천장에 붙였다 떼며 울린다.', example: 'год', exampleKo: '해, 년',
    korSim: '모음 사이의 ㄱ', korDiff: '처음부터 울린다. -ого/-его 어미에서는 [v](его́ → 이보).'),
  CyrLetter(upper: 'К', lower: 'к', name: 'ка', lat: 'k', ipa: 'k', kind: LetterKind.voiceless, place: Place.velar, pair: 'г',
    placeText: '혀 뒤를 여린입천장에 붙였다 떼며, 바람을 거의 내지 않는다.', example: 'кот', exampleKo: '고양이',
    korSim: 'ㄲ', korDiff: 'ㅋ처럼 바람을 세게 내지 않는다.'),
  CyrLetter(upper: 'Д', lower: 'д', name: 'дэ', lat: 'd', ipa: 'd', kind: LetterKind.voiced, place: Place.dental, pair: 'т',
    placeText: '혀끝을 윗니 뒤에 붙였다 떼며 울린다.', example: 'дом', exampleKo: '집',
    korSim: '모음 사이의 ㄷ', korDiff: '혀끝이 잇몸이 아니라 윗니 뒤. е·и·я·ю·ь 앞에선 「지」에 가깝게 무르다.'),
  CyrLetter(upper: 'Т', lower: 'т', name: 'тэ', lat: 't', ipa: 't', kind: LetterKind.voiceless, place: Place.dental, pair: 'д',
    placeText: '혀끝을 윗니 뒤에 붙였다 떼며, 바람을 거의 내지 않는다.', example: 'там', exampleKo: '거기',
    korSim: 'ㄸ', korDiff: 'ㅌ처럼 바람을 내지 않는다. 무른 т(ть)는 「찌」에 가깝다.'),
  CyrLetter(upper: 'Ж', lower: 'ж', name: 'жэ', lat: 'zh', ipa: 'ʐ', kind: LetterKind.voiced, place: Place.postalveolar, pair: 'ш',
    placeText: '혀끝을 잇몸 뒤로 말아 올리고 울리며 바람을 낸다. 언제나 딱딱한 소리.',
    example: 'жена́', exampleKo: '아내', korSim: '없음(ㅈ로 적지만 다른 소리)', korDiff: 'ㅈ처럼 막았다 떼지 않고 계속 문지른다. 뒤의 и 는 ы 처럼 들린다.'),
  CyrLetter(upper: 'Ш', lower: 'ш', name: 'ша', lat: 'sh', ipa: 'ʂ', kind: LetterKind.voiceless, place: Place.postalveolar, pair: 'ж',
    placeText: '혀끝을 잇몸 뒤로 말아 올리고 울림 없이 바람만. 언제나 딱딱한 소리.',
    example: 'шко́ла', exampleKo: '학교', korSim: '「쉬」의 ㅅ', korDiff: '한국어 「시」보다 혀를 더 뒤로, 입술을 조금 내민다.'),
  CyrLetter(upper: 'З', lower: 'з', name: 'зэ', lat: 'z', ipa: 'z', kind: LetterKind.voiced, place: Place.dental, pair: 'с',
    placeText: '혀끝을 윗니 뒤 가까이 두고 울리며 바람을 낸다.', example: 'зима́', exampleKo: '겨울',
    korSim: '없음(ㅈ로 적지만 다른 소리)', korDiff: '막지 않고 「즈—」 하고 이어지는 소리. 낱말 끝에선 [s].'),
  CyrLetter(upper: 'С', lower: 'с', name: 'эс', lat: 's', ipa: 's', kind: LetterKind.voiceless, place: Place.dental, pair: 'з',
    placeText: '혀끝을 윗니 뒤 가까이 두고 울림 없이 바람만.', example: 'сок', exampleKo: '주스',
    korSim: 'ㅆ', korDiff: 'и 앞이 아니어도 늘 맑은 [s]. 「싸」에 가깝다.'),
  // ── 공명음 5
  CyrLetter(upper: 'Л', lower: 'л', name: 'эль', lat: 'l', ipa: 'ɫ / lʲ', kind: LetterKind.sonorant, place: Place.dental, pair: 'ль',
    placeText: '혀끝을 윗니 뒤에 대고 혀 뒤를 들어 「어둡게」. 무른 ль 는 혀 가운데를 입천장으로.',
    example: 'ло́жка', exampleKo: '숟가락', korSim: '받침 ㄹ', korDiff: '딱딱한 л 은 혀 뒤가 들려 한국어 ㄹ보다 굵고 어둡다.'),
  CyrLetter(upper: 'М', lower: 'м', name: 'эм', lat: 'm', ipa: 'm', kind: LetterKind.sonorant, place: Place.lips,
    placeText: '두 입술을 닫고 코로 소리.', example: 'мир', exampleKo: '세계, 평화', korSim: 'ㅁ', korDiff: '거의 같다.'),
  CyrLetter(upper: 'Н', lower: 'н', name: 'эн', lat: 'n', ipa: 'n', kind: LetterKind.sonorant, place: Place.dental,
    placeText: '혀끝을 윗니 뒤에 대고 코로 소리.', example: 'нос', exampleKo: '코', korSim: 'ㄴ', korDiff: '거의 같다. 무른 нь 는 「니」 쪽.'),
  CyrLetter(upper: 'Р', lower: 'р', name: 'эр', lat: 'r', ipa: 'r', kind: LetterKind.sonorant, place: Place.alveolar,
    placeText: '혀끝을 잇몸에 대고 2~3번 떤다(굴리는 r).', example: 'рука́', exampleKo: '손', korSim: '첫소리 ㄹ(한 번 튕김)', korDiff: '한 번 튕기지 말고 「르르」 떨린다. 처음엔 한 번 튕김도 통한다.'),
  CyrLetter(upper: 'Й', lower: 'й', name: 'и кра́ткое', lat: 'y', ipa: 'j', kind: LetterKind.sonorant, place: Place.palatal,
    placeText: '혀 가운데를 입천장으로 올려 짧게. 모음 뒤에만 온다.', example: 'чай', exampleKo: '차 (차이)',
    korSim: '「이」를 짧게(ㅐ→「아이」의 이)', korDiff: '한 음절을 따로 만들지 않는다. мой 는 「모-이」가 아니라 한 박자.'),
  // ── 짝 없는 자음 4
  CyrLetter(upper: 'Х', lower: 'х', name: 'ха', lat: 'kh', ipa: 'x', kind: LetterKind.unpaired, place: Place.velar,
    placeText: '혀 뒤를 여린입천장 가까이 두고 긁듯 바람을 낸다.', example: 'хлеб', exampleKo: '빵',
    korSim: 'ㅎ보다 긁는 소리', korDiff: '목이 아니라 입 뒤쪽에서 마찰. 「흐」를 가래 끓듯.'),
  CyrLetter(upper: 'Ц', lower: 'ц', name: 'цэ', lat: 'ts', ipa: 't͡s', kind: LetterKind.unpaired, place: Place.dental,
    placeText: '혀끝을 윗니 뒤에 붙였다가 [s] 로 풀어낸다. 언제나 딱딱한 소리.', example: 'цирк', exampleKo: '서커스',
    korSim: '「쯔」의 ㅉ', korDiff: '모음 「으」를 넣지 말고 [ts] 한 덩어리. 뒤의 и 는 ы 처럼.'),
  CyrLetter(upper: 'Ч', lower: 'ч', name: 'че', lat: 'ch', ipa: 't͡ɕ', kind: LetterKind.unpaired, place: Place.palatal,
    placeText: '혀 앞을 입천장 앞쪽에 붙였다 풀어낸다. 언제나 무른 소리.', example: 'час', exampleKo: '시간',
    korSim: 'ㅊ·ㅉ', korDiff: '한국어 ㅊ보다 바람이 적다. 「치」 쪽으로 무르게.'),
  CyrLetter(upper: 'Щ', lower: 'щ', name: 'ща', lat: 'shch', ipa: 'ɕː', kind: LetterKind.unpaired, place: Place.palatal,
    placeText: '혀 앞을 입천장 가까이 두고 무르고 길게 「쉬—」. 언제나 무른 소리.', example: 'щи', exampleKo: '양배추 수프',
    korSim: '「시」를 길게', korDiff: 'ш 보다 무르고(혀를 앞으로), 더 길다.'),
  // ── 부호 2
  CyrLetter(upper: 'Ъ', lower: 'ъ', name: 'твёрдый знак', lat: '"', ipa: '—', kind: LetterKind.sign, place: Place.none,
    placeText: '소리 없음. 앞 자음과 뒤 모음 사이를 「끊어」 읽게 한다.', example: 'подъе́зд', exampleKo: '아파트 현관',
    korSim: '없음', korDiff: 'подъе́зд 는 「빠-드예스트」: д 와 е 를 붙여 「뎨」로 읽지 않는다.'),
  CyrLetter(upper: 'Ь', lower: 'ь', name: 'мя́гкий знак', lat: '\'', ipa: 'ʲ', kind: LetterKind.sign, place: Place.palatal,
    placeText: '소리 없음. 앞 자음을 무르게(혀 가운데를 입천장으로) 한다.', example: 'мать', exampleKo: '어머니 (마찌)',
    korSim: '없음(「이」를 소리 내지 않고 입만)', korDiff: 'брат(형제)와 брать(가지다)는 끝 자음의 무름만 다르다.'),
];

/// 강세·약화·동화 — 글자가 아니라 「규칙」 칸. 탭하면 예시 낱말을 읽는다.
const kRules = <CyrLetter>[
  CyrLetter(upper: 'о→а', lower: '', name: 'молоко́', lat: 'akanye', ipa: 'məlɐˈko', kind: LetterKind.rule, place: Place.none,
    placeText: '강세 없는 о 는 「아」 또는 약한 「어」. 강세 바로 앞은 [ɐ], 그 밖은 [ə].', example: 'молоко́', exampleKo: '우유 → 말라꼬',
    korSim: 'ㅏ·ㅓ(약하게)', korDiff: '철자는 о 셋이지만 「오」는 강세 받은 마지막 하나뿐.'),
  CyrLetter(upper: 'е·я→и', lower: '', name: 'язы́к', lat: 'ikanye', ipa: 'jɪˈzɨk', kind: LetterKind.rule, place: Place.none,
    placeText: '강세 없는 е·я 는 약한 「이」[ɪ].', example: 'язы́к', exampleKo: '혀, 언어 → 이즤크',
    korSim: 'ㅣ(약하게)', korDiff: 'сестра́ → 시스뜨라, телефо́н → 찔리폰.'),
  CyrLetter(upper: '끝 무성화', lower: '', name: 'хлеб', lat: 'devoicing', ipa: 'xlʲep', kind: LetterKind.rule, place: Place.none,
    placeText: '낱말 끝의 유성 자음(б в г д ж з)은 짝 무성음으로.', example: 'хлеб', exampleKo: '빵 → 흘롑',
    korSim: '받침 ㅂ·ㄷ·ㄱ', korDiff: 'год → 곹, друг → 드룩, раз → 라스.'),
  CyrLetter(upper: '동화', lower: '', name: 'вчера́', lat: 'assimilation', ipa: 'fʲtɕɪˈra', kind: LetterKind.rule, place: Place.none,
    placeText: '자음이 이어지면 뒤 자음의 유성/무성을 따른다.', example: 'вчера́', exampleKo: '어제 → 프치라',
    korSim: '한국어 자음 동화와 비슷한 생각', korDiff: 'в 가 무성 ч 앞에서 [f]. вокза́л 은 к 가 з 앞에서 [g].'),
  CyrLetter(upper: '경/연', lower: '', name: 'брат — брать', lat: 'palatalization', ipa: 'brat / bratʲ', kind: LetterKind.rule, place: Place.palatal,
    placeText: '같은 자음도 딱딱한(경)·무른(연) 두 소리. 연음은 혀 가운데를 입천장으로 올린다.', example: 'брат, брать', exampleKo: '형제 / 가지다',
    korSim: '「다-댜」, 「마-먀」의 차이', korDiff: '뜻이 갈린다: мат(매트)·мать(어머니), ел(먹었다)·ель(전나무).'),
  CyrLetter(upper: 'ё 강세', lower: '', name: 'всё', lat: 'yo stress', ipa: 'fsʲo', kind: LetterKind.rule, place: Place.none,
    placeText: 'ё 가 있는 낱말은 거기에 강세. 강세 위치는 낱말마다 외운다(규칙 없음 — 이 앱은 강세 부호를 단다).', example: 'всё', exampleKo: '모든 것 → 프쇼',
    korSim: '없음', korDiff: 'рука́(손이) / ру́ку(손을)처럼 같은 낱말도 격에 따라 강세가 옮는다.'),
];
