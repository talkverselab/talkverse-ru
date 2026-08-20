import 'package:flutter/material.dart';

import '../data/l2_dialogues.dart';
import '../data/spoonfed_sentences.dart';
import '../domain/models/dialogue.dart';
import '../services/progress_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/today_card.dart';
import '../widgets/ui_kit.dart';
import 'alphabet/cyrillic_alphabet_screen.dart';
import 'cases/cases_home_screen.dart';
import 'conversation/dialogue_chat_screen.dart';
import 'conversation/flashcards_home_screen.dart';
import 'conversation/spoonfed_course_screen.dart';
import 'curriculum/curriculum_home_screen.dart';
import 'progress_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = <_TabDef>[
    _TabDef('홈', Icons.cottage_rounded, Icons.cottage_outlined),
    _TabDef('회화', Icons.style_rounded, Icons.style_outlined),
    _TabDef('문법', Icons.account_tree_rounded, Icons.account_tree_outlined),
    _TabDef('진행', Icons.bar_chart_rounded, Icons.bar_chart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            _HomeTab(onJump: (i) => setState(() => _index = i)),
            const FlashcardsHomeScreen(),
            const CurriculumHomeScreen(),
            const ProgressScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        tabs: _tabs,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData active;
  final IconData inactive;
  const _TabDef(this.label, this.active, this.inactive);
}

// ─────────────────────────────────────────────────────────── 홈 탭
// zh 앱 UX 구조 이식: 인사 헤더 + 🔥스트릭 + '오늘의 학습' 이어하기 + 메뉴 그리드.

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onJump});
  final ValueChanged<int> onJump;

  /// 오늘의 학습 대상 결정 — 마지막 활동 이어하기, 없으면 다음 미방문 다이얼로그.
  _TodayTarget _resolveToday() {
    final ps = ProgressService.instance;
    final last = ps.lastActivity;

    if (last != null && last.startsWith('spoonfed:')) {
      final id = last.substring('spoonfed:'.length);
      final course = spoonfedCourses.where((c) => c.id == id).firstOrNull;
      if (course != null && ps.spoonfedSeen(id) < course.sentences.length) {
        return _TodayTarget.spoonfed(course, ps.spoonfedSeen(id));
      }
    }

    final visited = ps.visitedDialogues;
    final next = l2Dialogues.where((d) => !visited.contains(d.id)).firstOrNull;
    if (next != null) {
      return _TodayTarget.dialogue(next, visited.length);
    }

    // 다이얼로그 전부 완료 → 미완료 떠먹여주는 코스.
    final course = spoonfedCourses
        .where((c) => ps.spoonfedSeen(c.id) < c.sentences.length)
        .firstOrNull;
    if (course != null) {
      return _TodayTarget.spoonfed(course, ps.spoonfedSeen(course.id));
    }
    return _TodayTarget.dialogue(l2Dialogues.first, visited.length);
  }

  @override
  Widget build(BuildContext context) {
    final ps = ProgressService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: ps.revision,
      builder: (context, _, _) {
        final today = _resolveToday();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            // ── 인사 헤더 + 스트릭 ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Приве́т! 👋', style: AppType.serif(26)),
                      const SizedBox(height: 4),
                      Text('한국 화자를 위한 러시아어 — 오늘도 한 문장.',
                          style: AppType.sans(12.5,
                              weight: FontWeight.w500,
                              color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StreakChip(days: ps.streak),
              ],
            ),
            const SizedBox(height: 20),

            // ── 오늘의 학습 (이어하기) ────────────────────
            const Eyebrow('오늘의 학습'),
            const SizedBox(height: 10),
            _todayCard(context, today),
            const SizedBox(height: 24),

            // ── 메인 메뉴 그리드 ─────────────────────────
            const Eyebrow('메인 메뉴'),
            const SizedBox(height: 10),
            _MenuGrid(onJump: onJump),
            const SizedBox(height: 24),

            // ── 왜 한국인에게 유리한가 ────────────────────
            const Eyebrow('왜 한국인에게 유리한가'),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                    child: _StatCard(
                        value: '1:1', label: '격 ↔ 조사', fill: AppColors.peach)),
                SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        value: '자유', label: '어순', fill: AppColors.mint)),
                SizedBox(width: 12),
                Expanded(
                    child:
                        _StatCard(value: '0', label: '관사', fill: AppColors.sky)),
              ],
            ),
            const SizedBox(height: 14),
            OutlineCard(
              fill: AppColors.lilacLight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hearing_rounded,
                      color: AppColors.ink, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '진짜 보스는 상(вид) 하나. 한국어·영어에 1:1 대응이 없어 '
                      '현지 듣기로 떠넘깁니다.',
                      style: AppType.sans(13,
                          weight: FontWeight.w500,
                          color: AppColors.ink,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Text('러시아어유니버스 · 2026',
                  style: AppType.sans(11,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                      spacing: 3)),
            ),
          ],
        );
      },
    );
  }

  Widget _todayCard(BuildContext context, _TodayTarget t) {
    if (t.course != null) {
      final c = t.course!;
      return TodayCard(
        tag: '떠먹여주는',
        title: c.title,
        subtitle: t.progress > 0 ? '보던 카드 이어서 굴리기' : '오늘 첫 카드 시작',
        progress: t.progress,
        total: c.sentences.length,
        fill: AppColors.mint,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  SpoonfedCourseScreen(course: c, fill: AppColors.mint)),
        ),
      );
    }
    final d = t.dialogue!;
    return TodayCard(
      tag: 'L2 회화',
      title: d.title,
      subtitle: '${d.turns.length}턴 · ${d.tone.ko} · 반전 ${d.twistLabel}',
      progress: t.progress,
      total: l2Dialogues.length,
      fill: AppColors.sky,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DialogueChatScreen(dialogue: d)),
      ),
    );
  }
}

