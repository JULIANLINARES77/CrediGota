import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ResumenCard extends StatelessWidget {
  const ResumenCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.destacado = false,
    this.subtitulo,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final bool destacado;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: destacado ? null : AppColors.surface,
        gradient: destacado
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.95),
                  color.withValues(alpha: 0.58),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: destacado ? Colors.transparent : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: destacado ? Colors.black : color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: destacado ? Colors.black87 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                color: destacado ? Colors.black : AppColors.textPrimary,
                fontSize: destacado ? 28 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: TextStyle(
                color: destacado ? Colors.black87 : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
