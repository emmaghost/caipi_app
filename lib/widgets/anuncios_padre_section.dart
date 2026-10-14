import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/alumno.dart';
import '../models/anuncio.dart';
import '../services/anuncios_leidos_local.dart';
import '../services/supabase_service.dart';
import 'anuncio_card.dart';

enum FiltroAnunciosPadre { todos, noLeidos, leidos }

/// Anuncios del padre: más nuevos primero, filtro leído/no leído.
class AnunciosPadreSection extends StatefulWidget {
  final String usuarioId;
  final bool pantallaCompleta;

  const AnunciosPadreSection({
    super.key,
    required this.usuarioId,
    this.pantallaCompleta = false,
  });

  @override
  State<AnunciosPadreSection> createState() => _AnunciosPadreSectionState();
}

class _AnunciosPadreSectionState extends State<AnunciosPadreSection> {
  FiltroAnunciosPadre _filtro = FiltroAnunciosPadre.todos;
  final Set<String> _leidosLocal = {};

  @override
  void initState() {
    super.initState();
    AnunciosLeidosLocal.cargar(widget.usuarioId);
    AnunciosLeidosLocal.tick.addListener(_alCambiarLeidos);
  }

  @override
  void dispose() {
    AnunciosLeidosLocal.tick.removeListener(_alCambiarLeidos);
    super.dispose();
  }

  void _alCambiarLeidos() {
    if (mounted) setState(() {});
  }

  bool _leido(Anuncio a) =>
      a.fueLeidoPor(widget.usuarioId) ||
      _leidosLocal.contains(a.id) ||
      AnunciosLeidosLocal.contiene(a.id);

  List<Anuncio> aplicarFiltro(List<Anuncio> base, FiltroAnunciosPadre filtro) {
    switch (filtro) {
      case FiltroAnunciosPadre.noLeidos:
        return base.where((a) => !_leido(a)).toList();
      case FiltroAnunciosPadre.leidos:
        return base.where(_leido).toList();
      case FiltroAnunciosPadre.todos:
        return base;
    }
  }

  Future<void> _marcarLeido(SupabaseService service, Anuncio anuncio) async {
    setState(() => _leidosLocal.add(anuncio.id));
    await AnunciosLeidosLocal.marcar(widget.usuarioId, anuncio.id);
    try {
      await service.marcarAnuncioLeido(anuncio.id, widget.usuarioId);
    } catch (_) {
      // El leído ya quedó en el teléfono. La base a veces lo rechaza.
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final completa = widget.pantallaCompleta;
    final maxH = MediaQuery.sizeOf(context).height * 0.46;

    return StreamBuilder<List<Alumno>>(
      stream: service.getAlumnosPorPadre(widget.usuarioId),
      builder: (context, hijosSnap) {
        final gradoIds = <String>{
          for (final h in hijosSnap.data ?? const <Alumno>[])
            if (h.gradoId != null) h.gradoId!,
        };

        return StreamBuilder<List<Anuncio>>(
          stream: service.getAnuncios(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final todos = (snapshot.data ?? const <Anuncio>[])
                .where((a) => a.visibleParaPadre(gradoIds))
                .toList()
              ..sort(
                (a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion),
              );
            final filtrados = aplicarFiltro(todos, _filtro);
            final noLeidos = todos.where((a) => !_leido(a)).length;
            final leidos = todos.length - noLeidos;

            final filtros = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<FiltroAnunciosPadre>(
                  showSelectedIcon: false,
                  segments: [
                    const ButtonSegment(
                      value: FiltroAnunciosPadre.todos,
                      label: Text('Todos'),
                    ),
                    ButtonSegment(
                      value: FiltroAnunciosPadre.noLeidos,
                      label: Text(noLeidos > 0 ? 'Sin leer ($noLeidos)' : 'Sin leer'),
                    ),
                    ButtonSegment(
                      value: FiltroAnunciosPadre.leidos,
                      label: Text(leidos > 0 ? 'Leídos ($leidos)' : 'Leídos'),
                    ),
                  ],
                  selected: {_filtro},
                  onSelectionChanged: (s) {
                    setState(() => _filtro = s.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: WidgetStatePropertyAll(
                      GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (todos.isEmpty)
                  _cajaVacia('Aún no hay anuncios de la escuela')
                else if (filtrados.isEmpty)
                  _cajaVacia(
                    _filtro == FiltroAnunciosPadre.noLeidos
                        ? 'Ya no tienes anuncios sin leer'
                        : _filtro == FiltroAnunciosPadre.leidos
                            ? 'Aquí van los que marques como leídos'
                            : 'Sin anuncios en este filtro',
                  )
                else if (completa)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: filtrados.length,
                      itemBuilder: (context, i) => _card(service, filtrados[i]),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxH),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: filtrados.length <= 2,
                      itemCount: filtrados.length,
                      itemBuilder: (context, i) => _card(service, filtrados[i]),
                    ),
                  ),
              ],
            );

            if (completa) return filtros;
            return filtros;
          },
        );
      },
    );
  }

  Widget _card(SupabaseService service, Anuncio anuncio) {
    return AnuncioCard(
      anuncio: anuncio,
      usuarioId: widget.usuarioId,
      leidoForzado: _leidosLocal.contains(anuncio.id),
      onMarcarLeido: () => _marcarLeido(service, anuncio),
    );
  }

  Widget _cajaVacia(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: AppColors.gris, fontSize: 13),
      ),
    );
  }
}
