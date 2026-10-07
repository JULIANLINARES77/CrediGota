import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/database/database_helper.dart';
import '../providers/gota_provider.dart';

enum BackupFrequency {
  daily('daily', 'Diariamente', 1),
  weekly('weekly', 'Semanalmente', 7),
  fortnightly('fortnightly', 'Cada 15 días', 15);

  const BackupFrequency(this.value, this.label, this.intervalDays);

  final String value;
  final String label;
  final int intervalDays;

  static BackupFrequency fromValue(Object? value) => BackupFrequency.values
      .firstWhere((frequency) => frequency.value == value, orElse: () => daily);
}

class LocalBackupStatus {
  const LocalBackupStatus({
    required this.folderUri,
    required this.folderName,
    required this.automaticDestination,
    required this.frequency,
    required this.lastSuccess,
    required this.lastFile,
    required this.lastError,
  });

  final String? folderUri;
  final String? folderName;
  final bool automaticDestination;
  final BackupFrequency frequency;
  final DateTime? lastSuccess;
  final String? lastFile;
  final String? lastError;

  bool get hasDestination => folderUri != null;

  factory LocalBackupStatus.fromMap(Map<Object?, Object?> values) {
    final timestamp = (values['lastSuccess'] as num?)?.toInt() ?? 0;
    return LocalBackupStatus(
      folderUri: values['folderUri'] as String?,
      folderName: values['folderName'] as String?,
      automaticDestination: values['automaticDestination'] as bool? ?? false,
      frequency: BackupFrequency.fromValue(values['frequency']),
      lastSuccess: timestamp <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp),
      lastFile: values['lastFile'] as String?,
      lastError: values['lastError'] as String?,
    );
  }
}

class ImportableBackup {
  const ImportableBackup({
    required this.selectedPath,
    required this.version,
    required this.sizeBytes,
  });

  final String selectedPath;
  final int version;
  final int sizeBytes;
}

class LocalBackupService {
  LocalBackupService._();

  static const MethodChannel _channel = MethodChannel(
    'gotacontrol/local_backup',
  );
  static final instance = LocalBackupService._();

  Future<LocalBackupStatus> status() async {
    _requireAndroid();
    final values = await _channel.invokeMapMethod<Object?, Object?>(
      'getBackupStatus',
    );
    if (values == null) {
      throw StateError('Android no devolvió el estado de los respaldos.');
    }
    return LocalBackupStatus.fromMap(values);
  }

  Future<bool> restoreLatestBackupIfMissing() async {
    _requireAndroid();
    final values = await _channel.invokeMapMethod<Object?, Object?>(
      'restoreLatestBackupIfMissing',
      {'databasePath': await DatabaseHelper.instance.databaseFilePath},
    );
    if (values == null || values['restored'] is! bool) {
      throw StateError('Android no confirmó la recuperación del respaldo.');
    }
    switch (values['reason']) {
      case 'folder_selection_cancelled':
        throw StateError(
          'Se canceló el acceso a la carpeta. No se pudo buscar el respaldo '
          'anterior; puedes volver a intentarlo desde Ajustes.',
        );
      case 'no_backup_in_selected_folder':
        throw StateError(
          'No se encontró una copia válida en la carpeta seleccionada. '
          'Tus datos locales no se reemplazaron.',
        );
      case 'only_empty_backups':
        throw StateError(
          'Las copias encontradas no contienen registros de clientes, '
          'préstamos, cuotas ni pagos.',
        );
    }
    return values['restored'] as bool;
  }

  Future<LocalBackupStatus?> selectFolder(BackupFrequency frequency) async {
    _requireAndroid();
    final selected = await _channel.invokeMapMethod<Object?, Object?>(
      'selectBackupFolder',
    );
    if (selected == null) return null;
    await configureSchedule(frequency);
    return status();
  }

  Future<void> configureSchedule(BackupFrequency frequency) async {
    _requireAndroid();
    await _channel.invokeMethod<void>('configureSchedule', {
      'frequency': frequency.value,
      'databasePath': await DatabaseHelper.instance.databaseFilePath,
    });
  }

  Future<void> cancelSchedule() async {
    _requireAndroid();
    await _channel.invokeMethod<void>('cancelSchedule');
  }

  Future<String> runBackupNow() async {
    _requireAndroid();
    final filename = await _channel.invokeMethod<String>('runBackupNow', {
      'databasePath': await DatabaseHelper.instance.databaseFilePath,
    });
    if (filename == null || filename.isEmpty) {
      throw StateError('Android no confirmó la creación del respaldo.');
    }
    return filename;
  }

  Future<ImportableBackup?> selectImportBackup() async {
    _requireAndroid();
    final values = await _channel.invokeMapMethod<Object?, Object?>(
      'selectImportBackup',
    );
    if (values == null) return null;
    final selectedPath = values['selectedPath'] as String?;
    final version = (values['version'] as num?)?.toInt();
    final sizeBytes = (values['sizeBytes'] as num?)?.toInt();
    if (selectedPath == null || version == null || sizeBytes == null) {
      throw StateError('Android devolvió información incompleta del respaldo.');
    }
    return ImportableBackup(
      selectedPath: selectedPath,
      version: version,
      sizeBytes: sizeBytes,
    );
  }

  Future<void> discardImportBackup(ImportableBackup backup) async {
    _requireAndroid();
    await _channel.invokeMethod<void>('discardImportBackup', {
      'selectedPath': backup.selectedPath,
    });
  }

  Future<void> restoreBackup(
    ImportableBackup backup,
    GotaProvider provider,
  ) async {
    _requireAndroid();
    await DatabaseHelper.instance.close();
    try {
      await _channel.invokeMethod<void>('restoreBackup', {
        'selectedPath': backup.selectedPath,
        'databasePath': await DatabaseHelper.instance.databaseFilePath,
      });
    } on Object {
      await provider.cargarDatos();
      rethrow;
    }
    await provider.cargarDatos();
    if (provider.errorCarga != null) {
      throw StateError(
        'La base restaurada no se pudo cargar: ${provider.errorCarga}',
      );
    }
  }

  static void _requireAndroid() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Los respaldos del dispositivo solo funcionan en Android.',
      );
    }
  }
}
