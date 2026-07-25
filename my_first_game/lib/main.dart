import 'package:flutter/material.dart';
import 'package:my_first_game/app/invader_app.dart';
import 'package:my_first_game/services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurePurchases();
  runApp(const InvaderApp());
}
