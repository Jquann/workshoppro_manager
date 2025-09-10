import 'package:flutter/material.dart';
import 'pages/navigations/drawer.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'SF Pro'),
      home: MainAppWithDrawer(),
      debugShowCheckedModeBanner: false,
    );
  }
}
