import 'package:flutter/material.dart';
import 'package:workshoppro_manager/firestore_service.dart';
import 'vehicle_model.dart';
import 'add_vehicle.dart';
import 'view_vehicle.dart';

const _kBlue = Color(0xFF007AFF);
const _kGrey = Color(0xFF8E8E93);
const _kDivider = Color(0xFFE5E5EA);

class VehiclesPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const VehiclesPage({super.key, this.scaffoldKey});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final db = FirestoreService();
  String q = '';

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _kDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _kDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _kBlue, width: 1),
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
        title: const Text('Vehicle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0.2,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicle()));
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: _input('Search'),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          const Divider(height: 1, color: _kDivider),
          Expanded(
            child: StreamBuilder<List<VehicleModel>>(
              stream: db.vehiclesStream(q: q),
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
                  separatorBuilder: (_, __) => const Divider(height: 1, color: _kDivider),
                  itemBuilder: (_, i) {
                    final v = items[i];
                    return ListTile(
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.directions_car, color: _kGrey),
                      ),
                      title: Text(v.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("${v.year} ${v.make} ${v.model}", style: const TextStyle(color: _kGrey, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: _kGrey),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ViewVehicle(vehicleId: v.id),
                      )),
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
