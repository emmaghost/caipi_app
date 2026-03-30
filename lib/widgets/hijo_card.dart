import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alumno.dart';
import '../config/app_colors.dart';

class HijoCard extends StatelessWidget {
  final Alumno alumno;
  final VoidCallback? onTap;

  const HijoCard({
    super.key,
    required this.alumno,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFCE4EC),
                Color(0xFFF3E5F5),
                Color(0xFFE8EAF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.pink.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade200.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Avatar rosa pastel
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFAD1457), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade400.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.transparent,
                  backgroundImage: alumno.fotoUrl != null
                      ? CachedNetworkImageProvider(alumno.fotoUrl!)
                      : null,
                  child: alumno.fotoUrl == null
                      ? const Icon(
                          Icons.child_care, // Icono de silueta de niño
                          size: 42,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno.nombreCompleto,
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Grado - badge rosa pastel (texto blanco para contraste)
                    FutureBuilder<String>(
                      future: _cargarNombreGrado(alumno.gradoId),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.shade400.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.school, size: 17, color: Colors.white),
                              const SizedBox(width: 7),
                              Text(
                                snapshot.data ?? 'Cargando...',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Edad - badge morado pastel
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.shade300.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cake, size: 17, color: Colors.white),
                          const SizedBox(width: 7),
                          Text(
                            '${alumno.edad} años',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha rosa/morado
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF7C4DFF)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade400.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cargar nombre del grado desde BD
  Future<String> _cargarNombreGrado(String? gradoId) async {
    if (gradoId == null) return 'Sin asignar';
    
    try {
      final response = await Supabase.instance.client
          .from('grados')
          .select('nombre')
          .eq('id', gradoId)
          .maybeSingle();
      
      if (response == null) return 'Sin asignar';
      
      return response['nombre'] as String? ?? 'Sin asignar';
    } catch (e) {
      print('Error cargando grado: $e');
      return 'Sin asignar';
    }
  }
}

