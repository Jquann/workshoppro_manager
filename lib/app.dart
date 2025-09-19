import 'package:flutter/material.dart';
import 'pages/auth/login.dart';
import 'pages/profile/profile_edit.dart';
import 'pages/profile/profile.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkshopPro Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue, 
        fontFamily: 'SF Pro',
        // Disable visual debugging
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Login(), // Always start with login page
      routes: {
        '/edit_profile': (context) => ProfileEdit(),
        '/view_profile': (context) => Profile(),
      },
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
