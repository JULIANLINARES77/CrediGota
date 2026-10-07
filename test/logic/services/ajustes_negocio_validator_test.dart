import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/core/constants/db_constants.dart';
import 'package:flutter_prestamos/logic/services/ajustes_negocio_validator.dart';
import 'package:flutter_prestamos/logic/services/local_backup_service.dart';

Map<String, Object?> _configuracion({
  Object? nombre = 'Negocio local',
  Object? telefono = '',
  Object? direccion = '',
  Object? mora = 10,
  Object? dias = 3,
}) => {
  DbConstants.configuracionNombreNegocio: nombre,
  DbConstants.configuracionTelefonoNegocio: telefono,
  DbConstants.configuracionDireccionNegocio: direccion,
  DbConstants.configuracionPorcentajeMora: mora,
  DbConstants.configuracionDiasGraciaMora: dias,
};

void main() {
  test('acepta límites máximos y teléfono/dirección opcionales', () {
    expect(
      () => AjustesNegocioValidator.validar(
        _configuracion(
          nombre: 'N' * 250,
          telefono: '1' * 15,
          direccion: 'D' * 250,
          mora: 100,
          dias: 365,
        ),
      ),
      returnsNormally,
    );
    expect(
      () => AjustesNegocioValidator.validar(
        _configuracion(telefono: '', direccion: '', mora: 0, dias: 0),
      ),
      returnsNormally,
    );
  });

  test('rechaza nombre vacío y textos que superan sus límites', () {
    expect(
      () => AjustesNegocioValidator.validar(_configuracion(nombre: '  ')),
      throwsArgumentError,
    );
    expect(
      () => AjustesNegocioValidator.validar(_configuracion(nombre: 'N' * 251)),
      throwsArgumentError,
    );
    expect(
      () => AjustesNegocioValidator.validar(_configuracion(telefono: '1' * 16)),
      throwsArgumentError,
    );
    expect(
      () =>
          AjustesNegocioValidator.validar(_configuracion(direccion: 'D' * 251)),
      throwsArgumentError,
    );
  });

  test('rechaza mora fuera de rango y días no enteros o fuera de rango', () {
    for (final porcentaje in [-0.1, 100.1, double.nan, double.infinity]) {
      expect(
        () => AjustesNegocioValidator.validar(_configuracion(mora: porcentaje)),
        throwsArgumentError,
      );
    }
    for (final dias in [-1, 366, 1.5]) {
      expect(
        () => AjustesNegocioValidator.validar(_configuracion(dias: dias)),
        throwsArgumentError,
      );
    }
  });

  test('lee estado local de respaldo y tolera una frecuencia desconocida', () {
    final status = LocalBackupStatus.fromMap({
      'folderUri': 'content://documents/tree/primary%3ADocuments',
      'folderName': 'Documents',
      'automaticDestination': false,
      'frequency': 'fortnightly',
      'lastSuccess': 1791300000000,
      'lastFile': 'GotaControl_auto_latest.db',
      'lastError': null,
    });

    expect(status.hasDestination, isTrue);
    expect(status.automaticDestination, isFalse);
    expect(status.frequency, BackupFrequency.fortnightly);
    expect(status.lastSuccess, isNotNull);
    expect(
      LocalBackupStatus.fromMap(const {}).frequency,
      BackupFrequency.daily,
    );
    expect(
      LocalBackupStatus.fromMap({
        'folderUri': 'mediastore:downloads/gotacontrol',
        'folderName': 'Descargas/GotaControl',
        'automaticDestination': true,
      }).automaticDestination,
      isTrue,
    );
  });
}
