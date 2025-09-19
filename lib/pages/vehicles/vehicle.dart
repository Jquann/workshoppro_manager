import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:workshoppro_manager/firestore_service.dart';
import '../../models/vehicle_model.dart';
import 'add_vehicle.dart';
import 'view_vehicle.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // Voice-search state (kept minimal; no flow changes)
  final _searchCtrl = TextEditingController();
  String q = '';
  bool _listening = false;
  late final SpeechToText _stt;

  @override
  void initState() {
    super.initState();
    _stt = SpeechToText();
  }

  @override
  void dispose() {
    _stt.stop();
    _searchCtrl.dispose();
    super.dispose();
  }

  InputDecoration _searchInput(double s) => InputDecoration(
    hintText: 'Search',
    hintStyle: TextStyle(color: _kGrey, fontSize: (14 * s).clamp(13, 16)),
    prefixIcon: const Icon(Icons.search, color: _kGrey),
    suffixIcon: IconButton(
      tooltip: _listening ? 'Stop' : 'Voice Search',
      icon: Icon(_listening ? Icons.mic : Icons.mic_none,
          color: _listening ? Colors.red : _kGrey),
      onPressed: _toggleVoice,
    ),
    filled: true,
    fillColor: _kSurface,
    contentPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 12 * s),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  // ---- Permission & locale helpers ----
  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final req = await Permission.microphone.request();
    if (req.isGranted) return true;

    if (req.isPermanentlyDenied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Microphone in App Settings')),
      );
      await openAppSettings();
    }
    return false;
  }

  Future<String?> _pickLocaleId() async {
    try {
      final sys = await _stt.systemLocale();
      final id = sys?.localeId;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return 'ms_MY';
  }

  // ---- Start/stop voice recognition ----
  Future<void> _toggleVoice() async {
    if (_listening) {
      await _stt.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    // 1) Permission
    if (!await _ensureMicPermission()) return;

    // 2) Initialize STT
    final available = await _stt.initialize(
      onError: (e) {
        debugPrint('STT error: $e');
        if (mounted) {
          setState(() => _listening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${e.errorMsg ?? e.toString()}')),
          );
        }
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
        final s = status.toLowerCase();
        if (s.contains('notlistening') || s.contains('done')) {
          if (mounted) setState(() => _listening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech service unavailable. Install/enable Google app & Speech Services.'),
          ),
        );
      }
      return;
    }

    // 3) Locale & timing
    final locale = await _pickLocaleId();
    if (mounted) setState(() => _listening = true);

    await _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        debugPrint('STT result: "$text" (final=${result.finalResult})');
        _searchCtrl.text = text;
        _searchCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchCtrl.text.length),
        );
        if (mounted) setState(() => q = text);
      },
      listenMode: ListenMode.dictation,   // longer window than confirmation
      partialResults: true,
      cancelOnError: true,
      localeId: locale,                   // try ms_MY or en_US if needed
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => widget.scaffoldKey?.currentState?.openDrawer(),
        ),
        title: const Text(
          'Vehicle',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
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
                        controller: _searchCtrl,
                        decoration: _searchInput(s),
                        onChanged: (v) => setState(() => q = v),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<List<VehicleModel>>(
                        stream: db.vehiclesStream(q: q),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          // Only ACTIVE (unchanged)
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
                                            // BOTTOM: car plate
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
                      padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 16 * s),
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
