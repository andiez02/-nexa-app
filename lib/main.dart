import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseKey = dotenv.env['ANNONKEY'];
  if (supabaseKey == null || supabaseKey.isEmpty) {
    throw Exception(
      'Supabase key (ANNONKEY) missing from .env. Please add it before running the app.',
    );
  }

  await Supabase.initialize(
    url: 'https://ymbzenkneqvltfknqsoz.supabase.co',
    anonKey: supabaseKey,
  );

  await configureDependencies();

  runApp(const NexaApp());
}
