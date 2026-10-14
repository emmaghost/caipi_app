import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/alumno.dart';
import '../models/anuncio.dart';
import '../services/anuncios_leidos_local.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Cuenta anuncios sin leer del papá (mismos filtros que la campanita).
class AnunciosSinLeerBuilder extends StatelessWidget {
  const AnunciosSinLeerBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, int sinLeer) builder;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser?.id;
    if (uid == null) return builder(context, 0);
    AnunciosLeidosLocal.cargar(uid);
    final service = context.read<SupabaseService>();

    return StreamBuilder<List<Alumno>>(
      stream: service.getAlumnosPorPadre(uid),
      builder: (context, hijosSnap) {
        final gradoIds = <String>{
          for (final h in hijosSnap.data ?? const <Alumno>[])
            if (h.gradoId != null) h.gradoId!,
        };

        return StreamBuilder<List<Anuncio>>(
          stream: service.getAnuncios(),
          builder: (context, snap) {
            return ValueListenableBuilder<int>(
              valueListenable: AnunciosLeidosLocal.tick,
              builder: (context, _, __) {
                final n = (snap.data ?? const <Anuncio>[])
                    .where((a) => a.visibleParaPadre(gradoIds))
                    .where(
                      (a) =>
                          !a.fueLeidoPor(uid) &&
                          !AnunciosLeidosLocal.contiene(a.id),
                    )
                    .length;
                return builder(context, n);
              },
            );
          },
        );
      },
    );
  }
}

/// Campanita del papá: badge con anuncios sin leer y abre /padre/anuncios.
class CampanaAnunciosPadre extends StatelessWidget {
  const CampanaAnunciosPadre({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser?.id;
    if (uid == null) return const SizedBox.shrink();

    return AnunciosSinLeerBuilder(
      builder: (context, n) {
        return IconButton(
          tooltip: n > 0 ? '$n anuncio${n == 1 ? '' : 's'} sin leer' : 'Anuncios',
          onPressed: () => context.push('/padre/anuncios'),
          icon: Badge(
            isLabelVisible: n > 0,
            label: Text(n > 9 ? '9+' : '$n'),
            backgroundColor: const Color(0xFFFFD54F),
            textColor: const Color(0xFF5D4037),
            child: Icon(Icons.notifications_outlined, color: color),
          ),
        );
      },
    );
  }
}
