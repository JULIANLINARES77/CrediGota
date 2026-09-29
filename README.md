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
docker run --rm -p 8080:80 gotacontrol-web
```

Abrir `http://localhost:8080`. Para un dominio publico, publicar detras de un
proxy inverso con HTTPS.
