import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GuardianScaffold(
      title: 'Configurações',
      subtitle: 'Sincronizadas com o app — o celular é soberano',
      child: Column(
        children: [
          _SettingsGroup(
            title: 'Proteção',
            items: const [
              _SettingItem(
                icon: Icons.layers_outlined,
                title: 'Camadas',
                subtitle: 'Em breve — backup na nuvem',
              ),
              _SettingItem(
                icon: Icons.apps_outlined,
                title: 'Apps protegidos',
                subtitle: 'Em breve — backup na nuvem',
              ),
              _SettingItem(
                icon: Icons.tune_outlined,
                title: 'Sensibilidade',
                subtitle: 'Em breve — backup na nuvem',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Recuperação',
            items: const [
              _SettingItem(
                icon: Icons.contacts_outlined,
                title: 'Contatos confiáveis',
                subtitle: 'Em breve',
              ),
              _SettingItem(
                icon: Icons.pin_outlined,
                title: 'PIN de emergência',
                subtitle: 'Em breve',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Alterações feitas aqui serão enviadas como comandos ao app. '
                    'O celular aplica quando houver internet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});

  final String title;
  final List<_SettingItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.textMuted),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () {},
      ),
    );
  }
}
