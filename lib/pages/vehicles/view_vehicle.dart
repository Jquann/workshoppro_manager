import 'package:flutter/material.dart';
import 'package:workshoppro_manager/firestore_service.dart';
import 'vehicle_model.dart';
import 'service_model.dart';
import 'edit_vehicle.dart';
import 'view_service.dart';
import 'add_service.dart';

import 'package:intl/intl.dart';
final _currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM', decimalDigits: 2);

const String kRestorePassword = 'admin123'; // TODO: change this

class ViewVehicle extends StatelessWidget {
  final String vehicleId;
  const ViewVehicle({super.key, required this.vehicleId});

  // tokens
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return FutureBuilder<VehicleModel?>(
      future: db.getVehicle(vehicleId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final v = snap.data;
        if (v == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Vehicle not found')),
          );
        }

        // scale slightly toward the mock’s sizing
        final w = MediaQuery.of(context).size.width;
        const base = 375.0;
        final s = (w / base).clamp(0.95, 1.12);

        final isInactive = (v.status == 'inactive');

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.2,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vehicle Details',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: (22 * s).clamp(20, 24),
                  ),
                ),
                if (isInactive) ...[
                  SizedBox(width: 8 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFCACA)),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: (11 * s).clamp(10, 12),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                ],
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.black),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditVehicle(vehicle: v),
                  ),
                ),
              ),
            ],
          ),

          // ------------------ BODY (scrollable) ------------------
          body: ListView(
            padding: EdgeInsets.fromLTRB(24 * s, 8 * s, 24 * s, 24 * s + 72),
            children: [
              // ---------- VEHICLE INFO ----------
              Padding(
                padding: EdgeInsets.only(top: 8 * s, bottom: 12 * s),
                child: Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: (24 * s).clamp(22, 26),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _infoRow('Customer', v.customerName, s),
              _infoRow('Make', v.make, s),
              _infoRow('Model', v.model, s),
              _infoRow('Year', '${v.year}', s),
              _infoRow('VIN', v.vin, s),

              SizedBox(height: 18 * s),

              // ---------- SERVICE HISTORY ----------
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Service History',
                      style: TextStyle(
                        fontSize: (24 * s).clamp(22, 26),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 4 * s),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: isInactive
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddService(vehicleId: v.id),
                      ),
                    ),
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: isInactive ? _kGrey : _kBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: (16 * s).clamp(15, 17),
                      ),
                    ),
                  ),
                ],
              ),

              StreamBuilder<List<ServiceRecordModel>>(
                stream: db.serviceStream(v.id),
                builder: (context, sSnap) {
                  if (!sSnap.hasData) {
                    return Padding(
                      padding: EdgeInsets.all(12 * s),
                      child: const LinearProgressIndicator(),
                    );
                  }
                  final items = sSnap.data!;
                  if (items.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(left: 2 * s, top: 6 * s),
                      child: Text(
                        'No service records yet.',
                        style: TextStyle(color: _kGrey, fontSize: 15 * s),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...items.map(
                            (r) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 12 * s, horizontal: 2 * s),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewService(vehicleId: v.id, record: r),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // date (L)  +  amount (R)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _fmt(r.date),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: (18 * s).clamp(16, 20),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _currency.format(r.displayTotal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: (18 * s).clamp(16, 20),
                                      ),
                                    ),
                                  ],
                                ),
                                // blue sub-line
                                Padding(
                                  padding: EdgeInsets.only(top: 4 * s),
                                  child: Text(
                                    r.description,
                                    style: TextStyle(
                                      color: _kBlue,
                                      fontSize: (16 * s).clamp(15, 17),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6 * s),
                    ],
                  );
                },
              ),
            ],
          ),

          // ------------------ PINNED ACTION BUTTON ------------------
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInactive ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(isInactive ? Icons.restore : Icons.archive),
                label: Text(
                  isInactive ? 'Restore Vehicle' : 'Deactivate Vehicle',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  if (isInactive) {
                    // RESTORE — require global password
                    final ok = await _promptPassword(context);
                    if (!ok) return;

                    await db.deleteVehicle(vehicleId, 'active');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vehicle restored to Active')),
                      );
                      Navigator.pop(context, true);
                    }
                  } else {
                    // DEACTIVATE with confirmation
                    final sure = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Deactivate Vehicle'),
                        content: const Text(
                          'This will set the vehicle status to Inactive. You can restore it later.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Deactivate', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ) ?? false;
                    if (!sure) return;

                    await db.deleteVehicle(vehicleId, 'inactive');
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vehicle set to Inactive')),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- password dialog ----------
  Future<bool> _promptPassword(BuildContext context) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Restore password',
            helperText: 'Enter the manager password',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    ) ?? false;

    if (!ok) return false;

    if (ctrl.text.trim() != kRestorePassword) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')),
        );
      }
      return false;
    }
    return true;
  }

  // one labeled row with full-width divider
  static Widget _infoRow(String label, String value, double s) => Column(
    children: [
      SizedBox(
        height: (64 * s).clamp(58, 70),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _kGrey,
                  fontSize: (17 * s).clamp(15, 18),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: (18 * s).clamp(16, 20),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 1, color: _kDivider),
    ],
  );

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
}
