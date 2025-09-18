import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable debug prints and visual debugging in release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.transparent,
      child: const Center(
        child: Text(
          'Error',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      ),
    );
  };
  
  await Firebase.initializeApp(); // 🔹 Initialize Firebase
  runApp(MyApp());
}
