import 'package:flutter/material.dart';

import 'about_screen.dart';

import '../core/theme.dart';
import '../services/learner_prefs.dart';
import '../widgets/spanish_decor.dart';
import '../core/l10n.dart';
import '../core/pane.dart';
import '../services/ko_reading.dart';

Future<void> _editName(BuildContext context) async {
  final c = TextEditingController(text: LearnerPrefs.name.value);
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('이름')),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr('회화에서 불릴 이름'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
      ],
    ),
  );
  if (v != null) await LearnerPrefs.setName(v);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.rojoDeep, AppColors.rojo],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gualda, width: 1.5),
            ),
            child: Row(
              children: [
                const TileBadge(text: 'Ж', size: 60, color: AppColors.beniDeep),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('학습자'),
                        style: TextStyle(
                          color: AppColors.cal,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        tr('러시아어 · 입문'),
                        style: TextStyle(
                          color: AppColors.gualdaBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // 학습자 프로필(일본어앱 learner_prefs) — 이름 → 회화 속 「나」, 성별 → 학습자 목소리
          _SectionTitle(tr('학습자')),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: LearnerPrefs.name,
            builder: (context, name, _) => ValueListenableBuilder<String>(
              valueListenable: LearnerPrefs.gender,
              builder: (context, gender, _) => _SettingsGroup(items: [
                _SettingItem(
                    icon: Icons.badge_outlined,
                    title: tr('이름'),
                    subtitle: name.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [name]) : tr('없음 — 회화에서 「나」로 보여요'),
                    onTap: () => _editName(context)),
                _SettingItem(
                    icon: gender == 'female' ? Icons.face_3 : Icons.face,
                    title: tr('성별'),
                    subtitle: gender == 'female' ? tr('여성 — 탭하면 남성') : tr('남성 — 탭하면 여성'),
                    onTap: () => LearnerPrefs.setGender(gender == 'female' ? 'male' : 'female')),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(tr('설정')),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(valueListenable: KoReadingPrefs.show, builder: (context, _, _) => _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.language,
                title: tr('언어 / Language'),
                subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                onTap: AppLangPrefs.next),
            _SettingItem(
                icon: Icons.translate,
                title: tr('한글 독음'),
                subtitle: KoReadingPrefs.show.value ? tr('표시 — 탭하면 숨김') : tr('숨김 — 탭하면 표시'),
                onTap: () => KoReadingPrefs.toggle(context)),
          ])),
          const SizedBox(height: 16),
          _SectionTitle(tr('정보')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.landscape_outlined,
                title: tr('앱 소개'),
                subtitle: tr('절벽구간 — 이 앱이 단어를 나누는 기준'),
                onTap: () => openPane(context, (_) => const AboutScreen())),
            _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: '0.1.0 · alpha'),
            _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('러시아어유니버스 · 2026')),
          ]),
          const SizedBox(height: 20),
          const BandDivider(),
          const SizedBox(height: 12),
          const Center(child: SolMark(size: 28)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppColors.tinta,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    // 배경·테두리는 Material 이 그린다 — ListTile 의 눌림 효과가 배경 상자에 가려지지 않게(디버그 경고)
    return Material(
      color: AppColors.cal,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rojo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.rojo, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.rojo, size: 18),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
            ),
            if (i < items.length - 1)
              Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}
