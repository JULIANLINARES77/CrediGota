# GotaControl

Aplicacion Flutter para gestion local de prestamos en Android.

## Dependencias

Requiere Flutter 3.44.8 y Dart 3.12.2. Instalar los paquetes con `flutter pub get`.
La lista directa y los comandos estan en [DEPENDENCIAS.txt](DEPENDENCIAS.txt).

## Plataformas

Android usa SQLite local para conservar clientes, préstamos y pagos entre sesiones.
La compilación Web funciona, pero el adaptador SQLite de Android no está conectado
a almacenamiento de navegador. En Web se mostrará un aviso de base de datos no
disponible; no usar la versión Web para registrar operaciones reales.

Para probar la interfaz web sin persistencia, aún no hay un modo mock separado.

## APK Android de prueba

En PowerShell, si `JAVA_HOME` apunta a una carpeta inexistente, usa el JDK incluido
con Android Studio durante la compilación:

```powershell
$env:JAVA_HOME = "$env:ProgramFiles\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Actualmente se
firma con el certificado debug de Android: sirve para pruebas/sideload, pero antes
de distribuirlo a clientes hay que configurar una clave release propia. Conserva
`build/symbols` para poder diagnosticar errores de esta compilación ofuscada.

## Docker

```sh
docker build -t gotacontrol-web .
docker run --rm -e PORT=10000 -p 8080:10000 gotacontrol-web
```

Abrir `http://localhost:8080`.

### Render

1. Crear un **Web Service** y conectar el repositorio `JULIANLINARES77/CrediGota`.
2. Elegir **Docker** como runtime y dejar `Dockerfile` y el contexto de build en la raiz.
3. Render construira la imagen y proporcionara `PORT` (por defecto `10000`); Nginx escucha ese puerto.
4. Desplegar. El dominio `onrender.com` puede usarse para la demostracion; se puede asociar un dominio propio desde Render.

El contenedor sirve la versión Web, que actualmente no tiene backend ni adaptador
de base de datos para navegador. No usarla para guardar información real.
