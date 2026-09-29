import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../logic/services/notificacion_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _negocio = TextEditingController(text: 'GotaControl');
  final _telefono = TextEditingController(text: '300 000 0000');
  final _direccion = TextEditingController();
  final _porcentajeMora = TextEditingController(text: '10');
  final _diasGracia = TextEditingController(text: '3');
  bool _pinActivo = false;
  bool _alertasMora = true;
  bool _recordatorioDiario = false;
  TimeOfDay _horaRecordatorio = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _negocio.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _porcentajeMora.dispose();
    _diasGracia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _Seccion(
              titulo: 'Datos del negocio',
              icono: Icons.storefront_outlined,
              children: [
                TextField(
                  controller: _negocio,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _direccion,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
              ],
            ),
            _Seccion(
              titulo: 'Configuración de mora',
              icono: Icons.warning_amber_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _porcentajeMora,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Porcentaje de mora',
                          suffixText: '%',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _diasGracia,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Días de gracia',
                        ),
                      ),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alertas de mora'),
                  value: _alertasMora,
                  onChanged: (valor) => setState(() => _alertasMora = valor),
                ),
              ],
            ),
            _Seccion(
              titulo: 'Seguridad',
              icono: Icons.lock_outline,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activar PIN de seguridad'),
                  value: _pinActivo,
                  onChanged: _cambiarPin,
                ),
                if (_pinActivo)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _cambiarPin(true),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Cambiar PIN'),
                    ),
                  ),
              ],
            ),
            _Seccion(
              titulo: 'Notificaciones',
              icono: Icons.notifications_none,
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Resumen diario'),
                  value: _recordatorioDiario,
                  onChanged: _alternarRecordatorio,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hora del recordatorio'),
                  subtitle: Text(_horaRecordatorio.format(context)),
                  trailing: IconButton(
                    tooltip: 'Elegir hora',
                    onPressed: _elegirHora,
                    icon: const Icon(Icons.schedule),
                  ),
                  onTap: _elegirHora,
                ),
              ],
            ),
            _Seccion(
              titulo: 'Respaldo',
              icono: Icons.storage_outlined,
              children: [
                const Text(
                  'Las acciones de respaldo se habilitarán al conectar la base de datos local.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _mensaje(
                        'La exportación estará disponible al conectar SQLite.',
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Exportar base de datos'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _mensaje(
                        'La importación estará disponible al conectar SQLite.',
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Importar base de datos'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _mensaje(
                'Ajustes guardados para esta sesión de demostración.',
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar ajustes'),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'GotaControl · Modo de demostración',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _mensaje(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaRecordatorio,
    );
    if (hora != null) {
      setState(() => _horaRecordatorio = hora);
      if (_recordatorioDiario) await _programarRecordatorio(true);
    }
  }

  Future<void> _alternarRecordatorio(bool valor) async {
    setState(() => _recordatorioDiario = valor);
    await _programarRecordatorio(valor);
  }

  Future<void> _programarRecordatorio(bool habilitado) async {
    final servicio = NotificacionService.instance;
    if (!habilitado) {
      await servicio.cancelarNotificacion(1);
      return;
    }
    await servicio.programarNotificacionDiaria(
      hora: _horaRecordatorio,
      mensaje: 'Revisa el recaudo, la ganancia y las cuotas pendientes de hoy.',
    );
    if (mounted) _mensaje('Recordatorio diario programado.');
  }

  Future<void> _cambiarPin(bool valor) async {
    if (!valor) {
      setState(() => _pinActivo = false);
      return;
    }
    final pin = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear PIN'),
        content: TextField(
          controller: pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'PIN de 4 a 6 dígitos'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (confirmado == true && pin.text.length >= 4) {
      setState(() => _pinActivo = true);
    } else if (confirmado == true) {
      _mensaje('El PIN debe tener al menos 4 dígitos.');
    }
    pin.dispose();
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.children,
  });
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: AppColors.primary, size: 19),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    ),
  );
}
