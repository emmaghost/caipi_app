/// Resuelve el payload de una notificación push/local a una ruta GoRouter.
/// Acepta rutas reales (`/directora/...`) y textos legacy (`solicitud_recogida`).
String rutaDesdePayloadPush(String raw) {
  final ruta = raw.trim();
  if (ruta.startsWith('/')) return ruta;
  switch (ruta) {
    case 'solicitud_recogida':
      return '/directora/entrega-afuera';
    case 'chat':
      return '/directora/chat';
    case 'pagos':
      return '/directora/pagos';
    case 'incidentes':
      return '/directora/incidentes';
    case 'anuncios':
      return '/directora/anuncios';
    case 'eventos':
      return '/directora/eventos';
    default:
      return '/directora/entrega-afuera';
  }
}
