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
                      EmptyDevicesCard(uid: uid)
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
        : '$_platformLabel · Guardian Sense App v${status.appVersionLabel}';
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
          const SizedBox(height: 6),
          Text(
            '$_platformLabel · Guardian Sense App v${status.appVersionLabel}',
            style: DashboardTypography.cardSubtitle(context),
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
