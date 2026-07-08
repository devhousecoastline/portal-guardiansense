import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guardian_portal/core/layout/dashboard_layout.dart';
import 'package:guardian_portal/core/widgets/device_online_chip.dart';
import 'package:guardian_portal/core/widgets/guardian_scaffold.dart';
import 'package:guardian_portal/core/widgets/online_refresh.dart';
import 'package:guardian_portal/features/containment/presentation/widgets/remote_containment_card.dart';
import 'package:guardian_portal/features/dashboard/application/dashboard_service.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/empty_devices_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_checklist_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_setup_card.dart';
import 'package:guardian_portal/features/dashboard/presentation/widgets/protection_status_hero.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Stream<GuardianDevice?>? _deviceStream;
  final _refreshController = OnlineRefreshController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    _deviceStream ??= DashboardService().watchPrimaryDevice(uid);

    final viewport = MediaQuery.sizeOf(context);
    final layout = DashboardLayoutSpec.resolve(
      viewportWidth: viewport.width,
      viewportHeight: viewport.height,
    );

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
              title: 'Centro',
              subtitle: 'Status do seu dispositivo',
              subtitleTrailing: device != null
                  ? DeviceOnlineChip(
                      isOnline: device.status.isOnline,
                      lastSeen: device.status.lastSeen,
                    )
                  : null,
              onRefresh: _refreshController.refresh,
              fitViewport: layout.isNotebook,
              child: layout.isNotebook
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: initialLoad
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : device == null
                                  ? const EmptyDevicesCard()
                                  : _DashboardBody(
                                      uid: uid,
                                      device: device,
                                      layout: layout,
                                      showRefreshTick:
                                          isRefreshing && snapshot.hasData,
                                    ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (initialLoad)
                          const Center(child: CircularProgressIndicator())
                        else if (device == null)
                          const EmptyDevicesCard()
                        else
                          _DashboardBody(
                            uid: uid,
                            device: device,
                            layout: layout,
                            showRefreshTick: isRefreshing && snapshot.hasData,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.uid,
    required this.device,
    required this.layout,
    this.showRefreshTick = false,
  });

  final String uid;
  final GuardianDevice device;
  final DashboardLayoutSpec layout;
  final bool showRefreshTick;

  DeviceStatus get status => device.status;

  @override
  Widget build(BuildContext context) {
    final tone = ProtectionSnapshot.tone(status);

    final hero = ProtectionStatusHero(
      status: status,
      tone: tone,
      stretchVertically: layout.stretchTopRow,
      fillHeight: layout.isNotebook,
      compact: layout.compact,
    );
    final setup = ProtectionSetupCard(
      status: status,
      stretchVertically: layout.stretchTopRow,
      fillHeight: layout.isNotebook,
      compact: layout.compact,
    );
    final checklist = ProtectionChecklistCard(
      status: status,
      compact: layout.compact,
      twoColumns: layout.checklistTwoColumns,
      pairGrid: layout.checklistPairGrid,
      expandVertically: layout.isNotebook,
    );
    final containment = RemoteContainmentCard(
      uid: uid,
      deviceId: device.id,
      status: status,
      compact: layout.compact,
      expandVertically: layout.isNotebook,
    );

    if (layout.isNotebook) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight;
          final cellHeight = DashboardLayoutSpec.notebookCellHeightFromAvailable(
            available,
            sectionGap: layout.sectionGap,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: cellHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: layout.topRowHeroFlex, child: hero),
                    SizedBox(width: layout.columnGap),
                    Expanded(flex: layout.topRowSetupFlex, child: setup),
                  ],
                ),
              ),
              SizedBox(height: layout.sectionGap),
              SizedBox(
                height: cellHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: layout.bottomRowContainmentFlex,
                      child: containment,
                    ),
                    SizedBox(width: layout.columnGap),
                    Expanded(
                      flex: layout.bottomRowChecklistFlex,
                      child: checklist,
                    ),
                  ],
                ),
              ),
              SizedBox(height: layout.compact ? 16 : 20),
              _DashboardFooter(
                status: status,
                layout: layout,
                showRefreshTick: showRefreshTick,
              ),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!layout.isMobile) ...[
          if (layout.stretchTopRow)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: layout.topRowHeroFlex, child: hero),
                  SizedBox(width: layout.columnGap),
                  Expanded(flex: layout.topRowSetupFlex, child: setup),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: layout.topRowHeroFlex, child: hero),
                SizedBox(width: layout.columnGap),
                Expanded(flex: layout.topRowSetupFlex, child: setup),
              ],
            ),
          SizedBox(height: layout.sectionGap),
          if (layout.useBottomRowSplit)
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: layout.bottomRowContainmentFlex,
                  child: containment,
                ),
                SizedBox(width: layout.columnGap),
                Expanded(
                  flex: layout.bottomRowChecklistFlex,
                  child: checklist,
                ),
              ],
            )
          else ...[
            containment,
            SizedBox(height: layout.sectionGap),
            checklist,
          ],
        ]
        else ...[
          hero,
          SizedBox(height: layout.sectionGap),
          setup,
          SizedBox(height: layout.sectionGap),
          containment,
          SizedBox(height: layout.sectionGap),
          checklist,
        ],
        SizedBox(height: layout.compact ? 16 : 20),
        _DashboardFooter(
          status: status,
          layout: layout,
          showRefreshTick: showRefreshTick,
        ),
      ],
    );
  }
}

class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter({
    required this.status,
    required this.layout,
    required this.showRefreshTick,
  });

  final DeviceStatus status;
  final DashboardLayoutSpec layout;
  final bool showRefreshTick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ProtectionSnapshot.dashboardFooter(status),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: layout.footerFontSize,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.92),
              ),
        ),
        RefreshTickBar(
          visible: showRefreshTick,
          placement: RefreshTickBarPlacement.bottom,
          reserveSpace: true,
          alwaysVisible: true,
        ),
      ],
    );
  }
}
