import 'package:flutter/material.dart';

import 'app/app.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await configureDependencies();
  
  runApp(const NexaApp());
}
