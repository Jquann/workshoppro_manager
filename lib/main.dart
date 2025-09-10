import 'package:flutter/material.dart';
import 'package:workshoppro_manager/pages/navigations/drawer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔹 Initialize Firebase
  runApp(MyApp());
}
