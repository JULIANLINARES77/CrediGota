import '../../core/constants/db_constants.dart';

class AjustesNegocioValidator {
  AjustesNegocioValidator._();

  static const int maxNombre = 250;
  static const int maxTelefono = 15;
  static const int maxDireccion = 250;
  static const double maxPorcentajeMora = 100;
  static const int maxDiasGracia = 365;

  static void validar(Map<String, Object?> configuracion) {
    final nombre =
        configuracion[DbConstants.configuracionNombreNegocio] as String? ?? '';
    final telefono =
        configuracion[DbConstants.configuracionTelefonoNegocio] as String? ??
        '';
    final direccion =
        configuracion[DbConstants.configuracionDireccionNegocio] as String? ??
        '';
    final porcentaje =
        (configuracion[DbConstants.configuracionPorcentajeMora] as num?)
            ?.toDouble();
    final diasValue =
        configuracion[DbConstants.configuracionDiasGraciaMora] as num?;
    final dias = diasValue?.toInt();

    if (nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del negocio es obligatorio.');
    }
    if (nombre.trim().length > maxNombre) {
      throw ArgumentError('El nombre del negocio no puede superar 250 caracteres.');
    }
    if (telefono.trim().length > maxTelefono) {
      throw ArgumentError('El teléfono no puede superar 15 caracteres.');
    }
    if (direccion.trim().length > maxDireccion) {
      throw ArgumentError('La dirección no puede superar 250 caracteres.');
    }
    if (porcentaje == null ||
        !porcentaje.isFinite ||
        porcentaje < 0 ||
        porcentaje > maxPorcentajeMora) {
      throw ArgumentError('La mora debe estar entre 0 y 100 %.');
    }
    if (dias == null ||
        diasValue! % 1 != 0 ||
        dias < 0 ||
        dias > maxDiasGracia) {
      throw ArgumentError('Los días de gracia deben estar entre 0 y 365.');
    }
  }
}
