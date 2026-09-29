import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/prestamo.dart';
import '../../../logic/providers/demo_provider.dart';
import '../../widgets/cliente_card.dart';
import '../prestamos/prestamo_detail_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _busqueda = TextEditingController();
  String _filtro = 'Todos';

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = context.watch<DemoProvider>();
    final clientes = demo.clientes.where((cliente) {
      if (!cliente.activo) return false;
      final consulta = _busqueda.text.trim().toLowerCase();
      final coincide =
          cliente.nombre.toLowerCase().contains(consulta) ||
          (cliente.cedula ?? '').toLowerCase().contains(consulta) ||
          cliente.telefono.toLowerCase().contains(consulta);
      if (!coincide) return false;
      final prestamos = demo.prestamosDeCliente(cliente.id!);
      return switch (_filtro) {
        'En mora' => prestamos.any((prestamo) => prestamo.estado == 'MORA'),
        'Pagados' =>
          prestamos.isNotEmpty &&
              prestamos.every((prestamo) => prestamo.estado == 'PAGADO'),
        'Al día' => prestamos.any((prestamo) => prestamo.estado == 'ACTIVO'),
        _ => true,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Nuevo cliente',
            onPressed: _agregarCliente,
            icon: const Icon(Icons.person_add_alt_1),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _busqueda,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, cédula o teléfono',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _busqueda.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filtro in [
                      'Todos',
                      'Al día',
                      'En mora',
                      'Pagados',
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(filtro),
                          selected: _filtro == filtro,
                          onSelected: (_) => setState(() => _filtro = filtro),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: clientes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay clientes para este filtro.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: clientes.length,
                        itemBuilder: (context, index) =>
                            _clienteListTile(clientes[index], demo),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'clients-add-client',
        tooltip: 'Agregar cliente',
        onPressed: _agregarCliente,
        child: const Icon(Icons.person_add_alt_1),
      ),
    );
  }

  Widget _clienteListTile(Cliente cliente, DemoProvider demo) {
    final prestamos = demo.prestamosDeCliente(cliente.id!);
    final prestamo = prestamos.isEmpty ? null : prestamos.last;
    final cuotaSiguiente = prestamo == null
        ? null
        : demo
              .cuotasDePrestamo(prestamo.id!)
              .where((cuota) => cuota.estado != 'PAGADA')
              .firstOrNull;
    final estado = prestamo?.estado ?? 'PENDIENTE';
    final card = ClienteCard(
      cliente: cliente,
      saldoPendiente: prestamo?.saldoPendiente ?? 0,
      estado: estado,
      proximoPago: cuotaSiguiente?.fechaVencimiento,
      onTap: prestamo == null ? null : () => _abrirPrestamo(prestamo),
    );
    return Dismissible(
      key: ValueKey('cliente-${cliente.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desactivar cliente'),
          content: Text('¿Deseas ocultar a ${cliente.nombre} de la lista?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          context.read<DemoProvider>().desactivarCliente(cliente.id!),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person_off_outlined, color: Colors.white),
      ),
      child: card,
    );
  }

  Future<void> _agregarCliente() async {
    final nombre = TextEditingController();
    final telefono = TextEditingController();
    final cedula = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombre,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cedula,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cédula (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted) {
      nombre.dispose();
      telefono.dispose();
      cedula.dispose();
      return;
    }
    if (confirmado == true) {
      if (nombre.text.trim().isEmpty || telefono.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nombre y teléfono son obligatorios.')),
        );
      } else {
        context.read<DemoProvider>().agregarCliente(
          nombre: nombre.text,
          telefono: telefono.text,
          cedula: cedula.text.isEmpty ? null : cedula.text,
        );
      }
    }
    nombre.dispose();
    telefono.dispose();
    cedula.dispose();
  }

  void _abrirPrestamo(Prestamo prestamo) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PrestamoDetailScreen(prestamoId: prestamo.id!),
      ),
    );
  }
}
