
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/vehicle_model.dart';
import 'view_vehicle.dart';
import 'vehicle.dart';
import 'add_vehicle.dart';


class VehicleDashboard extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const VehicleDashboard({super.key, this.scaffoldKey});

  @override
  State<VehicleDashboard> createState() => _VehicleDashboardState();
}

class _VehicleDashboardState extends State<VehicleDashboard> {
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSuccess = Color(0xFF34C759);
  static const _kWarning = Color(0xFFFF9500);
  static const _kBackgroundGrey = Color(0xFFF8F9FA);

  Future<int> _count({String? status}) async {
    final col = FirebaseFirestore.instance.collection('vehicles');
    final query = (status == null) ? col : col.where('status', isEqualTo: status);
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Stream<List<VehicleModel>> _recentVehicles() {
    return FirebaseFirestore.instance
        .collection('vehicles')
        .orderBy('updatedAt', descending: true)
        .limit(5) // Reduced to 5 for better UX
        .snapshots()
        .map((s) => s.docs
        .map((d) => VehicleModel.fromMap(d.id, d.data()))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const base = 375.0;
    final s = (w / base).clamp(0.95, 1.15);

    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: _kBackgroundGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: EdgeInsets.all(16 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(s),
                      SizedBox(height: 24 * s),
                      _buildRecentVehiclesSection(s),
                      SizedBox(height: 16 * s),
                      _buildQuickActions(s),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
      ),
      title: const Text(
        'Vehicle Dashboard',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStatsSection(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vehicle Overview',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (20 * s).clamp(18, 22),
                color: Colors.black,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehiclesPage()),
                );
              },
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('View Details'),
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * s),
        FutureBuilder<List<int>>(
          future: Future.wait<int>([
            _count(),
            _count(status: 'active'),
            _count(status: 'inactive'),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Row(
                children: [
                  Expanded(child: _statCardSkeleton(s)),
                  SizedBox(width: 12 * s),
                  Expanded(child: _statCardSkeleton(s)),
                  SizedBox(width: 12 * s),
                  Expanded(child: _statCardSkeleton(s)),
                ],
              );
            }
            final all = snap.data![0];
            final active = snap.data![1];
            final inactive = snap.data![2];

            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    s: s,
                    title: 'Total',
                    value: all,
                    color: _kPrimary,
                    icon: Icons.directions_car_filled_rounded,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: _statCard(
                    s: s,
                    title: 'Active',
                    value: active,
                    color: _kSuccess,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: _statCard(
                    s: s,
                    title: 'Inactive',
                    value: inactive,
                    color: _kWarning,
                    icon: Icons.archive_rounded,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentVehiclesSection(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Vehicles',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: (20 * s).clamp(18, 22),
                color: Colors.black,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehiclesPage()),
                );
              },
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 12 * s),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0x0F000000),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: StreamBuilder<List<VehicleModel>>(
            stream: _recentVehicles(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(20 * s),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(_kPrimary),
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: EdgeInsets.all(20 * s),
                  child: _errorTile('Failed to load recent vehicles.', s),
                );
              }
              final items = snap.data ?? const <VehicleModel>[];
              if (items.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(32 * s),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        color: _kGrey.withValues(alpha: 0.5),
                        size: 48 * s,
                      ),
                      SizedBox(height: 12 * s),
                      Text(
                        'No vehicles yet',
                        style: TextStyle(
                          color: _kGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16 * s,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        'Add your first vehicle to get started',
                        style: TextStyle(
                          color: _kGrey.withValues(alpha: 0.7),
                          fontSize: 14 * s,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: _kLightGrey.withValues(alpha: 0.5),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (_, i) {
                  final v = items[i];
                  final isLast = i == items.length - 1;
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewVehicle(vehicleId: v.id),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(16) : Radius.zero,
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * s,
                        vertical: 12 * s,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8 * s),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: _kPrimary,
                              size: 20 * s,
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v.year} ${v.make} ${v.model}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15 * s,
                                  ),
                                ),
                                SizedBox(height: 2 * s),
                                Text(
                                  v.carPlate.isEmpty ? 'No plate number' : v.carPlate,
                                  style: TextStyle(
                                    color: _kGrey,
                                    fontSize: 13 * s,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusChip(v.status),
                          SizedBox(width: 8 * s),
                          Icon(
                            Icons.chevron_right,
                            color: _kGrey.withValues(alpha: 0.5),
                            size: 20 * s,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: (20 * s).clamp(18, 22),
            color: Colors.black,
          ),
        ),
        SizedBox(height: 12 * s),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                s: s,
                title: 'Add Vehicle',
                subtitle: 'Register new vehicle',
                icon: Icons.add_circle_outline,
                color: _kSuccess,
                onTap: () async {
                  final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddVehicle()),
                  );
                  if (result != null) {
                  // Refresh the dashboard data
                  setState(() {});
                  }
                },
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: _quickActionCard(
                s: s,
                title: 'View All',
                subtitle: 'See complete list',
                icon: Icons.list_alt_rounded,
                color: _kPrimary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VehiclesPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required double s,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24 * s),
            SizedBox(height: 8 * s),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14 * s,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 2 * s),
            Text(
              subtitle,
              style: TextStyle(
                color: _kGrey,
                fontSize: 12 * s,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== UI helpers =====

  Widget _statCard({
    required double s,
    required String title,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20 * s),
          ),
          SizedBox(height: 12 * s),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: (24 * s).clamp(20, 26),
              color: Colors.black,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            title,
            style: TextStyle(
              color: _kGrey,
              fontWeight: FontWeight.w600,
              fontSize: (12 * s).clamp(11, 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCardSkeleton(double s) {
    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBar(width: 32 * s, height: 32 * s, borderRadius: 8),
          SizedBox(height: 12 * s),
          _shimmerBar(width: 50 * s, height: 20 * s),
          SizedBox(height: 8 * s),
          _shimmerBar(width: 40 * s, height: 12 * s),
        ],
      ),
    );
  }

  Widget _shimmerBar({
    required double width,
    required double height,
    double borderRadius = 4
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kLightGrey.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _errorTile(String msg, double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 20 * s),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(
              color: Colors.red,
              fontSize: 14 * s,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color color;
    String label;

    if (s == 'inactive') {
      color = _kWarning;
      label = 'Inactive';
    } else {
      color = _kSuccess;
      label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}