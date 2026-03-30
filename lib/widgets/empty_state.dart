import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String mensaje;
  final String? submensaje;
  final String? textoBoton;
  final VoidCallback? onPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.mensaje,
    this.submensaje,
    this.textoBoton,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            if (submensaje != null) ...[
              const SizedBox(height: 8),
              Text(
                submensaje!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (textoBoton != null && onPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add),
                label: Text(textoBoton!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
