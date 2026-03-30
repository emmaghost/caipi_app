import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final String? mensaje;

  const LoadingOverlay({super.key, this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (mensaje != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    mensaje!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
