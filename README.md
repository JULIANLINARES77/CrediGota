# GotaControl

Aplicacion Flutter de demostracion para gestion de prestamos.

## Dependencias

Requiere Flutter 3.44.8 y Dart 3.12.2. Instalar los paquetes con `flutter pub get`.
La lista directa y los comandos estan en [DEPENDENCIAS.txt](DEPENDENCIAS.txt).

## Probar en web

```sh
flutter run -d chrome
```

Los datos de esta interfaz son de demostracion y se guardan en memoria.

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

Esta web es una demostracion con datos mock en memoria. No almacenar datos reales de clientes o pagos en este despliegue.
