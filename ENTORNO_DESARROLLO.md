# Validei - Entorno de desarrollo (verificado 2026-10-14)

## Versiones verificadas
| Herramienta | Version | Estado |
|---|---|---|
| Flutter / Dart | 3.47.4 / 3.13.3 | OK |
| JDK | Microsoft OpenJDK 17.0.20.1 (`JAVA_HOME`) | OK |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk`, platform android-37.0, build-tools 36.0.0 | OK |
| Gradle / AGP / Kotlin | 9.3.1 / 9.1.0 / 2.4.0 (generados por `flutter create`) | OK con JDK 17 |
| Emulador | Pixel_8 y Pixel_8_B (API 37) | Pixel_8 probado OK |

## Ejecutar la app
```
flutter pub get
flutter analyze
flutter run -d emulator-5554
```

## Android Studio
1. File > Open > seleccionar la carpeta `proyecto-final` (la raiz, no `android/`).
2. Settings > Plugins: instalar/activar **Flutter** (instala **Dart** automaticamente).
3. Settings > Languages & Frameworks > Flutter > Flutter SDK path:
   `C:\Users\lherasme\Documents\flutter`
4. Settings > Languages & Frameworks > Dart: marcar *Enable Dart support* y SDK path
   `C:\Users\lherasme\Documents\flutter\bin\cache\dart-sdk`.
5. Settings > Build, Execution, Deployment > Build Tools > Gradle > Gradle JDK: JDK 17
   (o `JAVA_HOME`) si se abre la carpeta `android/` por separado.
6. Elegir el dispositivo `Pixel 8` en la barra superior y pulsar Run (`main.dart`).

## Emulador: problema conocido
Si `flutter run` se queda en "Installing ...apk" (o `adb install` en "Performing Streamed Install"),
el snapshot de Quick Boot esta desfasado (reloj del emulador incorrecto). Solucion:
Device Manager > menu del AVD > **Cold Boot Now**, o:
```
%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe -avd Pixel_8 -no-snapshot-load
```

## Firebase (bloqueado, pendiente)
- No hay `google-services.json`, plugin `com.google.gms.google-services` ni `Firebase.initializeApp()`.
- La app compila y abre `HomeScreen` sin Firebase.
- Login, registro y recuperacion crean `AuthServiceFirebase()`, que accede a `FirebaseAuth.instance`
  al construirse: al abrir esas pantallas se lanzara `[core/no-app] No Firebase App '[DEFAULT]'`.
- Opciones: obtener las credenciales originales del profesor (applicationId actual:
  `com.example.proyecto_laboratorio_intec`) o sustituir `AuthRepository` por una implementacion REST
  contra Spring Boot.

## Backend Spring Boot + MySQL (sin implementar)
Disponible: JDK 17, IntelliJ IDEA Ultimate 2026.2.2 (plugins Spring, Spring Boot Initializr,
Maven y Database Tools), Maven 3 empaquetado en IntelliJ, MySQL Workbench 26.7, Docker Desktop 4.91.
No instalado: **MySQL Server** y Maven global (no es necesario: usar el wrapper `mvnw`).

Pasos sugeridos:
1. Instalar MySQL Server 8.x (MySQL Installer, solo "Server Only") **o** usar Docker:
   `docker run -d --name validei-mysql -e MYSQL_ROOT_PASSWORD=<elige> -e MYSQL_DATABASE=validei -p 3306:3306 mysql:8.4`
2. IntelliJ > New Project > Spring Boot: Java 17, Maven, Group `edu.intec`, Artifact `validei-backend`,
   dependencias Spring Web, Spring Data JPA, MySQL Driver, Validation, (Lombok opcional).
   Ubicarlo en una carpeta hermana (p. ej. `appmobiles\validei-backend`), fuera del proyecto Flutter.
3. `application.properties`: `spring.datasource.url=jdbc:mysql://localhost:3306/validei`, usuario y
   contrasena via variables de entorno.
4. Desde el emulador Android el backend local se accede como `http://10.0.2.2:8080`
   (requiere permitir trafico HTTP en debug o usar HTTPS).
