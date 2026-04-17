import 'package:cari_untung/src/app/app.dart';
import 'package:cari_untung/src/core/constants/supabase_constants.dart';
import 'package:cari_untung/src/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await NotificationService.init();

  runApp(const CariUntungApp());
}
