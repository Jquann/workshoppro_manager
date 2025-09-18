import 'package:flutter/material.dart';
import 'package:workshoppro_manager/firestore_service.dart';
import '../../models/vehicle_model.dart';
import 'add_vehicle.dart';
import 'view_vehicle.dart';

const _kGrey = Color(0xFF8E8E93);
const _kSurface = Color(0xFFF2F2F7);

class VehiclesPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const VehiclesPage({super.key, this.scaffoldKey});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final db = FirestoreService();
  String q = '';

  InputDecoration _searchInput(double s) => InputDecoration(
    hintText: 'Search',
    hintStyle: TextStyle(color: _kGrey, fontSize: (14 * s).clamp(13, 16)),
    prefixIcon: const Icon(Icons.search, color: _kGrey),
    filled: true,
    fillColor: _kSurface,
    contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
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
        title: const Text('Vehicle',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0.2,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddVehicle()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, c) {
                const base = 375.0;
                final s = (c.maxWidth / base).clamp(0.95, 1.15);

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 10 * s),
                      child: TextField(
                        decoration: _searchInput(s),
                        onChanged: (v) => setState(() => q = v),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<VehicleModel>>(
                        stream: db.vehiclesStream(q: q),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          // Show only ACTIVE
                          final items =
                          snap.data!.where((v) => v.status == 'active').toList();

                          if (items.isEmpty) {
                            return const Center(child: Text('No vehicles'));
                          }
                          return ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 4 * s),
                            physics: const BouncingScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Colors.transparent),
                            itemBuilder: (_, i) {
                              final v = items[i];
                              final plate = (v.carPlate ?? '').trim().isEmpty
                                  ? '–'
                                  : v.carPlate!.trim();
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ViewVehicle(vehicleId: v.id),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16 * s, vertical: 6 * s),
                                  child: Row(
                                    children: [
                                      _thumb(i, s),
                                      SizedBox(width: 12 * s),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // TOP: year make model (bold, black)
                                            Text(
                                              '${v.year} ${v.make} ${v.model}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: (15 * s).clamp(14, 16),
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 2 * s),
                                            // BOTTOM: car plate (grey)
                                            Text(
                                              plate,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: _kGrey,
                                                fontSize: (13 * s).clamp(12, 14),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: _kGrey),
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
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tooltip: 'Show Inactive',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InactiveVehiclesPage()),
          );
        },
        child: const Icon(Icons.archive_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // colored “avatar” circle/square like mock
  Widget _thumb(int i, double s) {
    const swatches = [
      Color(0xFFE3F2FD),
      Color(0xFFE8F5E9),
      Color(0xFFFFF3E0),
      Color(0xFFEDE7F6),
      Color(0xFFFFEBEE),
      Color(0xFFE0F7FA),
    ];
    final bg = swatches[i % swatches.length];
    return Container(
      width: (52 * s).clamp(46, 58),
      height: (52 * s).clamp(46, 58),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.directions_car, color: _kGrey, size: (26 * s).clamp(22, 28)),
    );
  }
}

/// ===================== INACTIVE VEHICLES PAGE =====================

class InactiveVehiclesPage extends StatelessWidget {
  const InactiveVehiclesPage({super.key});

  static const _kGrey = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inactive Vehicles',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0.2,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LayoutBuilder(
              builder: (context, c) {
                const base = 375.0;
                final s = (c.maxWidth / base).clamp(0.95, 1.15);

                return StreamBuilder<List<VehicleModel>>(
                  stream: db.vehiclesStream(q: ''),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items =
                    snap.data!.where((v) => v.status == 'inactive').toList();

                    if (items.isEmpty) {
                      return const Center(child: Text('No inactive vehicles'));
                    }

                    return ListView.separated(
                      padding:
                      EdgeInsets.symmetric(vertical: 8 * s, horizontal: 16 * s),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.transparent),
                      itemBuilder: (_, i) {
                        final v = items[i];
                        final plate = (v.carPlate ?? '').trim().isEmpty
                            ? '–'
                            : v.carPlate!.trim();

                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewVehicle(vehicleId: v.id),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 0),
                            child: Row(
                              children: [
                                _thumb(i, s),
                                SizedBox(width: 12 * s),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // TOP: year make model
                                      Text(
                                        '${v.year} ${v.make} ${v.model}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: (15 * s).clamp(14, 16),
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 2 * s),
                                      // BOTTOM: plate (grey)
                                      Text(
                                        plate,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _kGrey,
                                          fontSize: (13 * s).clamp(12, 14),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: _kGrey),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb(int i, double s) {
    const swatches = [
      Color(0xFFE3F2FD),
      Color(0xFFE8F5E9),
      Color(0xFFFFF3E0),
      Color(0xFFEDE7F6),
      Color(0xFFFFEBEE),
      Color(0xFFE0F7FA),
    ];
    final bg = swatches[i % swatches.length];
    return Container(
      width: (52 * s).clamp(46, 58),
      height: (52 * s).clamp(46, 58),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.directions_car, color: _kGrey, size: (26 * s).clamp(22, 28)),
    );
  }
}
