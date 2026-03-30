import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/menu_maternal.dart';
import '../../widgets/app_drawer.dart';

class MenuMaternalScreen extends StatefulWidget {
  const MenuMaternalScreen({super.key});

  @override
  State<MenuMaternalScreen> createState() => _MenuMaternalScreenState();
}

class _MenuMaternalScreenState extends State<MenuMaternalScreen> {
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Menú Maternal',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.azulOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _seleccionarFecha,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => GoRouter.of(context).go('/directora'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.azulOscuro.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Encabezado con fecha
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.naranjaClaro, AppColors.amarilloClaro],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Menú del día',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, dd \'de\' MMMM yyyy', 'es_MX')
                              .format(_fechaSeleccionada),
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar, color: Colors.white),
                    onPressed: _seleccionarFecha,
                  ),
                ],
              ),
            ),

            // Lista de menús
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('menu_maternal')
                    .stream(primaryKey: ['id'])
                    .eq('fecha', DateFormat('yyyy-MM-dd').format(_fechaSeleccionada))
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar menús',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_outlined,
                              size: 80,
                              color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay menú para esta fecha',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              GoRouter.of(context).push(
                                '/directora/menu-maternal/crear',
                                extra: {'fecha': _fechaSeleccionada},
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Menú del Día'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final menusData = snapshot.data!;
                  final menus = menusData
                      .map((json) => MenuMaternal.fromJson(json))
                      .toList();

                  // En este caso, debería haber solo un menú por fecha
                  final menu = menus.first;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _MenuCard(menu: menu),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          GoRouter.of(context).push(
            '/directora/menu-maternal/crear',
            extra: {'fecha': _fechaSeleccionada},
          );
        },
        backgroundColor: AppColors.verdeClaro,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nuevo Menú',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }
}

class _MenuCard extends StatelessWidget {
  final MenuMaternal menu;

  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.naranjaClaro, AppColors.amarilloClaro],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menú del Día',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulOscuro,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy', 'es_MX').format(menu.fecha),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 28),
                  onPressed: () {
                    GoRouter.of(context).push(
                      '/directora/menu-maternal/editar/${menu.id}',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Desayuno
            _buildComidaItem(
              icon: Icons.wb_sunny,
              iconColor: Colors.orange,
              titulo: 'Desayuno',
              descripcion: menu.desayuno,
            ),
            const SizedBox(height: 16),

            // Comida
            _buildComidaItem(
              icon: Icons.lunch_dining,
              iconColor: Colors.red,
              titulo: 'Comida',
              descripcion: menu.comida,
            ),
            const SizedBox(height: 16),

            // Merienda
            _buildComidaItem(
              icon: Icons.cookie,
              iconColor: Colors.purple,
              titulo: 'Merienda',
              descripcion: menu.merienda,
            ),

            // Observaciones
            if (menu.observaciones != null && menu.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observaciones',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menu.observaciones!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComidaItem({
    required IconData icon,
    required Color iconColor,
    required String titulo,
    String? descripcion,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion ?? 'No especificado',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
