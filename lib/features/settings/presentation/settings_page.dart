import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/app_layout.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/theme/portal_theme_mode.dart';
import 'package:guardian_portal/core/theme/theme_scope.dart';
import 'package:guardian_portal/core/widgets/device_online_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/live_status_tile.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/core/widgets/status_badge.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/empty_devices_card.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/settings/presentation/widgets/protected_layers_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Stream<GuardianDevice?>? _deviceStream;
  final _refreshController = OnlineRefreshController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    _deviceStream ??= DashboardService().watchPrimaryDevice(uid);

    return StreamBuilder<GuardianDevice?>(
      stream: _deviceStream,
      builder: (context, snapshot) {
        final device = snapshot.data;
        final initialLoad =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

        return OnlineRefresh(
          controller: _refreshController,
          builder: (context, isRefreshing) {
            return GuardianScaffold(
              title: 'Configurações',
              subtitle: 'Sincronizadas com o app — o celular é soberano',
              subtitleTrailing: device != null
                  ? DeviceOnlineChip(
                      isOnline: device.status.isOnline,
                      lastSeen: device.status.lastSeen,
                    )
                  : null,
              onRefresh: _refreshController.refresh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isRefreshing && snapshot.hasData)
                    const RefreshTickBar(visible: true),
                  if (initialLoad)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    const _AppearanceCard(),
                    const SizedBox(height: 16),
                    if (device == null)
                      const EmptyDevicesCard()
                    else
                      _SettingsBody(uid: uid, status: device.status),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.uid, required this.status});

  final String uid;
  final DeviceStatus status;

  ProtectionSetupItem? _item(String id) {
    for (final item in status.protectionSetupItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasChecklist = status.hasSetupChecklist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DeviceInfoCard(status: status),
        const SizedBox(height: 16),
        ProtectedLayersCard(uid: uid, status: status),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Detecção',
          children: const [
            _PlannedSettingRow(
              icon: Icons.tune_outlined,
              title: 'Sensibilidade',
              subtitle: 'Em breve — ajuste remoto via comandos',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Recuperação',
          children: [
            _SyncedSettingRow(
              icon: Icons.pin_outlined,
              title: 'PIN / biometria do aparelho',
              item: _item('recovery'),
              hasChecklist: hasChecklist,
            ),
             _PlannedSettingRow(
              icon: Icons.contacts_outlined,
              title: 'Contatos confiáveis',
              subtitle: 'Em breve — backup na nuvem',
            ),
          ],
        ),
         SizedBox(height: 16),
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasChecklist
                      ? 'Índice e checklist de permissões estão no Centro. '
                          'Camadas e demais opções são ajustadas no celular; '
                          'o portal apenas exibe o que foi sincronizado.'
                      : 'Abra o Guardian Sense no celular com esta conta para '
                          'sincronizar. O resumo de proteção aparece no Centro.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.status});

  final DeviceStatus status;

  String get _platformLabel {
    final raw = status.platform.trim().toLowerCase();
    return switch (raw) {
      'android' => 'Android',
      'ios' => 'iOS',
      _ when raw.isEmpty => '—',
      _ => status.platform,
    };
  }

  @override
  Widget build(BuildContext context) {
    final checklist = ProtectionSnapshot.checklist(status);
    final runtime = checklist.firstWhere(
      (e) => e.question.startsWith('O Runtime'),
    );
    final oyster = checklist.firstWhere(
      (e) => e.question.startsWith('A Ostra'),
    );
    final wide =
        AppLayout.mainAreaWidth(MediaQuery.sizeOf(context).width) >= 520;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                status.platform.toLowerCase() == 'ios'
                    ? Icons.phone_iphone_outlined
                    : Icons.smartphone_outlined,
                color: AppColors.primary.withValues(alpha: 0.9),
                size: 28,
              ),
               SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APARELHO VINCULADO',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.modelLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_platformLabel · v${status.appVersion} · '
                      'sync ${formatRelativeTime(status.lastSeen)}',
                      style: DashboardTypography.cardSubtitle(context),
                    ),
                  ],
                ),
              ),
              if (status.hasSetupChecklist) ...[
                const SizedBox(width: 12),
                StatusBadge(
                  label: '${status.protectionIndex}%',
                  tone: status.protectionIndex >= 90
                      ? StatusTone.protected
                      : status.protectionIndex >= 50
                          ? StatusTone.warning
                          : StatusTone.critical,
                ),
              ],
            ],
          ),
           SizedBox(height: 18),
           Divider(height: 1, color: AppColors.divider),
           SizedBox(height: 14),
          Text(
            'ESTADO EM TEMPO REAL',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 10),
          if (wide)
            Row(
              children: [
                Expanded(
                  child: LiveStatusTile(
                    icon: Icons.memory_rounded,
                    label: 'Runtime',
                    value: runtime.answer,
                    accent: _signalColor(runtime.signal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LiveStatusTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Ostra',
                    value: oyster.answer,
                    accent: _signalColor(oyster.signal),
                  ),
                ),
              ],
            )
          else ...[
            LiveStatusTile(
              icon: Icons.memory_rounded,
              label: 'Runtime',
              value: runtime.answer,
              accent: _signalColor(runtime.signal),
            ),
            const SizedBox(height: 10),
            LiveStatusTile(
              icon: Icons.lock_outline_rounded,
              label: 'Ostra',
              value: oyster.answer,
              accent: _signalColor(oyster.signal),
            ),
          ],
        ],
      ),
    );
  }

  static Color _signalColor(ChecklistSignal signal) => switch (signal) {
        ChecklistSignal.ok => AppColors.trustHigh,
        ChecklistSignal.warn => AppColors.trustMedium,
        ChecklistSignal.alert => AppColors.riskCritical,
        ChecklistSignal.muted => AppColors.textMuted,
      };
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:  EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
          ),
        ),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncedSettingRow extends StatelessWidget {
  const _SyncedSettingRow({
    required this.icon,
    required this.title,
    required this.item,
    required this.hasChecklist,
  });

  final IconData icon;
  final String title;
  final ProtectionSetupItem? item;
  final bool hasChecklist;

  @override
  Widget build(BuildContext context) {
    final (subtitle, trailing) = switch ((hasChecklist, item?.done)) {
      (false, _) => (
          'Aguardando sync do app',
           Icon(Icons.hourglass_empty, color: AppColors.textMuted, size: 20),
        ),
      (true, true) => (
          'Configurado no app',
           Icon(Icons.check_circle_rounded, color: AppColors.trustHigh, size: 22),
        ),
      (true, false) => (
          item?.label ?? 'Falta no aparelho',
           Icon(Icons.error_outline_rounded, color: AppColors.trustMedium, size: 22),
        ),
      (true, null) => (
          'Aguardando sync do app',
           Icon(Icons.hourglass_empty, color: AppColors.textMuted, size: 20),
        ),
    };

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.textMuted),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasChecklist && item?.done == false
                    ? 'Ajuste "$title" no app Guardian Sense no celular.'
                    : 'Esta opção é configurada no app no celular.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _PlannedSettingRow extends StatelessWidget {
  const _PlannedSettingRow({
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
        trailing: Icon(Icons.schedule_outlined, color: AppColors.textMuted),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recurso planejado — ainda não disponível no portal.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'APARÊNCIA',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tema do portal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'A preferência fica salva neste navegador.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                theme.mode == PortalThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema escuro',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      theme.mode == PortalThemeMode.dark
                          ? 'Fundo escuro'
                          : 'Fundo claro — melhor ao sol',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              _PillSwitch(
                value: theme.mode == PortalThemeMode.dark,
                onChanged: (dark) {
                  theme.setMode(
                    dark ? PortalThemeMode.dark : PortalThemeMode.light,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Switch com track em pill — visual alinhado aos FilterChips de Eventos.
class _PillSwitch extends StatelessWidget {
  const _PillSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _width = 52.0;
  static const _height = 30.0;
  static const _thumb = 22.0;
  static const _pad = 4.0;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.trustHigh;
    final light = Theme.of(context).brightness == Brightness.light;

    final trackColor = value
        ? accent.withValues(alpha: light ? 0.18 : 0.14)
        : light
            ? const Color(0xFFCBD5E1)
            : AppColors.card;
    final borderColor = value
        ? accent.withValues(alpha: light ? 0.55 : 0.45)
        : light
            ? AppColors.textMuted.withValues(alpha: 0.55)
            : AppColors.divider;
    final thumbColor = value
        ? accent
        : light
            ? Colors.white
            : AppColors.surface;
    final thumbBorder = value
        ? accent.withValues(alpha: 0.55)
        : light
            ? AppColors.textMuted.withValues(alpha: 0.4)
            : AppColors.divider;

    return Semantics(
      button: true,
      toggled: value,
      label: 'Tema escuro',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(_pad),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: borderColor),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumb,
              height: _thumb,
              decoration: BoxDecoration(
                color: thumbColor,
                shape: BoxShape.circle,
                border: Border.all(color: thumbBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: light ? (value ? 0.16 : 0.14) : (value ? 0.18 : 0.08),
                    ),
                    blurRadius: light ? 5 : 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
