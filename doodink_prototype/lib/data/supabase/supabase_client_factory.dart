import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';

class SupabaseClientFactory {
  SupabaseClientFactory._();

  static final SupabaseClient _client = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.anonKey,
  );

  static SupabaseClient get client => _client;
}

