import 'package:flutter/material.dart';
import 'package:workshoppro_manager/pages/crm/crm.dart';

class MainNavigationPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainNavigationPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 2; // CRM tab is selected

  List<Widget> get _pages => [
    // Vehicles Page
    Center(
      child: Text(
        'Vehicles',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    // Schedule Page
    Center(
      child: Text(
        'Schedule',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    // CRM Page
    CRMPage(scaffoldKey: widget.scaffoldKey),
    // Inventory Page
    Center(
      child: Text(
        'Inventory',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    // Invoices Page
    Center(
      child: Text(
        'Invoices',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  final List<String> _pageTitles = [
    'Vehicles',
    'Schedule',
    'CRM',
    'Inventory',
    'Invoices',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 0.5,
              offset: Offset(0, -0.5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 49,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(Icons.local_shipping_outlined, 'Vehicles', 0),
                _buildBottomNavItem(Icons.calendar_today_outlined, 'Schedule', 1),
                _buildBottomNavItem(Icons.people_outline, 'CRM', 2),
                _buildBottomNavItem(Icons.inventory_2_outlined, 'Inventory', 3),
                _buildBottomNavItem(Icons.description_outlined, 'Invoices', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Color(0xFF007AFF) : Color(0xFF8E8E93),
            size: 24,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Color(0xFF007AFF) : Color(0xFF8E8E93),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}