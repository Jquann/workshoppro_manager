import 'package:flutter/material.dart';
import 'pages/navigations/drawer.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRM',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        fontFamily: 'SF Pro',
        // Disable visual debugging
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainAppWithDrawer(),
      debugShowCheckedModeBanner: false,
      // Disable debug banner in release mode
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
