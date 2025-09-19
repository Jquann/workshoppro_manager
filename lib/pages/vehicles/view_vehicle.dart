import 'package:flutter/material.dart';
import 'package:workshoppro_manager/firestore_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/service_model.dart';
import 'edit_vehicle.dart';
import 'view_service.dart';
import 'add_service.dart';

import 'package:intl/intl.dart';
final _currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM', decimalDigits: 2);

const String kRestorePassword = 'admin123'; // TODO: change this

// --- Service status filter state (kept global as you wrote) ---
String _statusFilter = 'all';
final List<String> _statusTabs = const [
  'all',
  ServiceRecordModel.statusInProgress,  // 'in progress'
  ServiceRecordModel.statusCompleted,   // 'completed'
  ServiceRecordModel.statusCancel,      // 'cancelled'
];

class ViewVehicle extends StatefulWidget {
  final String vehicleId;
  const ViewVehicle({super.key, required this.vehicleId});

  @override
  State<ViewVehicle> createState() => _ViewVehicleState();
}

class _ViewVehicleState extends State<ViewVehicle> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Enhanced color scheme
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSecondary = Color(0xFF5856D6);
  static const _kSuccess = Color(0xFF34C759);
  static const _kDanger = Color(0xFFFF3B30);
  static const _kWarning = Color(0xFFFF9500);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kCardShadow = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return FutureBuilder<VehicleModel?>(
      future: db.getVehicle(widget.vehicleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: _kLightGrey,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading vehicle details...',
                    style: TextStyle(
                      color: _kGrey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final v = snap.data;
        if (v == null) {
          return Scaffold(
            backgroundColor: _kLightGrey,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: _kGrey),
                  const SizedBox(height: 16),
                  Text(
                    'Vehicle not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kGrey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final w = MediaQuery.of(context).size.width;
        const base = 375.0;
        final s = (w / base).clamp(0.95, 1.12);
        final isInactive = (v.status == 'inactive');

        return Scaffold(
          backgroundColor: _kLightGrey,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Enhanced App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: _kCardShadow,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _kCardShadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _kCardShadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.black, size: 20),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditVehicle(vehicle: v),
                            ),
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Vehicle Details',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: (20 * s).clamp(18, 22),
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              _kLightGrey.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16 * s),
                      child: Column(
                        children: [
                          // Vehicle Information Card
                          _buildVehicleInfoCard(v, s),
                          SizedBox(height: 24 * s),

                          // Service History Section
                          _buildServiceHistorySection(v, db, s, isInactive),
                          SizedBox(height: 100), // Space for floating button
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Enhanced Floating Action Button
          floatingActionButton: _buildActionButton(v, db, isInactive, s),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color color, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: (11 * s).clamp(10, 12),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(VehicleModel v, double s) {
    final isInactive = (v.status == 'inactive');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner at the top
          if (isInactive)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 12 * s),
              decoration: BoxDecoration(
                color: _kDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: _kDanger.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: _kDanger,
                    size: 16 * s,
                  ),
                  SizedBox(width: 8 * s),
                  Text(
                    'This vehicle is currently inactive',
                    style: TextStyle(
                      color: _kDanger,
                      fontSize: (10 * s).clamp(12, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  _buildStatusBadge('Inactive', _kDanger, s),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 24 * s, 24 * s, 16 * s),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * s),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: _kPrimary,
                    size: 24 * s,
                  ),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Vehicle Information',
                              style: TextStyle(
                                fontSize: (22 * s).clamp(20, 24),
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // Status badge only for active vehicles (inactive shown in banner above)
                          if (!isInactive)
                            _buildStatusBadge('Active', _kSuccess, s),
                        ],
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        'Complete vehicle details',
                        style: TextStyle(
                          fontSize: (14 * s).clamp(13, 15),
                          color: _kGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * s),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kDivider.withValues(alpha: 0),
                    _kDivider,
                    _kDivider.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
            child: Column(
              children: [
                _enhancedInfoRow('Customer', v.customerName, Icons.person_rounded, s),
                _enhancedInfoRow('Make', v.make, Icons.business_rounded, s),
                _enhancedInfoRow('Model', v.model, Icons.car_rental_rounded, s),
                _enhancedInfoRow('Year', '${v.year}', Icons.calendar_today_rounded, s),
                _enhancedInfoRow('Car Plate Number', v.carPlate, Icons.confirmation_number_rounded, s, isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedInfoRow(String label, String value, IconData icon, double s, {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16 * s),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * s),
            decoration: BoxDecoration(
              color: _kLightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20 * s,
              color: _kGrey,
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _kGrey,
                    fontSize: (14 * s).clamp(13, 15),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2 * s),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: (16 * s).clamp(15, 17),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Status filter helpers =====
  String _normalizeStatus(String raw) {
    final s = (raw.isEmpty ? '' : raw).trim().toLowerCase();
    if (s.contains('cancel')) return ServiceRecordModel.statusCancel;
    if (s.contains('complete')) return ServiceRecordModel.statusCompleted;
    return ServiceRecordModel.statusInProgress; // default bucket: scheduled
  }

  List<ServiceRecordModel> _filterByStatus(List<ServiceRecordModel> list) {
    if (_statusFilter == 'all') return list;
    return list.where((r) => _normalizeStatus(r.status) == _statusFilter).toList();
  }

  String _statusLabel(String key) {
    switch (key) {
      case 'all': return 'All';
      case ServiceRecordModel.statusInProgress: return 'In progress';
      case ServiceRecordModel.statusCompleted: return 'Completed';
      case ServiceRecordModel.statusCancel: return 'Cancelled';
      default: return key;
    }
  }

  Widget _buildStatusFilterBar(double s) {
    return Wrap(
      spacing: 8 * s,
      runSpacing: 8 * s,
      children: _statusTabs.map((tab) {
        final selected = (_statusFilter == tab);
        return ChoiceChip(
          label: Text(
            _statusLabel(tab),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: (12 * s).clamp(11, 13),
              color: selected ? Colors.white : _kGrey,
            ),
          ),
          selected: selected,
          onSelected: (_) => setState(() => _statusFilter = tab),
          backgroundColor: _kLightGrey,
          selectedColor: _kPrimary,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? _kPrimary : _kDivider),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        );
      }).toList(),
    );
  }

  Widget _buildServiceHistorySection(VehicleModel v, FirestoreService db, double s, bool isInactive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kCardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 24 * s, 24 * s, 16 * s),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12 * s),
                  decoration: BoxDecoration(
                    color: _kSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.build_rounded,
                    color: _kSecondary,
                    size: 24 * s,
                  ),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service History',
                        style: TextStyle(
                          fontSize: (22 * s).clamp(20, 24),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        'Showing ${_statusLabel(_statusFilter)}',
                        style: TextStyle(
                          fontSize: (14 * s).clamp(13, 15),
                          color: _kGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isInactive)
                  Container(
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddService(vehicleId: v.id),
                        ),
                      ),
                      icon: Icon(Icons.add_rounded, color: _kPrimary, size: 20 * s),
                      label: Text(
                        'Add',
                        style: TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: (14 * s).clamp(13, 15),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * s),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _kDivider.withValues(alpha: 0),
                    _kDivider,
                    _kDivider.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Status filter bar
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 0),
            child: _buildStatusFilterBar(s),
          ),
          // Stream list
          StreamBuilder<List<ServiceRecordModel>>(
            stream: db.serviceStream(v.id),
            builder: (context, sSnap) {
              // 1) show query/mapping errors instead of spinning forever
              if (sSnap.hasError) {
                return Padding(
                  padding: EdgeInsets.all(24 * s),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: _kDanger, size: 28 * s),
                      SizedBox(height: 8 * s),
                      Text(
                        'Failed to load services.\n${sSnap.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _kGrey),
                      ),
                    ],
                  ),
                );
              }

              // 2) show initial/progress state
              if (sSnap.connectionState == ConnectionState.waiting && !sSnap.hasData) {
                return Padding(
                  padding: EdgeInsets.all(24 * s),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              final items = sSnap.data ?? const <ServiceRecordModel>[];
              final filtered = _filterByStatus(items);

              if (filtered.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(24 * s),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 48 * s, color: _kGrey.withValues(alpha: 0.5)),
                        SizedBox(height: 12 * s),
                        Text(
                          'No ${_statusLabel(_statusFilter).toLowerCase()} records',
                          style: TextStyle(color: _kGrey, fontSize: 16 * s, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4 * s),
                        Text('Try a different status',
                            style: TextStyle(color: _kGrey.withValues(alpha: 0.7), fontSize: 14 * s)),
                      ],
                    ),
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
                child: Column(
                  children: filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final r = entry.value;
                    final isLastItem = index == filtered.length - 1;
                    return _buildServiceRecordCard(r, v.id, s, isLastItem);
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- STATUS VISUAL HELPERS ----------------
  ({IconData icon, Color color, Color bg, String label}) _statusLook(String raw) {
    final s = (raw.isEmpty ? '' : raw).trim().toLowerCase();

    if (s == ServiceRecordModel.statusCancel || s.contains('cancel')) {
      return (icon: Icons.cancel_rounded, color: _kDanger,  bg: _kDanger.withValues(alpha: 0.10), label: 'Cancelled');
    }
    if (s == ServiceRecordModel.statusCompleted || s.contains('complete')) {
      return (icon: Icons.verified_rounded, color: _kSuccess, bg: _kSuccess.withValues(alpha: 0.10), label: 'Completed');
    }
    // default -> in progress
    return (icon: Icons.build_circle_rounded, color: _kWarning, bg: _kWarning.withValues(alpha: 0.10), label: 'In progress');
  }

  Widget _statusPill(String text, Color color, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: (12 * s).clamp(11, 13),
        ),
      ),
    );
  }

  Widget _buildServiceRecordCard(
      ServiceRecordModel r,
      String vehicleId,
      double s,
      bool isLast,
      ) {
    final look = _statusLook(r.status); // pick icon/color/pill by status

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16 * s),
      decoration: BoxDecoration(
        color: _kLightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewService(vehicleId: vehicleId, record: r),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16 * s),
            child: Row(
              children: [
                // Leading status icon (color-coded)
                Container(
                  padding: EdgeInsets.all(10 * s),
                  decoration: BoxDecoration(
                    color: look.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    look.icon,
                    color: look.color,
                    size: 20 * s,
                  ),
                ),
                SizedBox(width: 16 * s),

                // Middle content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fmt(r.date),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: (16 * s).clamp(15, 17),
                                color: Colors.black,
                              ),
                            ),
                          ),
                          // Amount chip
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currency.format(r.displayTotal),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: (14 * s).clamp(13, 15),
                                color: _kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6 * s),

                      // Description
                      Text(
                        r.description,
                        style: TextStyle(
                          color: _kGrey,
                          fontSize: (14 * s).clamp(13, 15),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 8 * s),

                      // Status pill
                      Row(
                        children: [
                          _statusPill(look.label, look.color, s),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8 * s),
                Icon(Icons.arrow_forward_ios_rounded, size: 16 * s, color: _kGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(VehicleModel v, FirestoreService db, bool isInactive, double s) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isInactive ? _kSuccess : _kDanger).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isInactive ? _kSuccess : _kDanger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(
            isInactive ? Icons.restore_rounded : Icons.archive_rounded,
            size: 24,
          ),
          label: Text(
            isInactive ? 'Restore Vehicle' : 'Deactivate Vehicle',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          onPressed: () async {
            if (isInactive) {
              // RESTORE — require global password
              final ok = await _promptPassword(context);
              if (!ok) return;

              await db.deleteVehicle(widget.vehicleId, 'active');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Vehicle restored to Active'),
                    backgroundColor: _kSuccess,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                Navigator.pop(context, true);
              }
            } else {
              // DEACTIVATE with confirmation
              final sure = await _showDeactivateDialog();
              if (!sure) return;

              await db.deleteVehicle(widget.vehicleId, 'inactive');
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Vehicle set to Inactive'),
                    backgroundColor: _kWarning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<bool> _showDeactivateDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: _kWarning, size: 28),
            const SizedBox(width: 12),
            const Text('Deactivate Vehicle'),
          ],
        ),
        content: const Text(
          'This will set the vehicle status to Inactive. You can restore it later with the manager password.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _kGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kDanger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _promptPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: _kPrimary, size: 28),
            const SizedBox(width: 12),
            const Text('Confirm Restore'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the manager password to restore this vehicle:'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Manager Password',
                prefixIcon: const Icon(Icons.key_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _kPrimary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _kGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kSuccess,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;

    if (!ok) return false;

    if (ctrl.text.trim() != kRestorePassword) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Incorrect password'),
            backgroundColor: _kDanger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return false;
    }
    return true;
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}