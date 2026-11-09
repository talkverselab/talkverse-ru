# 러시아어 유니버스 — 스토어 준비(가격·차별화·출시 조건) · 2026-11-09

근거: `~/talkverse/PRICING.md`(사용자 확정 2026-11-09), `~/talkverse/STORE_DIFFERENTIATION.md`(애플 지침 4.3 대비, 사용자 "엄청 중요해"). 숫자는 이 앱 실측 — 출시 직전에 다시 센다.

## 1. 가격(앱 안) — 결제 화면을 만들 때 그대로

| 상품 | 상품 ID | 앱 정가 | 앱 할인가(출시 기념·정기 30%) |
|---|---|---|---|
| 러시아어 1개월(자동 갱신) | `lang_ru_1m` | 5,500 | 3,900 |
| 러시아어 3개월(자동 갱신) | `lang_ru_3m` | 12,900 | 9,000 |
| 러시아어 1년(자동 갱신) | `lang_ru_1y` | 28,500 | 19,900 |
| 러시아어 평생(서비스 운영 기간 동안) | `lang_ru_life` | 69,900 | 49,000 |
| 종합 1년(전 언어) | `all_1y` | 112,900 | 79,000 |
| 종합 평생 | `all_life` | 469,000 | 329,000(할인 없음) |

- 결제 화면 필수: 기간·자동 갱신과 해지 방법(스토어 구독 설정), 「평생 이용권(서비스 운영 기간 동안)」, 구매 복원, 약관·개인정보처리방침 링크. **앱 안에서 사이트 가격을 안내하지 않는다.**
- **현재 상태: 이 앱에는 로그인·결제 코드가 아직 없다**(Talkverse ID 로그인·결제는 공통 프롬프터 §11 "사용자가 「착수」라고 한 뒤"). 착수 때 일본어앱 `lib/screens/paywall_screen.dart`·`lib/services/purchase.dart`·`account.dart`·`widgets/legal_links.dart`(커밋 6ed3774, 새 가격표 반영본)를 옮기고 상품 ID 를 `lang_ru_*` 로. App Store Connect·Play 상품 등록은 사용자, Talkverse ID client_id `ru` 등록은 uk 세션.
- 출시 첫 판은 잠금 없이 전부 무료(PRICING.md).

## 2. 스토어 설명(한국어 초안)

**첫 줄**: 러시아어 6격, 한국어 조사 6개로 바로 대응시켜 외웁니다 — 단어 156개로 대사의 55%를 듣는 러시아어.

**이 앱에만 있는 학습 도구**
1. **키릴 문자와 발음** — 33자 격자(모음 10 · 유성/무성 짝 12 · 공명음 5 · 짝 없는 자음 4 · 부호 2) + 강세·약화 규칙 6(о→а, е·я→и, 끝 무성화, 동화, 경/연음, ё 강세). 글자마다 자동 발음, IPA, 조음 위치 그림, 러시아어·한국어 모음 위치 비교, 한국어 화자가 틀리는 지점.
2. **격 골격 10단계** — 격을 한국어 조사(은/는·을/를·에게·의·으로·에서)로 바꿔 익힌다. 단수 1·2·3인칭으로 격을 끝낸 뒤 복수·존댓말(Вы)을 같은 문장에 갈아끼운다(그래머2).
3. **강세 부호와 한글 독음** — 모든 문장에 강세 부호, 소리 나는 대로 적은 한글 독음(아깐예 반영), 둘 다 켜고 끌 수 있다.
4. **학습자 성별판** — 러시아어는 말하는 사람의 성별로 과거형이 바뀐다(я был / была). 회화·음성 모두 남/여 두 판.
5. **절벽 단어 3,000** — 러시아 영화·드라마 대사 1,303만 토큰에서 잰 빈도. 156 → 55%, 251 → 60%, 685 → 70%, 1,985 → 80%, 3,000 → 83.6%.

**숫자**: 회화 6레벨(도구획득·격 골격·챗 실전·그래머2·어려운 문법·어휘 완주) [N]편 · 음성 [N]줄 · 단어 3,000(한국어 뜻) — [N] 은 출시 직전 실측으로 채운다.

**공통(마지막에 짧게)**: Talkverse 계정(선택)·오프라인 학습·결제 안내.

## 3. 심사 메모(App Review Notes) 필수 문단

```
This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Russian app has its own script & pronunciation module (33 Cyrillic letters in 6 groups plus 6 stress/vowel-reduction rules, with IPA, articulation diagrams and Russian-vs-Korean vowel charts), its own grammar tools (a 10-step case skeleton that maps the six Russian cases onto Korean particles, learner-gender variants of every line, stress marks and Korean-script readings), [N] original conversation episodes with recorded audio written for this language, and a vocabulary list measured from a Russian conversation corpus (156 words = 55%, 1,985 words = 80% of film/TV dialogue). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.
```

## 4. 스크린샷 순서(고유 화면 먼저)
1. 키릴 문자와 발음 — 33자 격자(로마자 켬)
2. 발음 시트 — 예: о(강세/비강세) 또는 ы(러 vs 한 모음 위치 그림)
3. 회화 리더 — 격 표시가 보이는 장면(「격」 자막 UI 가 들어간 뒤)
4. 절벽 단어 — R1~R5 구간표
5. 홈·프로필은 맨 뒤 또는 넣지 않음

## 5. 출시 전 막는 것(지침 2.1 — 하나라도 남으면 내지 않는다)
- [ ] **표현** 메뉴: 데이터 비어 있음(themes 0, 2026-11-02 저작권 정리로 삭제) → 채우거나 메뉴에서 뺀다
- [ ] **문법** 메뉴: 레슨 1개뿐 → 격 골격 10단계로 채운다
- [ ] **단어 카드**: 주제 1개 → 절벽 단어 3,000 기반으로 바꾼다
- [ ] **회화**: 앱은 아직 옛 `L1.json` 18편만 읽음 → Grok 재작성·사용자 통과한 레벨 0~5 편으로 연결
- [ ] 회화 음성(Grok 재작성 뒤), 장면 컷
- [ ] 「격」 자막·「말 조각」 카드(통과된 UX 시안 01)
- [ ] 강세 부호 표시/미표시 토글(문법 요소 배치 결정)
- [ ] 조음 그림을 Grok 그림으로 교체(지금은 임시)
- [ ] 로그인·결제(§1) — 출시 첫 판이 무료면 결제 없이 내는 것도 가능(사용자 결정)
- [ ] 개인정보처리방침·약관 페이지(talkverse.uk/talkverse/ru/…) — uk 세션
