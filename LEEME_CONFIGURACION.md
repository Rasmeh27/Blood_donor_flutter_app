# Validei - fuentes del profesor organizadas

Este archivo contiene las 40 fuentes Dart y todos los assets entregados, sin modificar
ningun archivo Dart original. Se agrega unicamente `lib/main.dart` de arranque provisional
para previsualizar el Home, y este README.

NO incluye las carpetas Android/Gradle, el backend, MySQL ni configuracion Firebase.
NO se ha compilado ni ejecutado: el entorno de generacion no tiene Flutter instalado.
NO es una aplicacion final funcional.

## Instalacion en Windows
1. Instala/configura Flutter y Android Studio. Verifica `flutter doctor -v`.
2. Desde PowerShell en la carpeta que contendra el proyecto:
   flutter create --platforms=android --project-name proyecto_laboratorio_intec validei_flutter
3. Descomprime este ZIP y copia su contenido a `validei_flutter/`,
   reemplazando `lib/main.dart` y `pubspec.yaml` generados.
4. `cd validei_flutter`
5. Verifica que `pubspec.yaml` tenga `name: proyecto_laboratorio_intec`.
6. `flutter pub get`
7. Elimina el archivo de test de ejemplo generado `test/widget_test.dart`,
   ya que utiliza la clase `MyApp`, no incluida en el codigo del profesor.
8. `flutter analyze`
9. `flutter devices`
10. `flutter run`

## Avisos
- `lib/main.dart` abre HomeScreen provisionalmente porque el origen no incluye la
  configuracion Firebase ni un backend Java. No se ha modificado ninguna pantalla.
- Login/registro de Firebase no estan configurados para funcionar sin un proyecto Firebase;
  al implementarse Spring Boot + MySQL se debera sustituir el servicio de autenticacion.
- Algunos botones no tienen `onTap` real y varios formularios son solo maqueta.
- Hay un date picker que falla si el usuario cancela y hay un OTP aun no implementado.
- En los materiales recibidos no hay una carpeta llamada Validei.
- Se recomienda registrar la familia Poppins en `pubspec.yaml` antes de validar pixel a pixel:

    fonts:
      - family: Poppins
        fonts:
          - asset: assets/fonts/Poppins-Regular.ttf
            weight: 400
          - asset: assets/fonts/Poppins-SemiBold.ttf
            weight: 600
          - asset: assets/fonts/Poppins-Bold.ttf
            weight: 700
          - asset: assets/fonts/Poppins-Black.ttf
            weight: 900
      - family: PoppinsBold
        fonts:
          - asset: assets/fonts/Poppins-Bold.ttf

  La seccion `fonts:` debe quedar al mismo nivel que `assets:` dentro de `flutter:`.
