import '../../core/constants/db_constants.dart';

class Cliente {
  const Cliente({
    this.id,
    required this.nombre,
    this.cedula,
    required this.telefono,
    this.direccion,
    this.fotoPath,
    this.notas,
    required this.fechaRegistro,
    this.activo = true,
  });

  final int? id;
  final String nombre;
  final String? cedula;
  final String telefono;
  final String? direccion;
  final String? fotoPath;
  final String? notas;
  final DateTime fechaRegistro;
  final bool activo;

  Map<String, Object?> toMap() => {
    DbConstants.columnId: id,
    DbConstants.clienteNombre: nombre,
    DbConstants.clienteCedula: cedula,
    DbConstants.clienteTelefono: telefono,
    DbConstants.clienteDireccion: direccion,
    DbConstants.clienteFotoPath: fotoPath,
    DbConstants.clienteNotas: notas,
    DbConstants.clienteFechaRegistro: fechaRegistro.toIso8601String(),
    DbConstants.clienteActivo: activo ? 1 : 0,
  };

  factory Cliente.fromMap(Map<String, Object?> map) => Cliente(
    id: (map[DbConstants.columnId] as num?)?.toInt(),
    nombre: map[DbConstants.clienteNombre] as String,
    cedula: map[DbConstants.clienteCedula] as String?,
    telefono: map[DbConstants.clienteTelefono] as String,
    direccion: map[DbConstants.clienteDireccion] as String?,
    fotoPath: map[DbConstants.clienteFotoPath] as String?,
    notas: map[DbConstants.clienteNotas] as String?,
    fechaRegistro: DateTime.parse(
      map[DbConstants.clienteFechaRegistro] as String,
    ),
    activo: ((map[DbConstants.clienteActivo] as num?)?.toInt() ?? 1) != 0,
  );

  Cliente copyWith({
    int? id,
    String? nombre,
    String? cedula,
    String? telefono,
    String? direccion,
    String? fotoPath,
    String? notas,
    DateTime? fechaRegistro,
    bool? activo,
  }) => Cliente(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    cedula: cedula ?? this.cedula,
    telefono: telefono ?? this.telefono,
    direccion: direccion ?? this.direccion,
    fotoPath: fotoPath ?? this.fotoPath,
    notas: notas ?? this.notas,
    fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    activo: activo ?? this.activo,
  );
}
