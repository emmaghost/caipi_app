import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/alumno.dart';
import '../config/app_colors.dart';

class AlumnoCard extends StatelessWidget {
  final Alumno alumno;
  final VoidCallback? onTap;
  final bool showAutorizados;

  const AlumnoCard({
    super.key,
    required this.alumno,
    this.onTap,
    this.showAutorizados = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: alumno.fotoUrl != null
              ? CachedNetworkImageProvider(alumno.fotoUrl!)
              : null,
          child: alumno.fotoUrl == null
              ? Text(
                  alumno.nombre[0],
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Text(
          alumno.nombreCompleto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grado: ${alumno.gradoId ?? "Sin asignar"}'),
            Text('Edad: ${alumno.edad} años'),
          ],
        ),
        trailing: showAutorizados
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.verified_user, color: AppColors.verde),
                    tooltip: 'Personas Autorizadas',
                    onPressed: () {
                      context.push('/directora/personas-autorizadas/${alumno.id}?nombre=${Uri.encodeComponent(alumno.nombreCompleto)}');
                    },
                  ),
                  const Icon(Icons.chevron_right),
                ],
              )
            : const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }
}
