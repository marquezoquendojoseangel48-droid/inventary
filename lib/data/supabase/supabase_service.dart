import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

/// Servicio centralizado para comunicación con Supabase
/// Maneja el cliente y operaciones de base de datos
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  late final SupabaseClient _client;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de Supabase
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    _client = Supabase.instance.client;
    _isInitialized = true;
  }

  /// Obtiene el cliente de Supabase
  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('SupabaseService no está inicializado. Llama a initialize() primero.');
    }
    return _client;
  }
}

/// Provider para el servicio de Supabase
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Provider para inicializar Supabase
final supabaseInitializerProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  await service.initialize();
});
