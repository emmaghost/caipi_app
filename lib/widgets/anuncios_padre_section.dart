import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/alumno.dart';
import '../models/anuncio.dart';
import '../services/supabase_service.dart';
import 'anuncio_card.dart';

enum _FiltroAnunciosPadre { todos, noLeidos, leidos }

/// Anuncios del padre: más nuevos primero, filtro leído/no leído,
/// altura acotada (no empujan toda la pantalla).
class AnunciosPadreSection extends StatefulWidget {
  final String usuarioId;

  const AnunciosPadreSection({super.key, required this.usuarioId});

  @override
  State<AnunciosPadreSection> createState() => _AnunciosPadreSectionState();
}

class _AnunciosPadreSectionState extends State<AnunciosPadreSection> {
  _FiltroAnunciosPadre _filtro = _FiltroAnunciosPadre.todos;

  bool _visibleParaPadre(Anuncio a, Set<String> gradoIdsHijos) {
    if (a.paraTodos) return true;
    if (a.paraGrados.isEmpty) return true;
    return a.paraGrados.any(gradoIdsHijos.contains);
  }

  List<Anuncio> _aplicarFiltro(List<Anuncio> base) {
    switch (_filtro) {
      case _FiltroAnunciosPadre.noLeidos:
        return base
            .where((a) => !a.fueLeidoPor(widget.usuarioId))
            .toList();
      case _FiltroAnunciosPadre.leidos:
        return base.where((a) => a.fueLeidoPor(widget.usuarioId)).toList();
      case _FiltroAnunciosPadre.todos:
        return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SupabaseService>();
    final maxH = MediaQuery.sizeOf(context).height * 0.38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Anuncios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                label: 'Todos',
                selected: _filtro == _FiltroAnunciosPadre.todos,
                onTap: () =>
                    setState(() => _filtro = _FiltroAnunciosPadre.todos),
              ),
              const SizedBox(width: 8),
              _chip(
                label: 'No leídos',
                selected: _filtro == _FiltroAnunciosPadre.noLeidos,
                onTap: () =>
                    setState(() => _filtro = _FiltroAnunciosPadre.noLeidos),
              ),
              const SizedBox(width: 8),
              _chip(
                label: 'Leídos',
                selected: _filtro == _FiltroAnunciosPadre.leidos,
                onTap: () =>
                    setState(() => _filtro = _FiltroAnunciosPadre.leidos),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Del más reciente al más antiguo',
          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.gris),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<Alumno>>(
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
                    .where((a) => _visibleParaPadre(a, gradoIds))
                    .toList()
                  ..sort(
                    (a, b) =>
                        b.fechaPublicacion.compareTo(a.fechaPublicacion),
                  );
                final filtrados = _aplicarFiltro(todos);
                final noLeidos =
                    todos.where((a) => !a.fueLeidoPor(widget.usuarioId)).length;

                if (todos.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No hay anuncios',
                          style: GoogleFonts.poppins(color: AppColors.gris),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (noLeidos > 0 &&
                        _filtro != _FiltroAnunciosPadre.leidos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '$noLeidos sin leer',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.rosa,
                          ),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH),
                      child: filtrados.isEmpty
                          ? Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    _filtro == _FiltroAnunciosPadre.noLeidos
                                        ? 'No tienes anuncios sin leer'
                                        : _filtro ==
                                                _FiltroAnunciosPadre.leidos
                                            ? 'Aún no has marcado anuncios como leídos'
                                            : 'Sin anuncios en este filtro',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.gris,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filtrados.length,
                              itemBuilder: (context, i) {
                                final anuncio = filtrados[i];
                                return AnuncioCard(
                                  anuncio: anuncio,
                                  usuarioId: widget.usuarioId,
                                  onMarcarLeido: () async {
                                    await service.marcarAnuncioLeido(
                                      anuncio.id,
                                      widget.usuarioId,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    if (filtrados.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Desliza dentro del recuadro para ver más',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.gris,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.rosa.withOpacity(0.25),
      checkmarkColor: AppColors.rosa,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
