import '../domain/models/sentence.dart';

/// 단계별 일상 예문 (L1·L2 어휘).
///
/// 각 토큰: 키릴 어간|어미 + 한글 독음(stemKo|inflKo). 어미는 성(色)·동사(굵게).
/// 남성 명사도 "꼬리"(성을 만드는 끝)를 성색으로. 독음에도 라임이 같은 색으로 뜬다.
const Map<String, List<Sentence>> curriculumSentences = {
  // ── 1단계 · 형용사+명사 (주격). 성 일치 라임. ──────────────
  's1': [
    Sentence([
      Tok('Э́то', stemKo: '에따'),
      Tok('о́чень', stemKo: '오친'),
      Tok('но́в', infl: 'ый', stemKo: '노브', inflKo: '이', gender: Gender.masc),
      Tok('до', infl: 'м', stemKo: '도', inflKo: 'ㅁ', gender: Gender.masc),
    ], ko: '이거 아주 새 집이야.', note: '남성: 형용사 -ый + 명사 꼬리 둘 다 남성색'),
    Sentence([
      Tok('Э́то', stemKo: '에따'),
      Tok('о́чень', stemKo: '오친'),
      Tok('хоро́ш', infl: 'ая', stemKo: '하로', inflKo: '샤야', gender: Gender.fem),
      Tok('ма́м', infl: 'а', stemKo: '마', inflKo: '마', gender: Gender.fem),
    ], ko: '정말 좋은 엄마야.', note: '여성 라임 [샤야 … 마]'),
    Sentence([
      Tok('Э́то', stemKo: '에따'),
      Tok('вку́сн', infl: 'ое', stemKo: '브꾸스', inflKo: '나예', gender: Gender.neut),
      Tok('тёпл', infl: 'ое', stemKo: '쬬쁠', inflKo: '라예', gender: Gender.neut),
      Tok('молок', infl: 'о́', stemKo: '말라', inflKo: '꼬', gender: Gender.neut),
    ], ko: '이건 맛있고 따뜻한 우유야.', note: '중성 라임 [나예 … 라예 … 꼬]'),
    Sentence([
      Tok('Москва́', stemKo: '마스크바'),
      Tok('—', stemKo: ''),
      Tok('о́чень', stemKo: '오친'),
      Tok('ста́р', infl: 'ый', stemKo: '스따', inflKo: '르이', gender: Gender.masc),
      Tok('и', stemKo: '이'),
      Tok('краси́в', infl: 'ый', stemKo: '크라시', inflKo: '브이', gender: Gender.masc),
      Tok('го́род', stemKo: '고', inflKo: '랏', gender: Gender.masc),
    ], ko: '모스크바는 아주 오래되고 아름다운 도시야.', note: '남성 두 형용사 + 명사 꼬리'),
    Sentence([
      Tok('Э́то', stemKo: '에따'),
      Tok('но́в', infl: 'ая', stemKo: '노브', inflKo: '아야', gender: Gender.fem),
      Tok('и', stemKo: '이'),
      Tok('бы́стр', infl: 'ая', stemKo: '븨스트', inflKo: '라야', gender: Gender.fem),
      Tok('маши́н', infl: 'а', stemKo: '마시', inflKo: '나', gender: Gender.fem),
    ], ko: '이건 새롭고 빠른 차야.', note: '여성 라임 [아야 … 라야 … 나]'),
  ],

  // ── 2단계 · 과거동사(-л/-ла) + 가정법(бы) ──────────────────
  's2': [
    Sentence([
      Tok('Вчера́', stemKo: '프치라'),
      Tok('я', stemKo: '야'),
      Tok('о́чень', stemKo: '오친'),
      Tok('хоте́', infl: 'л', stemKo: '하쪠', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('горя́чий', stemKo: '가랴치'),
      Tok('ко́фе', stemKo: '꼬폐'),
    ], ko: '어제 나 뜨거운 커피가 정말 마시고 싶었어. (남자)', note: '과거 -л = 동사 + 남성'),
    Sentence([
      Tok('Вчера́', stemKo: '프치라'),
      Tok('я', stemKo: '야'),
      Tok('то́же', stemKo: '또제'),
      Tok('хоте́', infl: 'ла', stemKo: '하쪠', inflKo: '라', gender: Gender.fem, verb: true),
      Tok('ко́фе', stemKo: '꼬폐'),
    ], ko: '어제 나도 커피 마시고 싶었어. (여자)', note: '같은 동사, 여성 -ла [라]'),
    Sentence([
      Tok('Ма́ма', stemKo: '마마'),
      Tok('до́лго', stemKo: '돌가'),
      Tok('гото́ви', infl: 'ла', stemKo: '가또비', inflKo: '라', gender: Gender.fem, verb: true),
      Tok('вку́сный', stemKo: '브꾸스늬'),
      Tok('у́жин', stemKo: '우진'),
    ], ko: '엄마가 맛있는 저녁을 오래 준비했어.', note: '주어(엄마=여성) → 동사도 여성 -ла'),
    Sentence([
      Tok('Па́па', stemKo: '빠빠'),
      Tok('весь', stemKo: '볘시'),
      Tok('день', stemKo: '졘'),
      Tok('тяжело́', stemKo: '찌질로'),
      Tok('рабо́та', infl: 'л', stemKo: '라보따', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
    ], ko: '아빠는 온종일 힘들게 일했어.', note: '주어(아빠=남성) → 동사 -л'),
    Sentence([
      Tok('Я', stemKo: '야'),
      Tok('хоте́', infl: 'л', stemKo: '하쪠', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('бы', stemKo: '븨'),
      Tok('ча́шку', stemKo: '차시꾸'),
      Tok('ко́фе', stemKo: '꼬폐'),
      Tok('пожа́луйста', stemKo: '빠잘스따'),
    ], ko: '커피 한 잔 주시겠어요, 부탁드려요.', note: '과거 + бы = 정중한 요청'),
  ],

  // ── 3단계 · 과거동사 + 대/여/생격 ─────────────────────────
  's3': [
    Sentence([
      Tok('Вчера́', stemKo: '프치라'),
      Tok('я', stemKo: '야'),
      Tok('случа́йно', stemKo: '슬루차이나'),
      Tok('ви́де', infl: 'л', stemKo: '비졔', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('ста́рого', stemKo: '스따라바'),
      Tok('дру́г', infl: 'а', stemKo: '드루', inflKo: '가', gender: Gender.masc, josa: '을/를'),
    ], ko: '어제 우연히 옛 친구를 봤어.', note: '대격(을/를)'),
    Sentence([
      Tok('Я', stemKo: '야'),
      Tok('да', infl: 'л', stemKo: '다', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('ма́м', infl: 'е', stemKo: '마', inflKo: '몌', gender: Gender.fem, josa: '에게'),
      Tok('но́вую', stemKo: '노부유'),
      Tok('кни́г', infl: 'у', stemKo: '크니', inflKo: '구', gender: Gender.fem, josa: '을/를'),
    ], ko: '엄마한테 새 책을 줬어.', note: '여격(에게) + 대격(을/를)'),
    Sentence([
      Tok('Я', stemKo: '야'),
      Tok('до́лго', stemKo: '돌가'),
      Tok('жда', infl: 'л', stemKo: '즈다', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('тебя́', stemKo: '찌뱌'),
      Tok('на', stemKo: '나'),
      Tok('рабо́те', stemKo: '라보쪠'),
    ], ko: '직장에서 너 오래 기다렸어.'),
    Sentence([
      Tok('Он', stemKo: '온'),
      Tok('наконе́ц', stemKo: '나까녯'),
      Tok('сказа́', infl: 'л', stemKo: '스까자', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('мне', stemKo: '므녜'),
      Tok('всю', stemKo: '프슈'),
      Tok('пра́вд', infl: 'у', stemKo: '프라브', inflKo: '두', gender: Gender.fem, josa: '을/를'),
    ], ko: '그가 드디어 나한테 진실을 다 말했어.'),
    Sentence([
      Tok('У', stemKo: '우'),
      Tok('ма́м', infl: 'ы', stemKo: '마', inflKo: '믜', gender: Gender.fem, josa: '의'),
      Tok('сего́дня', stemKo: '시보드냐'),
      Tok('мно́го', stemKo: '므노가'),
      Tok('рабо́т', infl: 'ы', stemKo: '라보', inflKo: '띄', gender: Gender.fem, josa: '의'),
    ], ko: '엄마는 오늘 일이 많아.', note: 'У + 생격 = 소유 / мно́го + 생격'),
  ],

  // ── 3'단계 · 전치사구 + с(동반) ───────────────────────────
  's3p': [
    Sentence([
      Tok('Сейча́с', stemKo: '시차스'),
      Tok('я', stemKo: '야'),
      Tok('жив', infl: 'у́', stemKo: '즤', inflKo: '부', verb: true),
      Tok('и', stemKo: '이'),
      Tok('рабо́таю', stemKo: '라보따유'),
      Tok('в', stemKo: '브'),
      Tok('Москв', infl: 'е́', stemKo: '마스크', inflKo: '볘', gender: Gender.fem, josa: '에서'),
    ], ko: '나 지금 모스크바에서 살고 일해.', note: 'в + 전치격(장소)'),
    Sentence([
      Tok('За́втра', stemKo: '자프트라'),
      Tok('я', stemKo: '야'),
      Tok('ид', infl: 'у́', stemKo: '이', inflKo: '두', verb: true),
      Tok('в', stemKo: '브'),
      Tok('кино́', stemKo: '끼노'),
      Tok('с', stemKo: '스'),
      Tok('дру́г', infl: 'ом', stemKo: '드루', inflKo: '곰', gender: Gender.masc, josa: '와'),
    ], ko: '내일 친구랑 영화 보러 가.', note: 'с + 조격(동반)'),
    Sentence([
      Tok('По́сле', stemKo: '뽀슬례'),
      Tok('рабо́ты', stemKo: '라보띄'),
      Tok('я', stemKo: '야'),
      Tok('е́д', infl: 'у', stemKo: '예', inflKo: '두', verb: true),
      Tok('к', stemKo: '크'),
      Tok('ма́м', infl: 'е', stemKo: '마', inflKo: '몌', gender: Gender.fem, josa: '에게로'),
    ], ko: '퇴근하고 엄마한테 가.', note: 'к + 여격(방향)'),
    Sentence([
      Tok('Тво', infl: 'я́', stemKo: '뜨바', inflKo: '야', gender: Gender.fem),
      Tok('кни́г', infl: 'а', stemKo: '크니', inflKo: '가', gender: Gender.fem),
      Tok('сейча́с', stemKo: '시차스'),
      Tok('на', stemKo: '나'),
      Tok('стол', infl: 'е́', stemKo: '스딸', inflKo: '례', gender: Gender.masc, josa: '위에'),
    ], ko: '네 책 지금 탁자 위에 있어.', note: 'на + 전치격 / 여성 라임 [야 … 가]'),
  ],

  // ── 4단계 · 규칙동사 1식·2식 (단수 3인칭) ─────────────────
  's4': [
    Sentence([
      Tok('Он', stemKo: '온'),
      Tok('хорошо́', stemKo: '하라쇼'),
      Tok('зна́', infl: 'ет', stemKo: '즈나', inflKo: '예트', verb: true),
      Tok('э́тот', stemKo: '에떳'),
      Tok('го́род', stemKo: '고랏'),
    ], ko: '그는 이 도시를 잘 알아.', note: '1식 현재 -ет'),
    Sentence([
      Tok('Она́', stemKo: '아나'),
      Tok('о́чень', stemKo: '오친'),
      Tok('бы́стро', stemKo: '븨스트라'),
      Tok('говор', infl: 'и́т', stemKo: '가바', inflKo: '리트', verb: true),
      Tok('по-ру́сски', stemKo: '빠루스끼'),
    ], ko: '그녀는 러시아어를 아주 빨리 해.', note: '2식 현재 -ит'),
    Sentence([
      Tok('Мой', stemKo: '모이'),
      Tok('друг', stemKo: '드룩'),
      Tok('ка́ждый', stemKo: '까즈듸'),
      Tok('день', stemKo: '졘'),
      Tok('чита́', infl: 'ет', stemKo: '치따', inflKo: '예트', verb: true),
      Tok('кни́ги', stemKo: '크니기'),
    ], ko: '내 친구는 매일 책을 읽어.'),
    Sentence([
      Tok('Она́', stemKo: '아나'),
      Tok('сейча́с', stemKo: '시차스'),
      Tok('рабо́та', infl: 'ет', stemKo: '라보따', inflKo: '예트', verb: true),
      Tok('в', stemKo: '브'),
      Tok('большо́м', stemKo: '발쇼ㅁ'),
      Tok('го́роде', stemKo: '고라졔'),
    ], ko: '그녀는 지금 큰 도시에서 일해.'),
    Sentence([
      Tok('Он', stemKo: '온'),
      Tok('ча́сто', stemKo: '차스따'),
      Tok('ду́ма', infl: 'ет', stemKo: '두마', inflKo: '예트', verb: true),
      Tok('о', stemKo: '아'),
      Tok('рабо́те', stemKo: '라보쪠'),
    ], ko: '그는 일 생각을 자주 해.'),
  ],

  // ── 4'단계 · 조격 단독 (도구·신분·быть 보어) ──────────────
  's4p': [
    Sentence([
      Tok('Ра́ньше', stemKo: '란셰'),
      Tok('он', stemKo: '온'),
      Tok('бы', infl: 'л', stemKo: '븨', inflKo: 'ㄹ', gender: Gender.masc, verb: true),
      Tok('хоро́шим', stemKo: '하로심'),
      Tok('учи́тел', infl: 'ем', stemKo: '우치쪨', inflKo: '롐', gender: Gender.masc, josa: '(으)로'),
    ], ko: '예전에 그는 좋은 교사였어.', note: '조격 = быть 보어(신분)'),
    Sentence([
      Tok('Я', stemKo: '야'),
      Tok('всегда́', stemKo: '프시그다'),
      Tok('пиш', infl: 'у́', stemKo: '삐', inflKo: '슈', verb: true),
      Tok('пи́сьма', stemKo: '삐시마'),
      Tok('ру́чк', infl: 'ой', stemKo: '루치', inflKo: '꼬이', gender: Gender.fem, josa: '(으)로'),
    ], ko: '나는 항상 편지를 펜으로 써.', note: '조격 = 도구'),
    Sentence([
      Tok('Тепе́рь', stemKo: '찌뼤리'),
      Tok('она́', stemKo: '아나'),
      Tok('рабо́тает', stemKo: '라보따예트'),
      Tok('хоро́шим', stemKo: '하로심'),
      Tok('врач', infl: 'о́м', stemKo: '브라', inflKo: '촘', gender: Gender.masc, josa: '(으)로'),
    ], ko: '이제 그녀는 좋은 의사로 일해.', note: '조격 = 신분'),
  ],

  // ── 5단계 · 불규칙 동사 (통문장) ──────────────────────────
  's5': [
    Sentence([
      Tok('Я', stemKo: '야'),
      Tok('о́чень', stemKo: '오친'),
      Tok('хоч', infl: 'у́', stemKo: '하', inflKo: '추', verb: true),
      Tok('есть', stemKo: '예스찌'),
      Tok('и', stemKo: '이'),
      Tok('спать', stemKo: '스빠찌'),
    ], ko: '나 너무 배고프고 졸려.', note: 'хотеть 불규칙 + 부정사'),
    Sentence([
      Tok('Е́сли', stemKo: '예슬리'),
      Tok('хо́чешь', stemKo: '호체시'),
      Tok(',', stemKo: ''),
      Tok('я', stemKo: '야'),
      Tok('мог', infl: 'у́', stemKo: '마', inflKo: '구', verb: true),
      Tok('тебе́', stemKo: '찌볘'),
      Tok('помо́чь', stemKo: '빠모치'),
    ], ko: '원하면 내가 도와줄 수 있어.', note: 'мочь 불규칙'),
    Sentence([
      Tok('Уже́', stemKo: '우제'),
      Tok('по́здно', stemKo: '뽀즈나'),
      Tok(',', stemKo: ''),
      Tok('я', stemKo: '야'),
      Tok('ид', infl: 'у́', stemKo: '이', inflKo: '두', verb: true),
      Tok('домо́й', stemKo: '다모이'),
    ], ko: '벌써 늦었네, 나 집에 갈게.', note: 'идти 불규칙'),
    Sentence([
      Tok('У', stemKo: '우'),
      Tok('меня́', stemKo: '미냐'),
      Tok('сейча́с', stemKo: '시차스'),
      Tok('совсе́м', stemKo: '사프솀'),
      Tok('нет', stemKo: '녯'),
      Tok('вре́мени', stemKo: '브례미니'),
    ], ko: '나 지금 시간이 전혀 없어.', note: 'нет + 생격 = 없음'),
  ],

  // ── 6단계 · вид(상) + 미래 ────────────────────────────────
  's6': [
    Sentence([
      Tok('За́втра', stemKo: '자프트라'),
      Tok('я', stemKo: '야'),
      Tok('весь', stemKo: '볘시'),
      Tok('день', stemKo: '졘'),
      Tok('бу́д', infl: 'у', stemKo: '부', inflKo: '두', verb: true),
      Tok('рабо́тать', stemKo: '라보따찌'),
    ], ko: '내일 나 온종일 일할 거야.', note: '불완료 미래 = буду + 부정사'),
    Sentence([
      Tok('Не', stemKo: '니'),
      Tok('волну́йся', stemKo: '발누이샤'),
      Tok(',', stemKo: ''),
      Tok('я', stemKo: '야'),
      Tok('всё', stemKo: '프쇼'),
      Tok('сде́ла', infl: 'ю', stemKo: '즈졜라', inflKo: '유', verb: true),
      Tok('за́втра', stemKo: '자프트라'),
    ], ko: '걱정 마, 내일 다 해놓을게.', note: '완료 미래 = 한 단어'),
    Sentence([
      Tok('Не', stemKo: '니'),
      Tok('спеши́', stemKo: '스삐시'),
      Tok(',', stemKo: ''),
      Tok('я', stemKo: '야'),
      Tok('бу́д', infl: 'у', stemKo: '부', inflKo: '두', verb: true),
      Tok('ждать', stemKo: '즈다찌'),
    ], ko: '서두르지 마, 기다리고 있을게.'),
    Sentence([
      Tok('Ско́ро', stemKo: '스꼬라'),
      Tok('всё', stemKo: '프쇼'),
      Tok('бу́д', infl: 'ет', stemKo: '부', inflKo: '졛', verb: true),
      Tok('хорошо́', stemKo: '하라쇼'),
    ], ko: '곧 다 잘될 거야.'),
  ],
};

/// 단계별 핵심 포인트 — 설명 보강(불릿). grammar_stage_screen 에서 카드로.
const grammarPoints = <String, List<String>>{
  'alpha': [
    '1군 А К М О Т는 영어와 모양·소리가 같다.',
    '발음 규칙은 외우지 말고 [소리]로 흘려라.',
    '"대충 읽기"가 목표 — 정확한 음독은 나중에.',
  ],
  's1': [
    '명사의 "꼬리"가 성을 만든다 → 명사 꼬리도 성색으로.',
    '형용사 어미는 명사의 성을 따라간다: -ый(남)/-ая(여)/-ое(중).',
    '러시아어·독음에서 같은 색이면 라임이 맞는 것.',
  ],
  's2': [
    '과거형 = 부정사어간 + -л/-ла/-ло/-ли (인칭 무시, 성·수만).',
    '과거동사 어미도 형용사처럼 성에 일치한다.',
    '과거 + бы = 정중한 요청·가정.',
  ],
  's3': [
    '동사가 격을 결정한다: 보다(대격)·주다(여격)·기다리다(대격).',
    '격 = 한국어 조사(을/를·에게·의).',
    '주어를 바꿔도 목적어 격은 그대로.',
  ],
  's3p': [
    '전치사가 격을 정한다 (в+전치격, с+조격, к+여격…).',
    'в/на는 의미(위치 vs 방향)로 격이 갈린다.',
    'с+조격 = 동반(~와 함께).',
  ],
  's4': [
    '규칙동사 1식(-ет)·2식(-ит), 단수 3인칭만.',
    '복수는 잠금 — 단수 자동화 후 해금.',
    '현재 어미는 성과 무관 (색 없이 굵게만).',
  ],
  's4p': [
    '조격 단독 = 도구(~로)·신분(~로서)·быть 보어.',
    "동반(с)은 3' 단계에서 따로 다룬다.",
  ],
  's5': [
    'быть·хоте́ть·мочь·дать·идти… 고빈도 8개 불규칙.',
    '표로 외우지 말고 통문장으로.',
    '원어민도 인칭표로 갖고 있지 않다.',
  ],
  's6': [
    '불완료 미래 = бу́ду + 부정사 / 완료 미래 = 한 단어.',
    'вид(상)는 2달에 정복 불가 — 씨앗만 심는다.',
    '나머지는 현지 듣기로 떠넘긴다.',
  ],
};
