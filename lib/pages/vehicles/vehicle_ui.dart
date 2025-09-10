import 'package:flutter/material.dart';
import 'package:workshoppro_manager/firestore_service.dart';
import 'vehicle_model.dart';
import 'view_vehicle.dart';
import 'add_vehicle.dart';

class VehicleUI extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const VehicleUI({super.key, this.scaffoldKey});

  @override
  State<VehicleUI> createState() => _VehicleUIState();
}

class _VehicleUIState extends State<VehicleUI> {
  // inline tokens (no new files)
  static const _kBlue = Color(0xFF007AFF);
  static const _kGrey = Color(0xFF8E8E93);
  static const _kDivider = Color(0xFFE5E5EA);

  final _db = FirestoreService();
  String _q = '';

  InputDecoration _search() => InputDecoration(
    hintText: 'Search',
    hintStyle: const TextStyle(fontSize: 14, color: _kGrey),
    prefixIcon: const Icon(Icons.search, size: 20, color: _kGrey),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBlue),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.2,
        title: const Text('Vehicle',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddVehicle())),
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: _search(),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          Expanded(
            child: StreamBuilder<List<VehicleModel>>(
              stream: _db.vehiclesStream(q: _q),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data!;
                if (items.isEmpty) {
                  return const Center(child: Text('No vehicles'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _kDivider),
                  itemBuilder: (_, i) {
                    final v = items[i];
                    return ListTile(
                      minVerticalPadding: 10,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_car, color: _kGrey),
                      ),
                      title: Text(v.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text('${v.year} ${v.make} ${v.model}',
                          style: const TextStyle(color: _kGrey, fontSize: 12)),
                      trailing:
                      const Icon(Icons.chevron_right, color: _kGrey),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewVehicle(vehicleId: v.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
