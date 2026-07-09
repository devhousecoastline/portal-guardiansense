import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/theme/app_colors.dart';
import 'package:guardian_portal/core/widgets/device_online_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/core/widgets/relative_time.dart';
import 'package:guardian_portal/core/widgets/section_card.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/empty_devices_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_setup_card.dart';
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
                  else if (device == null)
                    const EmptyDevicesCard()
                  else
                    _SettingsBody(status: device.status),
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
  const _SettingsBody({required this.status});

  final DeviceStatus status;

  ProtectionSetupItem? _item(String id) {
    for (final item in status.protectionSetupItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pending = status.pendingSetupItems;
    final hasChecklist = status.hasSetupChecklist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasChecklist && pending.isNotEmpty && status.isOnline) ...[
          _PendingAlertBanner(count: pending.length),
          const SizedBox(height: 16),
        ],
        ProtectionSetupCard(status: status),
        const SizedBox(height: 16),
        _DeviceInfoCard(status: status),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Proteção',
          children: [
            _SyncedSettingRow(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              item: _item('notifications'),
              hasChecklist: hasChecklist,
            ),
            _SyncedSettingRow(
              icon: Icons.apps_outlined,
              title: 'Apps protegidos',
              item: _item('accessibility'),
              hasChecklist: hasChecklist,
            ),
            _SyncedSettingRow(
              icon: Icons.battery_charging_full_outlined,
              title: 'Bateria sem otimização',
              item: _item('battery'),
              hasChecklist: hasChecklist,
            ),
            const _PlannedSettingRow(
              icon: Icons.tune_outlined,
              title: 'Sensibilidade',
              subtitle: 'Em breve — ajuste remoto via comandos',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProtectedLayersCard(
          status: status,
          layersItem: _item('protected_layers'),
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
            const _PlannedSettingRow(
              icon: Icons.contacts_outlined,
              title: 'Contatos confiáveis',
              subtitle: 'Em breve — backup na nuvem',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _RuntimeCard(status: status),
        const SizedBox(height: 16),
        SectionCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasChecklist
                      ? 'Estado refletido em tempo real quando o app sincroniza. '
                          'Permissões e camadas são ajustadas no celular; '
                          'o portal apenas exibe o que foi enviado.'
                      : 'Abra o Guardian Sense no celular com esta conta para '
                          'sincronizar as configurações. Alterações remotas '
                          'via comandos chegarão em fases futuras.',
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

class _PendingAlertBanner extends StatelessWidget {
  const _PendingAlertBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.trustMedium.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.trustMedium.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.trustMedium,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 1
                  ? '1 opção ainda falta no aparelho. Ajuste no app e volte '
                      '— o portal atualiza em segundos.'
                  : '$count opções ainda faltam no aparelho. Ajuste no app e '
                      'volte — o portal atualiza em segundos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.trustMedium,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  const _DeviceInfoCard({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aparelho vinculado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _InfoLine(label: 'Modelo', value: status.modelLabel),
          _InfoLine(label: 'Plataforma', value: status.platform),
          _InfoLine(label: 'Versão do app', value: status.appVersion),
          _InfoLine(
            label: 'Última sincronização',
            value: formatRelativeTime(status.lastSeen),
          ),
          if (status.hasSetupChecklist) ...[
            const SizedBox(height: 4),
            _InfoLine(
              label: 'Índice de proteção',
              value: '${status.protectionIndex}%',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  const _RuntimeCard({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado em tempo real',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _InfoLine(
            label: 'Runtime',
            value: ProtectionSnapshot.checklist(status)
                .firstWhere((e) => e.question.startsWith('O Runtime'))
                .answer,
          ),
          _InfoLine(
            label: 'Ostra',
            value: ProtectionSnapshot.checklist(status)
                .firstWhere((e) => e.question.startsWith('A Ostra'))
                .answer,
          ),
        ],
      ),
    );
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
          const Icon(Icons.hourglass_empty, color: AppColors.textMuted, size: 20),
        ),
      (true, true) => (
          'Configurado no app',
          const Icon(Icons.check_circle_rounded, color: AppColors.trustHigh, size: 22),
        ),
      (true, false) => (
          item?.label ?? 'Falta no aparelho',
          const Icon(Icons.error_outline_rounded, color: AppColors.trustMedium, size: 22),
        ),
      (true, null) => (
          'Aguardando sync do app',
          const Icon(Icons.hourglass_empty, color: AppColors.textMuted, size: 20),
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
        trailing: const Icon(Icons.schedule_outlined, color: AppColors.textMuted),
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
