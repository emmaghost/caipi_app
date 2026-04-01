// Configuración de Supabase (Android e iOS usan esto; un solo lugar).
//
// Opción A — Editar valores por defecto abajo (lo más simple en tu PC).
//   Supabase → Project Settings → API → "Project URL" y "anon public".
//
// Opción B — Sin pegar claves en el archivo (repo público, CI, etc.):
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
//
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qxldfqnuwpucptajcazf.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4bGRmcW51d3B1Y3B0YWpjYXpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDkxNTQsImV4cCI6MjA4ODEyNTE1NH0.7ruhv9B_DyHwsdsC13EAZa2IVFMyXa5BSjlDY9-GSyE',
  );
}
