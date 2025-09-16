import 'package:flutter/material.dart';
import 'package:workshoppro_manager/pages/crm/crm.dart';
import 'package:workshoppro_manager/pages/inventory_control/inventory_dashboard.dart';
import 'package:workshoppro_manager/pages/invoice/invoice_dashboard.dart';
import 'package:workshoppro_manager/pages/vehicles/vehicle.dart';
import 'package:workshoppro_manager/pages/schedule/schedule.dart';

class MainNavigationPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainNavigationPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 2; // default view

  List<Widget> get _pages => [
    // Vehicles Page
    Center(
      child: VehiclesPage(scaffoldKey: widget.scaffoldKey),
    ),
    // Schedule Page
    SchedulePage(scaffoldKey: widget.scaffoldKey),
    // CRM Page
    CRMPage(scaffoldKey: widget.scaffoldKey),
    // Inventory Page
    InventoryScreen(),
    // Invoices Page
    InvoiceDashboard(scaffoldKey: widget.scaffoldKey),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main content
        Expanded(child: _pages[_selectedIndex]),
        // Bottom Navigation Bar
        Container(
          height: 61,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                Icons.local_shipping_outlined,
                'Vehicles',
                0,
              ),
              _buildBottomNavItem(
                Icons.calendar_today_outlined,
                'Schedule',
                1,
              ),
              _buildBottomNavItem(Icons.people_outline, 'CRM', 2),
              _buildBottomNavItem(
                Icons.inventory_2_outlined,
                'Inventory',
                3,
              ),
              _buildBottomNavItem(
                Icons.description_outlined,
                'Invoices',
                4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    IconData displayIcon;
    
    // Change to filled icon when selected
    switch (icon) {
      case Icons.local_shipping_outlined:
        displayIcon = isSelected ? Icons.local_shipping : icon;
        break;
      case Icons.calendar_today_outlined:
        displayIcon = isSelected ? Icons.calendar_today : icon;
        break;
      case Icons.people_outline:
        displayIcon = isSelected ? Icons.people : icon;
        break;
      case Icons.inventory_2_outlined:
        displayIcon = isSelected ? Icons.inventory_2 : icon;
        break;
      case Icons.description_outlined:
        displayIcon = isSelected ? Icons.description : icon;
        break;
      default:
        displayIcon = icon;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        width: 44,
        height: 50,
        padding: EdgeInsets.only(top: 8),
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(
            displayIcon,
            color: isSelected ? Colors.black : Color(0xFF8E8E93),
            size: 29,
          ),
        ),
      ),
    );
  }
}
