import 'package:flutter/material.dart';
import '../models/anuncio.dart';
import '../utils/mexico_time.dart';

class AnuncioCard extends StatelessWidget {
  final Anuncio anuncio;
  final String usuarioId;
  final VoidCallback? onMarcarLeido;

  const AnuncioCard({
    super.key,
    required this.anuncio,
    required this.usuarioId,
    this.onMarcarLeido,
  });

  @override
  Widget build(BuildContext context) {
    final leido = anuncio.fueLeidoPor(usuarioId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: leido ? null : anuncio.prioridadColor.withOpacity(0.05),
      child: InkWell(
        onTap: () {
          if (!leido && onMarcarLeido != null) {
            onMarcarLeido!();
          }
          _mostrarDetalleAnuncio(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con prioridad
              Row(
                children: [
                  if (anuncio.prioridad == PrioridadAnuncio.alta)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (anuncio.prioridad == PrioridadAnuncio.alta)
                    const SizedBox(width: 8),
                  
                  if (!leido)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!leido) const SizedBox(width: 8),
                  
                  Expanded(
                    child: Text(
                      MexicoTime.format(
                        anuncio.fechaPublicacion,
                        'dd/MMM/yyyy HH:mm',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Título
              Text(
                anuncio.titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: leido ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Mensaje preview
              Text(
                anuncio.mensaje,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              // Fecha del evento si existe
              if (anuncio.fechaEvento != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: anuncio.prioridadColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Evento: ${MexicoTime.format(anuncio.fechaEvento!, 'dd/MMM/yyyy')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: anuncio.prioridadColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleAnuncio(BuildContext context) {
    final leido = anuncio.fueLeidoPor(usuarioId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          anuncio.titulo,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MexicoTime.format(
                    anuncio.fechaPublicacion,
                    'dd/MM/yyyy HH:mm',
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Text(anuncio.mensaje),
                if (anuncio.fechaEvento != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha del evento:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MexicoTime.format(
                      anuncio.fechaEvento!,
                      'EEEE, dd de MMMM de yyyy',
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!leido && onMarcarLeido != null)
            TextButton(
              onPressed: () {
                onMarcarLeido!();
                Navigator.pop(context);
              },
              child: const Text('Marcar como leído'),
            ),
          FilledButton(
            onPressed: () {
              if (!leido && onMarcarLeido != null) {
                onMarcarLeido!();
              }
              Navigator.pop(context);
            },
            child: Text(leido ? 'Cerrar' : 'Leído y cerrar'),
          ),
        ],
      ),
    );
  }
}
