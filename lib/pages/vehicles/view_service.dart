import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_model.dart';
import 'edit_service.dart';
import 'package:workshoppro_manager/firestore_service.dart';

final _currency =
NumberFormat.currency(locale: 'ms_MY', symbol: 'RM', decimalDigits: 2);

class ViewService extends StatefulWidget {
  final String vehicleId;
  final ServiceRecordModel record;

  const ViewService({
    super.key,
    required this.vehicleId,
    required this.record,
  });

  @override
  State<ViewService> createState() => _ViewServiceState();
}

class _ViewServiceState extends State<ViewService>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Keep a mutable copy so we can refresh after editing
  late ServiceRecordModel _record;

  // Color tokens
  static const _kPrimary = Color(0xFF007AFF);
  static const _kSecondary = Color(0xFF5856D6);
  static const _kSuccess = Color(0xFF34C759);
  static const _kDanger = Color(0xFFFF3B30);
  static const _kWarning = Color(0xFFFF9500);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kLightGrey = Color(0xFFF2F2F7);
  static const _kDivider = Color(0xFFE5E5EA);
  static const _kCardShadow = Color(0x1A000000);

  String _fmtHoursMins(double h) {
    final totalMins = (h * 60).round();
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    if (hrs > 0 && mins > 0) {
      return '$hrs hr ${mins.toString().padLeft(2, '0')} min';
    } else if (hrs > 0) {
      return '$hrs hr';
    } else {
      return '$mins min';
    }
  }

  bool get _canEdit {
    final s = _record.status.trim().toLowerCase();
    if (s == ServiceRecordModel.statusCompleted || s == ServiceRecordModel.statusCancel) return false;
    if (s.contains('completed') || s.contains('cancelled')) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _record = widget.record;

    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController =
        AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _refreshRecord() async {
    // Re-read current service list once and pick the one we just edited
    final list =
    await FirestoreService().serviceStream(widget.vehicleId).first;
    final updated = list.firstWhere(
          (x) => x.id == _record.id,
      orElse: () => _record,
    );
    setState(() => _record = updated);
  }

  // Reusable toolbar chip button (matches leading/back style)
  Widget _toolbarIconButton({
    required IconData icon,
    required VoidCallback onTap,
    EdgeInsets margin = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return Container(
      margin: margin,
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
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.black, size: 20),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    const base = 375.0;
    final s = (w / base).clamp(0.95, 1.12);

    return Scaffold(
      backgroundColor: _kLightGrey,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                shadowColor: _kCardShadow,

                // Back (left)
                leading: _toolbarIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),

                // Edit (right)
                actions: [
                  if (_canEdit)
                    _toolbarIconButton(
                      icon: Icons.edit_rounded,
                      tooltip: 'Edit service',
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditService(
                              vehicleId: widget.vehicleId,
                              record: _record,
                            ),
                          ),
                        );
                        if (changed == true) {
                          await _refreshRecord(); // <- reload and repaint
                        }
                      },
                    ),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Service Record',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: (20 * s).clamp(18, 22),
                        ),
                      ),
                    ],
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
                      _buildStatusBar(s),
                      SizedBox(height: 16 * s),
                      _buildServiceOverviewCard(s),
                      SizedBox(height: 24 * s),
                      _buildPartsSection(s),
                      SizedBox(height: 24 * s),
                      _buildLaborSection(s),
                      SizedBox(height: 24 * s),
                      _buildTotalCard(s),
                      if ((_record.notes ?? '').isNotEmpty) ...[
                        SizedBox(height: 24 * s),
                        _buildNotesSection(s),
                      ],
                      if (_canEdit) ...[
                        SizedBox(height: 24 * s),
                        _buildQuickActions(s),
                      ],
                      SizedBox(height: 32 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(double s) {
    return Row(
      children: [
        // Cancel
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmStatusChange(
              title: 'Cancel service?',
              message: 'This will mark the service as cancelled.',
              nextStatus: ServiceRecordModel.statusCancel,
            ),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Cancel Service'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: const BorderSide(color: _kDanger),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12 * s),
        // Complete
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmStatusChange(
              title: 'Complete service?',
              message: 'This will mark the service as completed and create an invoice.',
              nextStatus: ServiceRecordModel.statusCompleted,
            ),
            icon: const Icon(Icons.verified_rounded, color: Colors.white),
            label: const Text('Complete Service', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kSuccess,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildServiceOverviewCard(double s) {
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
                    Icons.build_circle_rounded,
                    color: _kPrimary,
                    size: 24 * s,
                  ),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Details',
                        style: TextStyle(
                          fontSize: (22 * s).clamp(20, 24),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        _fmt(_record.date),
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
                    _kDivider.withValues(alpha: 0.0),
                    _kDivider,
                    _kDivider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
            child: Column(
              children: [
                _enhancedInfoRow(
                    'Description', _record.description, Icons.description_rounded, s),
                _enhancedInfoRow(
                    'Mechanic', _record.mechanic, Icons.person_rounded, s,
                    isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedInfoRow(String label, String value, IconData icon, double s,
      {bool isLast = false}) {
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
            child: Icon(icon, size: 20 * s, color: _kGrey),
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

  Widget _buildPartsSection(double s) {
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
                    color: _kSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.settings_rounded, color: _kSuccess, size: 24 * s),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parts Replaced',
                        style: TextStyle(
                          fontSize: (22 * s).clamp(20, 24),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        '${_record.parts.length} ${_record.parts.length == 1 ? 'part' : 'parts'} used',
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
                    _kDivider.withValues(alpha: 0.0),
                    _kDivider,
                    _kDivider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (_record.parts.isEmpty)
            Padding(
              padding: EdgeInsets.all(24 * s),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_rounded,
                        size: 48 * s, color: _kGrey.withValues(alpha: 0.5)),
                    SizedBox(height: 12 * s),
                    Text('No parts used',
                        style: TextStyle(
                            color: _kGrey,
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 4 * s),
                    Text('This service didn’t require any parts',
                        style: TextStyle(
                            color: _kGrey.withValues(alpha: 0.7), fontSize: 14 * s)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
              child: Column(
                children: _record.parts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final part = entry.value;
                  final isLastItem = index == _record.parts.length - 1;
                  return _buildPartItem(part, s, isLastItem);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPartItem(PartLine part, double s, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16 * s),
      decoration: BoxDecoration(
        color: _kLightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    part.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: (16 * s).clamp(15, 17),
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                  decoration: BoxDecoration(
                    color: _kSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currency.format(part.unitPrice * part.quantity),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: (15 * s).clamp(14, 16),
                      color: _kSuccess,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            Row(
              children: [
                _buildInfoChip('Qty: ${part.quantity}',
                    Icons.inventory_2_rounded, s),
                SizedBox(width: 12 * s),
                _buildInfoChip('${_currency.format(part.unitPrice)} each',
                    Icons.money_sharp, s),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborSection(double s) {
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
                    color: _kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.handyman_rounded,
                      color: _kWarning, size: 24 * s),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Labor',
                        style: TextStyle(
                          fontSize: (22 * s).clamp(20, 24),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        '${_record.labor.length} ${_record.labor.length == 1 ? 'task' : 'tasks'} performed',
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
                    _kDivider.withValues(alpha: 0.0),
                    _kDivider,
                    _kDivider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (_record.labor.isEmpty)
            Padding(
              padding: EdgeInsets.all(24 * s),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.work_outline_rounded,
                        size: 48 * s, color: _kGrey.withValues(alpha: 0.5)),
                    SizedBox(height: 12 * s),
                    Text('No labor charges',
                        style: TextStyle(
                            color: _kGrey,
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 4 * s),
                    Text('This service had no billable labor',
                        style: TextStyle(
                            color: _kGrey.withValues(alpha: 0.7), fontSize: 14 * s)),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
              child: Column(
                children: _record.labor.asMap().entries.map((entry) {
                  final index = entry.key;
                  final labor = entry.value;
                  final isLastItem = index == _record.labor.length - 1;
                  return _buildLaborItem(labor, s, isLastItem);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLaborItem(LaborLine labor, double s, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16 * s),
      decoration: BoxDecoration(
        color: _kLightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    labor.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: (16 * s).clamp(15, 17),
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                  decoration: BoxDecoration(
                    color: _kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _currency.format(labor.rate * labor.hours),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: (15 * s).clamp(14, 16),
                      color: _kWarning,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * s),
            Row(
              children: [
                _buildInfoChip(_fmtHoursMins(labor.hours),
                    Icons.schedule_rounded, s),
                SizedBox(width: 12 * s),
                _buildInfoChip('${_currency.format(labor.rate)}/hr',
                    Icons.trending_up_rounded, s),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: _kGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * s, color: _kGrey),
          SizedBox(width: 6 * s),
          Text(
            text,
            style: TextStyle(
              color: _kGrey,
              fontSize: (13 * s).clamp(12, 14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double s) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kSecondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(15 * s),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12 * s),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  color: Colors.white, size: 24 * s),
            ),
            SizedBox(width: 16 * s),
            Text(
              'Total Amount',
              style: TextStyle(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                fontSize: (16 * s).clamp(15, 17),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _currency.format(_record.displayTotal),
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: (24 * s).clamp(22, 26),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(double s) {
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
                    color: _kDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.note_alt_rounded,
                      color: _kDanger, size: 24 * s),
                ),
                SizedBox(width: 16 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: (22 * s).clamp(20, 24),
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        'Additional information',
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
                    _kDivider.withValues(alpha: 0.0),
                    _kDivider,
                    _kDivider.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 24 * s),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18 * s),
              decoration: BoxDecoration(
                color: _kLightGrey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kDivider.withValues(alpha: 0.5)),
              ),
              child: Text(
                _record.notes!,
                style: TextStyle(
                  color: _kGrey,
                  fontSize: (15 * s).clamp(14, 16),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------- STATUS BAR (Stepper) -------

  int _statusIndexOf(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == ServiceRecordModel.statusCancel) return -1;          // cancelled
    if (s == ServiceRecordModel.statusCompleted || s.contains('completed')) return 2;
    if (s == ServiceRecordModel.statusInProgress || s.contains('in progress')) return 1;
    // default to scheduled
    return 0;
  }

  Widget _buildStatusBar(double s) {
    // Step definitions
    final steps = <({String label, IconData icon})>[
      (label: 'Scheduled',   icon: Icons.event_available_rounded),
      (label: 'In progress', icon: Icons.build_rounded),
      (label: 'Completed',   icon: Icons.verified_rounded),
    ];

    final idx = _statusIndexOf(_record.status);

    // Cancelled UI
    if (idx == -1) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
        decoration: BoxDecoration(
          color: _kDanger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kDanger.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(color: _kCardShadow, blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10 * s),
              decoration: BoxDecoration(
                color: _kDanger.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cancel_rounded, color: _kDanger, size: 22 * s),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(
                'Cancelled',
                style: TextStyle(
                  color: _kDanger,
                  fontWeight: FontWeight.w800,
                  fontSize: (16 * s).clamp(15, 18),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _kDanger.withValues(alpha: 0.35)),
              ),
              child: Text(
                _record.status,
                style: TextStyle(color: _kDanger, fontWeight: FontWeight.w600, fontSize: (12 * s).clamp(11, 13)),
              ),
            ),
          ],
        ),
      );
    }

    Color dotColor(int i) => (i <= idx) ? _kSuccess : _kGrey.withValues(alpha: 0.6);
    Color dotBg(int i)    => (i <= idx) ? _kSuccess.withValues(alpha: 0.12) : _kLightGrey;
    Color lineColor(int i) => (i < idx) ? _kSuccess : _kDivider;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kCardShadow, blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Icons + connecting lines
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // connector
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 6 * s),
                    decoration: BoxDecoration(
                      color: lineColor((i ~/ 2)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              } else {
                final stepIdx = i ~/ 2;
                final step = steps[stepIdx];
                return Column(
                  children: [
                    Container(
                      width: 44 * s,
                      height: 44 * s,
                      decoration: BoxDecoration(
                        color: dotBg(stepIdx),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (stepIdx <= idx) ? _kSuccess : _kDivider,
                          width: 1.2,
                        ),
                      ),
                      child: Icon(step.icon, size: 22 * s, color: dotColor(stepIdx)),
                    ),
                  ],
                );
              }
            }),
          ),
          SizedBox(height: 10 * s),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              return Expanded(
                child: Align(
                  alignment: i == 0
                      ? Alignment.centerLeft
                      : (i == steps.length - 1 ? Alignment.centerRight : Alignment.center),
                  child: Text(
                    steps[i].label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: (12 * s).clamp(11, 13),
                      fontWeight: (i <= idx) ? FontWeight.w700 : FontWeight.w500,
                      color: (i <= idx) ? Colors.black : _kGrey,
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8 * s),
        ],
      ),
    );
  }

  Future<void> _confirmStatusChange({
    required String title,
    required String message,
    required String nextStatus,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (ok == true) {
      await _updateStatus(nextStatus);
    }
  }

  Future<void> _updateStatus(String nextStatus) async {
    // loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              CircularProgressIndicator(color: _kPrimary, strokeWidth: 3),
              SizedBox(width: 20),
              Text('Updating status...'),
            ],
          ),
        ),
      ),
    );

    try {
      // keep everything same, only change status
      final updated = ServiceRecordModel(
        id: _record.id,
        date: _record.date,
        description: _record.description,
        mechanic: _record.mechanic,
        status: nextStatus,
        parts: List.of(_record.parts),
        labor: List.of(_record.labor),
        notes: _record.notes,
      );

      await FirestoreService().updateService(widget.vehicleId, updated);

      // auto-create invoice on completed (same behavior as your Edit page)
      if (nextStatus == ServiceRecordModel.statusCompleted) {
        final vehicle = await FirestoreService().getVehicle(widget.vehicleId);
        if (vehicle != null) {
          try {
            await FirestoreService().addInvoice(
              widget.vehicleId,
              updated,
              vehicle.customerName,
              vehicle.carPlate,
              updated.mechanic,
              updated.mechanic,
            );
          } catch (_) {/* ignore invoice failure */}
        }
      }


      await _refreshRecord(); // re-read so UI reflects status change

      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showSnackBar(
        'Status updated to ${nextStatus[0].toUpperCase()}${nextStatus.substring(1)}',
        _kSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Failed to update status: $e', _kDanger);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _kSuccess
                  ? Icons.check_circle_rounded
                  : color == _kDanger
                  ? Icons.error_rounded
                  : Icons.info_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}
