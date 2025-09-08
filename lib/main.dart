import 'package:flutter/material.dart';
import 'package:workshoppro_manager/pages/navigations/drawer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro',
      ),
      home: MainAppWithDrawer(),
      debugShowCheckedModeBanner: false,
    );
  }
}