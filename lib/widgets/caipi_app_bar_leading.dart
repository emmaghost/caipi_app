import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// Flecha atrás visible en iPhone.
///
/// Con [drawer] en el Scaffold, Flutter muestra el menú y oculta el back.
/// Esta leading fuerza la flecha; el menú sigue abriéndose con el gesto
/// desde el borde izquierdo.
class CaipiAppBarLeading extends StatelessWidget {
  /// Si true (solo dashboards), muestra el ícono de menú del drawer.
  final bool esRaiz;

  /// Ruta de respaldo si no hay historial ([context.go]).
  final String? rutaInicio;

  const CaipiAppBarLeading({
    super.key,
    this.esRaiz = false,
    this.rutaInicio,
  });

  /// Solo menú hamburguesa (inicio).
  const CaipiAppBarLeading.menu({super.key})
      : esRaiz = true,
        rutaInicio = null;

  @override
  Widget build(BuildContext context) {
    if (esRaiz) {
      return IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menú',
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      tooltip: 'Atrás',
      onPressed: () => volver(context, rutaInicio: rutaInicio),
    );
  }

  /// Vuelve atrás o al home del rol.
  static void volver(BuildContext context, {String? rutaInicio}) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    final ruta = rutaInicio ?? _rutaHome(context);
    context.go(ruta);
  }

  static String _rutaHome(BuildContext context) {
    try {
      final user = context.read<AuthService>().currentUser;
      if (user?.esPadre == true) return '/padre';
    } catch (_) {}
    return '/directora';
  }
}
