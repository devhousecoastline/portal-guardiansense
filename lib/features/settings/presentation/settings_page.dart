import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/theme/dashboard_typography.dart';
import 'package:guardian_portal/core/theme/portal_theme_mode.dart';
import 'package:guardian_portal/core/theme/theme_scope.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DeviceInfoCard(
          status: status,
          recovery: _item('recovery'),
        ),
        const SizedBox(height: 16),
        ProtectedLayersCard(uid: uid, status: status),
        const SizedBox(height: 16),
        const _DetectionSensitivityCard(),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Recuperação',
          children: const [
            _PlannedSettingRow(
              icon: Icons.contacts_outlined,
              title: 'Contatos confiáveis',
              subtitle: 'Em breve — backup na nuvem',
            ),
          ],
        ),
      ],
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({
    required this.status,
    required this.recovery,
  });

  final DeviceStatus status;
  final ProtectionSetupItem? recovery;

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

    final phoneIcon = status.platform.toLowerCase() == 'ios'
        ? Icons.phone_iphone_outlined
        : Icons.smartphone_outlined;
    final deviceValue = status.hasSetupChecklist
        ? '${status.protectionIndex}% · índice'
        : '$_platformLabel · v${status.appVersion}';
    final deviceAccent = status.hasSetupChecklist
        ? _indexColor(status.protectionIndex)
        : AppColors.primary;

    final (recoveryValue, recoveryAccent) = switch ((
      status.hasSetupChecklist,
      recovery?.done,
    )) {
      (false, _) || (true, null) => (
          'Aguardando sync',
          AppColors.textMuted,
        ),
      (true, true) => (
          'Configurado no app',
          AppColors.trustHigh,
        ),
      (true, false) => (
          recovery?.label ?? 'Falta no aparelho',
          AppColors.trustMedium,
        ),
    };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.smartphone_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aparelho vinculado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              LiveStatusTile(
                icon: phoneIcon,
                label: status.modelLabel,
                value: deviceValue,
                accent: deviceAccent,
              ),
              LiveStatusTile(
                icon: status.isOnline
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                label: status.isOnline ? 'Online' : 'Offline',
                value: formatRelativeTime(status.lastSeen),
                accent: status.isOnline
                    ? AppColors.trustHigh
                    : AppColors.textMuted,
              ),
              LiveStatusTile(
                icon: Icons.memory_rounded,
                label: 'Runtime',
                value: runtime.answer,
                accent: _signalColor(runtime.signal),
              ),
              LiveStatusTile(
                icon: Icons.lock_outline_rounded,
                label: 'Ostra',
                value: oyster.answer,
                accent: _signalColor(oyster.signal),
              ),
              LiveStatusTile(
                icon: Icons.pin_outlined,
                label: 'PIN / biometria',
                value: recoveryValue,
                accent: recoveryAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$_platformLabel · v${status.appVersion}',
            style: DashboardTypography.cardSubtitle(context),
          ),
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

  static Color _indexColor(int index) {
    if (index >= 90) return AppColors.trustHigh;
    if (index >= 50) return AppColors.trustMedium;
    return AppColors.riskCritical;
  }
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

class _DetectionSensitivityCard extends StatefulWidget {
  const _DetectionSensitivityCard();

  @override
  State<_DetectionSensitivityCard> createState() =>
      _DetectionSensitivityCardState();
}

enum _SensitivityLevel {
  conservative,
  balanced,
  aggressive;

  String get label => switch (this) {
        _SensitivityLevel.conservative => 'Conservadora',
        _SensitivityLevel.balanced => 'Equilibrada',
        _SensitivityLevel.aggressive => 'Alta',
      };

  String get description => switch (this) {
        _SensitivityLevel.conservative =>
          'Exige sinais mais fortes antes de elevar o risco.',
        _SensitivityLevel.balanced =>
          'Calibração padrão da sensibilidade validada em dispositivo real.',
        _SensitivityLevel.aggressive =>
          'Detecta mais cedo; pode aumentar alertas em movimento leve.',
      };
}

class _DetectionSensitivityCardState extends State<_DetectionSensitivityCard> {
  _SensitivityLevel _level = _SensitivityLevel.balanced;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detecção',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 480;
              final description = Text(
                _level.description,
                style: Theme.of(context).textTheme.bodyMedium,
              );
              final slider = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.trustHigh,
                      inactiveTrackColor: AppColors.divider,
                      thumbColor: AppColors.trustHigh,
                      overlayColor:
                          AppColors.trustHigh.withValues(alpha: 0.14),
                      trackHeight: 4,
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                    ),
                    child: Slider(
                      value: _level.index.toDouble(),
                      min: 0,
                      max: (_SensitivityLevel.values.length - 1).toDouble(),
                      divisions: _SensitivityLevel.values.length - 1,
                      label: _level.label,
                      onChanged: (value) {
                        setState(() {
                          _level = _SensitivityLevel.values[value.round()];
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final level in _SensitivityLevel.values)
                          Text(
                            level.label,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: level == _level
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: level == _level
                                          ? AppColors.trustHigh
                                          : AppColors.textMuted,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    description,
                    const SizedBox(height: 8),
                    slider,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: description),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: slider),
                ],
              );
            },
          ),
        ],
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
        trailing: const StatusBadge(
          label: 'Em breve',
          tone: StatusTone.neutral,
        ),
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
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tema do portal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
