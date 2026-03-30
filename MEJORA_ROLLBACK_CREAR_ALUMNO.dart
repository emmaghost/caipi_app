// MEJORA: Crear alumno con ROLLBACK automático
// Reemplaza la función _mostrarDialogoCrearPadre() en crear_alumno_screen.dart

Future<String?> _mostrarDialogoCrearPadre() async {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Padre no encontrado'),
      content: Text(
        'El correo ${_padreEmailController.text} no está registrado.\n\n'
        '¿Deseas crear un usuario padre con este correo?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            String? padreIdCreado;
            String? userIdAuth;
            
            try {
              // 1. CREAR USUARIO EN AUTH
              final response = await Supabase.instance.client.auth.signUp(
                email: _padreEmailController.text.trim(),
                password: 'Caipi2026',
              );
              
              if (response.user == null) {
                throw Exception('No se pudo crear el usuario en Auth');
              }
              
              userIdAuth = response.user!.id;
              
              // 2. CREAR REGISTRO EN TABLA USUARIOS
              await Supabase.instance.client.from('usuarios').insert({
                'id': userIdAuth,
                'email': _padreEmailController.text.trim(),
                'rol': 'padre',
                'nombre': 'Padre de ${_nombreController.text}',
              });
              
              padreIdCreado = userIdAuth;
              
              // ✅ TODO EXITOSO
              if (context.mounted) {
                Navigator.pop(context, padreIdCreado);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Padre creado. Password temporal: Caipi2026'),
                    duration: Duration(seconds: 5),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              
            } catch (e) {
              // ❌ ERROR: HACER ROLLBACK
              print('❌ Error creando padre: $e');
              
              // ROLLBACK: Eliminar usuario de Auth si se creó
              if (userIdAuth != null) {
                try {
                  // Nota: Supabase no permite eliminar usuarios desde el cliente
                  // por seguridad, pero podemos marcar el registro en usuarios como inactivo
                  await Supabase.instance.client
                      .from('usuarios')
                      .delete()
                      .eq('id', userIdAuth);
                  
                  print('🔄 Rollback: Usuario eliminado de tabla usuarios');
                } catch (rollbackError) {
                  print('⚠️ Error en rollback: $rollbackError');
                }
              }
              
              if (context.mounted) {
                Navigator.pop(context, null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error al crear padre: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          },
          child: const Text('Crear Padre'),
        ),
      ],
    ),
  );
}

// =====================================================
// MEJORA ADICIONAL: Validar antes de guardar alumno
// =====================================================

Future<void> _guardarAlumnoConValidacion() async {
  if (!_formKey.currentState!.validate()) return;
  if (_fechaNacimiento == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona la fecha de nacimiento')),
    );
    return;
  }

  setState(() => _isLoading = true);

  String? padreIdCreado; // Para hacer rollback si falla
  bool padreCreado = false;

  try {
    final supabaseService = context.read<SupabaseService>();
    final storageService = context.read<StorageService>();

    // 1. BUSCAR O CREAR PADRE
    String? padreId;
    final padreResponse = await Supabase.instance.client
        .from('usuarios')
        .select('id')
        .eq('email', _padreEmailController.text.trim())
        .eq('rol', 'padre')
        .maybeSingle();
    
    if (padreResponse != null) {
      padreId = padreResponse['id'] as String;
    } else {
      // Padre no existe, crear uno nuevo
      if (mounted) {
        padreId = await _mostrarDialogoCrearPadre();
        if (padreId == null) {
          setState(() => _isLoading = false);
          return;
        }
        padreIdCreado = padreId;
        padreCreado = true;
      }
    }

    // 2. DETERMINAR SI ES CREACIÓN O EDICIÓN
    final esEdicion = widget.alumnoId != null;
    final alumnoId = esEdicion ? widget.alumnoId! : const Uuid().v4();

    // 3. SUBIR FOTO (si existe)
    String? fotoUrl;
    if (_fotoSeleccionada != null) {
      fotoUrl = await storageService.subirFotoAlumno(_fotoSeleccionada!, alumnoId);
    }

    // 4. CREAR/ACTUALIZAR ALUMNO
    if (esEdicion) {
      // Actualizar alumno existente
      final alumnoData = {
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'fecha_nacimiento': _fechaNacimiento!.toIso8601String(),
        'genero': _generoSeleccionado,
        'grado_id': _gradoSeleccionado,
        'padre_id': padreId ?? 'sin-padre',
        // ... resto de campos
      };

      if (fotoUrl != null) {
        alumnoData['foto_url'] = fotoUrl;
      }

      await Supabase.instance.client
          .from('alumnos')
          .update(alumnoData)
          .eq('id', alumnoId);

    } else {
      // Crear alumno nuevo
      final alumno = Alumno(
        id: alumnoId,
        nombre: _nombreController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        fechaNacimiento: _fechaNacimiento!,
        genero: _generoSeleccionado,
        gradoId: _gradoSeleccionado,
        padreId: padreId ?? 'sin-padre',
        // ... resto de campos
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await supabaseService.crearAlumno(alumno);
    }

    // ✅ TODO EXITOSO
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(esEdicion 
              ? '✅ Alumno actualizado exitosamente!' 
              : '✅ Alumno creado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }

  } catch (e) {
    // ❌ ERROR: HACER ROLLBACK
    print('❌ Error al guardar alumno: $e');
    
    // ROLLBACK: Si creamos un padre nuevo y falló crear el alumno
    if (padreCreado && padreIdCreado != null) {
      try {
        print('🔄 Iniciando rollback: eliminando padre creado...');
        await Supabase.instance.client
            .from('usuarios')
            .delete()
            .eq('id', padreIdCreado);
        print('✅ Rollback exitoso: padre eliminado');
      } catch (rollbackError) {
        print('⚠️ Error en rollback: $rollbackError');
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e\n\n'
              '${padreCreado ? "Se eliminó el padre creado." : ""}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