class _TodayTarget {
  final Dialogue? dialogue;
  final SpoonfedCourse? course;
  final int progress;
  _TodayTarget.dialogue(this.dialogue, this.progress) : course = null;
  _TodayTarget.spoonfed(this.course, this.progress) : dialogue = null;
}

// ─────────────────────────────────────────────────── 메뉴 그리드

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.onJump});
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final ps = ProgressService.instance;
    final nextCourse = spoonfedCourses
            .where((c) => ps.spoonfedSeen(c.id) < c.sentences.length)
            .firstOrNull ??
        spoonfedCourses.first;

    final items = <_MenuItem>[
      _MenuItem('회화 챗', '다이얼로그 ${l2Dialogues.length}', Icons.chat_bubble_rounded,
          AppColors.sky, () => onJump(1)),
      _MenuItem(
          '떠먹여주는 600',
          nextCourse.title,
          Icons.restaurant_rounded,
          AppColors.mint,
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SpoonfedCourseScreen(
                  course: nextCourse, fill: AppColors.mint)))),
      _MenuItem('문법 10단계', '알파벳 50 + 문법 100', Icons.account_tree_rounded,
          AppColors.peach, () => onJump(2)),
      _MenuItem(
          '격변화 cliff',
          '격 6개를 조사처럼',
          Icons.layers_rounded,
          AppColors.lilac,
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CasesHomeScreen()))),
      _MenuItem(
          '알파벳 33자',
          'Аа · 소리부터',
          Icons.abc_rounded,
          AppColors.sky,
          () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CyrillicAlphabetScreen()))),
      _MenuItem('진행 리포트', '스트릭 · 섹션별', Icons.bar_chart_rounded,
          AppColors.peach, () => onJump(3)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MenuTile(item: items[i]),
    );
  }
}

class _MenuItem {
  final String label;
  final String sub;
  final IconData icon;
  final Color fill;
  final VoidCallback onTap;
  _MenuItem(this.label, this.sub, this.icon, this.fill, this.onTap);
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: item.fill,
      padding: const EdgeInsets.all(14),
      onTap: item.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 1.4),
            ),
            child: Icon(item.icon, color: AppColors.ink, size: 18),
          ),
          const SizedBox(height: 10),
          Text(item.label, style: AppType.serif(15.5)),
          const SizedBox(height: 2),
          Text(item.sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.sans(11,
                  weight: FontWeight.w600, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.value, required this.label, required this.fill});
  final String value;
  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: fill,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: AppType.serif(22)),
          const SizedBox(height: 4),
          Text(label,
              style: AppType.sans(12,
                  weight: FontWeight.w700, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── 하단 내비

class _BottomNav extends StatelessWidget {
  const _BottomNav(
      {required this.index, required this.tabs, required this.onTap});
  final int index;
  final List<_TabDef> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 1.4)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    def: tabs[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.def, required this.selected, required this.onTap});
  final _TabDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.inkFaint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.1 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(selected ? def.active : def.inactive,
                color: color, size: 25),
          ),
          const SizedBox(height: 4),
          Text(def.label,
              style: AppType.sans(10.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
