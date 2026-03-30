import 'package:flutter/material.dart';

/// Paleta de colores oficial CAIPI (basada en el logo)
class AppColors {
  // Colores principales del logo CAIPI
  static const Color rosa = Color(0xFFFF69B4); // Rosa vibrante del logo
  static const Color azulCielo = Color(0xFF87CEEB); // Azul claro del logo
  static const Color azul = Color(0xFF3B82F6); // Azul
  static const Color azulOscuro = Color(0xFF1E40AF); // Azul oscuro
  static const Color amarillo = Color(0xFFFFD700); // Amarillo brillante
  static const Color verde = Color(0xFF90EE90); // Verde manzana
  static const Color naranja = Color(0xFFFF8C42); // Naranja suave
  static const Color morado = Color(0xFFDA70D6); // Orquídea
  static const Color purpura = Color(0xFF8B5CF6); // Púrpura
  static const Color turquesa = Color(0xFF14B8A6); // Turquesa
  static const Color rojo = Color(0xFFEF4444); // Rojo
  
  // Colores secundarios (tonos más claros para fondos)
  static const Color rosaClaro = Color(0xFFFFE4F0);
  static const Color azulClaro = Color(0xFFE0F4FF);
  static const Color amarilloClaro = Color(0xFFFFF9E0);
  static const Color verdeClaro = Color(0xFFE8F8E8);
  static const Color naranjaClaro = Color(0xFFFFE8D6);
  static const Color moradoClaro = Color(0xFFF5E6FF);
  
  // Colores funcionales
  static const Color exitoPago = Color(0xFF10B981); // Verde para pagos al corriente
  static const Color alertaPago = Color(0xFFFBBF24); // Amarillo para pagos próximos
  static const Color errorPago = Color(0xFFEF4444); // Rojo para pagos vencidos
  static const Color info = Color(0xFF3B82F6); // Azul para información
  
  // Gradientes del logo CAIPI
  static const Gradient gradienteArcoiris = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      morado,
      rosa,
      naranja,
      amarillo,
      verde,
      azulCielo,
    ],
  );

  static const Gradient gradientePrincipal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      rosa,
      morado,
    ],
  );

  static const Gradient gradienteCielo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      azulCielo,
      Color(0xFFB0E0E6),
    ],
  );
  
  // Neutros
  static const Color gris = Color(0xFF6B7280);
  static const Color grisOscuro = Color(0xFF4B5563);
  static const Color grisClaro = Color(0xFFF9FAFB);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color negro = Color(0xFF1F2937);
}
