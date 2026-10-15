# Integración de Flutter con el backend Spring Boot: Validei

**Fecha:** 2026-10-14

| Componente | Detalle |
|---|---|
| Frontend | Flutter 3.47.4 / Dart 3.13.3 en `proyecto-final/` |
| Backend | Spring Boot 4.1.1 en `validei-api/`, **sin modificar** |
| Base de datos | MySQL 8.4 (Docker) |
| Dispositivo | Emulador Pixel 8 (Android 17, API 37) |

Todo lo que se marca como verificado se ejecutó en esta sesión. Las evidencias visuales están en `docs/visual/`.

**Leyenda de estados:**

| Símbolo | Significado |
|---|---|
| ✅V | Implementado y verificado con pruebas automáticas **y** en el emulador con el backend real |
| ✅T | Implementado y verificado con pruebas automáticas (backend simulado) |
| ⛔ | Bloqueado por una decisión funcional pendiente; no se implementó un comportamiento supuesto |

## 1. Matriz Pantalla → Acción → Endpoint → Prueba → Estado

| Pantalla | Acción | Endpoint | Prueba | Estado |
|---|---|---|---|---|
| main / SplashScreen | Restaurar sesión al abrir; con token vigente va a Home, si no a Onboarding | — (almacenamiento seguro) | `auth_flow_test` (Sesión ×2), `session_and_auth_test`; emulador: login → `force-stop` → reabrir → Home | ✅V |
| OnboardingScreen | Skip / Let's Start → Login | — | Prueba integral, paso 1 | ✅V |
| RegisterScreen | REGISTER | `POST /auth/register` | `auth_flow_test` (contraseñas distintas, 409, éxito), prueba integral paso 2 | ✅V |
| RegisterScreen | Show Password | — | `auth_flow_test` | ✅T |
| LoginScreen | LOGIN (200 / 400 / 401 / sin red) | `POST /auth/login` | `auth_flow_test` ×5, prueba integral pasos 3 y 10, login manual en el emulador | ✅V |
| Cualquier pantalla | Token inválido o vencido: borra la sesión y va a Login | Cualquier 🔐 que responda 401 | `api_client_test`, `auth_flow_test` (401 → Login) | ✅T |
| HomeScreen | Feed con las 10 más recientes; carga, vacío, error y reintento; actualizar arrastrando | `GET /blood-requests?page=0&size=10` | `screens_test` (Home ×3), prueba integral paso 7 | ✅V |
| HomeScreen | Find a donor / Requests / I want to donate / See all / avatar | — | `screens_test`, capturas en el emulador | ✅V |
| CustomRequestFeedItem | Details → detalle con el id | `GET /blood-requests/{id}` | `screens_test`, prueba integral paso 8 | ✅V |
| HomeDrawer | Donor Registration / Find Donors / Blood Requests / Profile | — | `screens_test` (menú ×4) | ✅T |
| HomeDrawer | Nombre del usuario real | — (sesión) | `auth_flow_test`, captura en el emulador ("Usuario Integración") | ✅V |
| HomeDrawer | Logout | — (borra el JWT local) | `auth_flow_test`, prueba integral paso 9 | ✅V |
| HomeScreen | Back con el menú abierto lo cierra (antes cerraba la app) | — | Emulador: el primer Back cierra el menú y la app sigue en primer plano (`docs/visual/back_menu.png`) | ✅V |
| FindDonorScreen | Find Donors → publica la solicitud con los valores elegidos | `POST /blood-requests` | `screens_test` ×3 (envío real, validaciones, error 400), prueba integral paso 6 | ✅V |
| AllRequestScreen | Listado, filtro por grupo (`A%2B`), "All" y paginación al llegar al final | `GET /blood-requests?bloodGroup=&page=&size=` | `screens_test` ×2, `api_client_test` (%2B), captura en el emulador | ✅V |
| RequestDetailsScreen | Mostrar los datos reales | `GET /blood-requests/{id}` | `screens_test`, prueba integral paso 8 | ✅V |
| RequestDetailsScreen | Call / Message | — (intents `tel:` y `sms:` con `url_launcher`) | Emulador: abre el marcador y Mensajes con el número (`docs/visual/call_message.png`) | ✅V |
| DonorRegistrationForm | Precargar datos (200) o formulario vacío (404) | `GET /donors/me` | `screens_test`, `domain_services_test`, captura en el emulador | ✅V |
| DonorRegistrationForm | Complete (201 registro / 200 actualización / 400) | `PUT /donors/me` | `screens_test` ×2, `domain_services_test` ×2, prueba integral paso 5 | ✅V |
| ProfileScreen | Datos reales del usuario y del donante | `GET /users/me` + `GET /donors/me` | `screens_test` ×2, prueba integral pasos 4 y 10 | ✅V |
| ProfileScreen | Edit Profile | `PATCH /users/me`, implementado en `UserApiService.updateCurrentUser` y probado | `domain_services_test` (PATCH) | ⛔ D7: sin pantalla de edición (archivo vacío y sin diseño) |
| DonorRegistrationForm | Foto con cámara o galería | — (el backend no la admite) | — | ⛔ D6 |
| ForgotPasswordScreen | SEND | — (el backend no tiene el endpoint) | `session_and_auth_test` (informa "not available") | ⛔ D1: muestra "Password recovery is not available yet." |
| RecoveryScreen / OtpRecoveryScreen | Restablecer contraseña / OTP | — | — | ⛔ D1 y D5, sin cambios |
| "Find a donor" | Buscar donantes de terceros | No existe `GET /donors` | — | ⛔ D3: se conserva la navegación original; el botón publica una solicitud |

## 2. Endpoints integrados

| Método y ruta | Servicio Flutter | Contrato confirmado en |
|---|---|---|
| `POST /api/v1/auth/register` | `AuthServiceApi.register` | `RegisterRequest`: name, email, password |
| `POST /api/v1/auth/login` | `AuthServiceApi.login` | `AuthResponse`: tokenType, accessToken, expiresAt (Instant UTC), user |
| `GET /api/v1/users/me` | `UserApiService.getCurrentUser` | `UserResponse`: id, name, email, phone, gender, location, createdAt |
| `PATCH /api/v1/users/me` | `UserApiService.updateCurrentUser` | `UpdateProfileRequest` parcial |
| `GET /api/v1/donors/me` | `DonorApiService.getMyDonor` (un 404 devuelve `null`) | `DonorResponse` |
| `PUT /api/v1/donors/me` | `DonorApiService.saveMyDonor` (201 = creado, 200 = actualizado) | `DonorRequest` |
| `POST /api/v1/blood-requests` | `BloodRequestApiService.create` | `CreateBloodRequest`; `location` no se envía (el formulario no la tiene) |
| `GET /api/v1/blood-requests` | `BloodRequestApiService.list` | `PageResponse` con content, page, size, totalElements y totalPages |
| `GET /api/v1/blood-requests/{id}` | `BloodRequestApiService.getById` | `BloodRequestResponse` |

**Contrato:** la colección de Postman y el código Java coinciden. No se encontraron diferencias. Los tipos reales que se tuvieron en cuenta:

- `expiresAt` llega como `Instant` con `Z`.
- `createdAt` llega como `LocalDateTime` **sin zona**.
- Las fechas de negocio llegan como `yyyy-MM-dd`.

## 3. Archivos creados

| Archivo | Responsabilidad |
|---|---|
| `lib/src/general/config/api_config.dart` | URL base (`--dart-define=API_BASE_URL`, por defecto `http://10.0.2.2:8080/api/v1`) y timeout de 15 s |
| `lib/src/services/api/api_client.dart` | Única capa HTTP: JSON, cabeceras, Bearer, timeouts, 401 → cierre de sesión, traducción de errores |
| `lib/src/services/api/api_exception.dart` | Errores tipados según el formato `ApiError` del backend; mensajes aptos para el usuario |
| `lib/src/services/session_service.dart` | JWT, expiración y usuario en `flutter_secure_storage`, con copia en memoria |
| `lib/src/services/auth_service_api.dart` | Implementa `AuthRepository` contra la API; sustituye a Firebase |
| `lib/src/services/user_api_service.dart` | Perfil |
| `lib/src/services/donor_api_service.dart` | Donantes |
| `lib/src/services/blood_request_api_service.dart` | Solicitudes de sangre |
| `lib/src/services/app_services.dart` | Punto único donde se crean los servicios (las pruebas lo reemplazan) |
| `lib/src/models/user_profile.dart`, `gender.dart`, `donor.dart`, `blood_request.dart`, `page_result.dart` | Modelos con `fromJson` y `toJson` |
| `lib/src/general/utils/date_format.dart` | `yyyy-MM-dd` sin conversión de zona horaria, "10 February 2024", "d-m-yyyy" y "2 minute ago" |
| `lib/src/general/utils/form_rules.dart` | Validaciones iguales a las del backend (teléfono, 1 a 10 bolsas, longitudes) |
| `lib/src/general/utils/phone_actions.dart` | Intents `tel:` y `sms:` |
| `lib/src/screens/views/components/widgets/request_list_status.dart` | Estados de carga, vacío y error de las listas (único widget visual nuevo; solo aparece cuando no hay tarjetas) |
| `android/app/src/debug/res/xml/network_security_config.xml` | HTTP sin cifrar **solo en debug** y solo para 10.0.2.2, localhost y 127.0.0.1 |
| `test/support/fake_backend.dart`, `test/support/widget_helpers.dart`, `test/flutter_test_config.dart` | Backend simulado, ayudantes y fuentes reales para los tests |
| `test/services/*.dart` (3), `test/widgets/*.dart` (2) | Pruebas unitarias y de widgets |
| `integration_test/app_flow_test.dart` | Prueba integral en el emulador contra el backend real |
| `docs/visual/*.png` | Capturas antes y después, Call/Message y restauración de sesión |

## 4. Archivos modificados

Todos los cambios son **solo de lógica, parámetros y navegación**. Ningún estilo, color, tamaño, espaciado, imagen ni orden de widgets cambió.

| Archivo | Cambio |
|---|---|
| `lib/main.dart` (provisional, no es del profesor) | Restaura la sesión antes de `runApp`; ruta inicial Splash; `navigatorKey` y `scaffoldMessengerKey` globales; redirección a Login por 401; `appRoutes` |
| `repositories/auth_repository.dart` | Añadidos `sendPasswordResetEmail` (ya existía en la clase Firebase) y `logout` |
| `onboarding/splash_screen.dart` | Tras 3 s va a Home si hay sesión, o a Onboarding si no; cancela el temporizador |
| `auth/login_screen.dart` | Servicio API; navega a Home al iniciar sesión (antes se quedaba cargando); bloquea doble envío |
| `auth/register_screen.dart` | Servicio API; valida que las contraseñas coincidan; Show Password funcional; contraseña sin `trim()` (coincide con el login); vuelve a Login con `pop` |
| `auth/forgot_password_screen.dart` | Servicio API (informa que aún no está disponible); bloquea doble envío; quitado un import sin uso |
| `components/widgets/home_drawer.dart` | Nombre real desde la sesión; Logout funcional (se conserva el `TextButton` por su relleno visual) |
| `components/widgets/custom_drawer_item.dart` | Navegación activada (estaba comentada); cierra el menú antes de navegar; `onTap` opcional |
| `home/screens/home_screen.dart` | Feed real, `RefreshIndicator`, recarga tras crear una solicitud, `PopScope` para el Back con el menú abierto. *Nota: se formateó con `dart format` (solo espacios)* |
| `home/widgets/request_feed_item.dart` | Recibe `BloodRequest`; mismos widgets y estilos; Details envía el id como argumento |
| `all_requests/screens/all_request_screen.dart` | Lista dinámica, filtro, paginación y actualización |
| `all_request_details/screens/request_details_screen.dart` | Consulta por id; Call y Message |
| `all_request_details/widgets/custom_call_btn.dart`, `components/widgets/custom_red_btn.dart` | `onTap` opcional con `GestureDetector` (sin efecto visual) |
| `components/widgets/custom_blood_group_box.dart`, `custom_gender_box.dart`, `custom_blood_filter_box.dart` | `onChanged` opcional (y `initialValue` en el grupo sanguíneo) con la misma preselección visual |
| `components/widgets/find_donor_date_picker.dart` | **Corregido el *null check* al cancelar**; `onChanged`, rango y fecha inicial; mismo formato visible `d-m-yyyy` |
| `components/widgets/custom_form_textfield.dart` | `keyboardType` opcional |
| `find_donor/screens/find_donor_screen.dart` | Controladores, validación, envío real, bloqueo de doble envío, mensajes |
| `donor_registration/screens/donor_registration_screen.dart` | De `StatelessWidget` a `StatefulWidget`: precarga, validación, `PUT` y mensajes |
| `profile/screens/profile_screen.dart` | De `StatelessWidget` a `StatefulWidget` con datos reales |
| `android/app/src/main/AndroidManifest.xml` | Permiso `INTERNET`; `<queries>` para los intents `DIAL` y `SENDTO` |
| `android/app/src/debug/AndroidManifest.xml` | `networkSecurityConfig` (solo debug) |
| `pubspec.yaml` | +`http`, +`flutter_secure_storage`, +`url_launcher`, +`integration_test` (dev); −Firebase |
| `analysis_options.yaml` | Excluye `backups/**` |
| `test/widget_test.dart` | Usa el backend simulado y el flujo con Splash |

**Firebase:** `lib/src/services/auth_service_firebase.dart` (del profesor) se **movió** a `backups/firebase/`, de modo que se conserva y el cambio es reversible. Se retiraron `firebase_core`, `firebase_auth` y `cloud_firestore`. Ya no hay ninguna referencia a Firebase en `lib/` y queda un único sistema de autenticación.

## 5. Dependencias

| Paquete | Versión | Motivo |
|---|---|---|
| `http` | ^1.6.0 | Cliente HTTP; más simple que Dio e incluye `MockClient` para los tests |
| `flutter_secure_storage` | ^11.2.0 | JWT cifrado con el Keystore de Android (pedido explícito; no se usa SharedPreferences) |
| `url_launcher` | ^6.3.3 | Botones Call y Message |
| `integration_test` | SDK (dev) | Prueba integral en el emulador |
| ~~firebase_core / firebase_auth / cloud_firestore~~ | Retiradas | Sustituidas por la API. Con esto desaparece también el aviso de compilación de Kotlin (KGP) |

## 6. Manejo de errores y sesión

| Situación | Comportamiento |
|---|---|
| 400 | Muestra el primer mensaje de `fields[]` del backend |
| 401 `INVALID_CREDENTIALS` (login) | Muestra "Correo o contraseña incorrectos" y **no** toca la sesión |
| 401 con token | Borra el token, vuelve a Login (una sola vez aunque fallen varias peticiones) y avisa con un SnackBar |
| Token vencido localmente | No se envía la petición; mismo flujo que el 401. Se aplica un margen de 30 s |
| 403 | Mensaje genérico; **no** cierra la sesión |
| 404 | Mensaje del backend. En `GET /donors/me` significa "aún no es donante" |
| 409 | Mensaje del backend (por ejemplo, "El correo ya esta registrado") |
| 5xx | "The server had a problem…", sin detalles del servidor |
| Sin conexión, timeout o respuesta que no es JSON | Mensajes propios; la sesión **no** se borra |

Otros puntos:

- **Sin refresh token**, porque el backend no tiene ese endpoint.
- **Sin logs de secretos:** se revisaron la salida de `flutter run`, la de la prueba integral y `logcat`. Las únicas coincidencias en `logcat` son registros de `adbd` de los comandos `adb input text` usados para la prueba manual, no de la app.

## 7. Pruebas ejecutadas y resultados reales

| Comando | Resultado |
|---|---|
| `flutter pub get` | OK |
| `flutter analyze` | **0 errores, 0 avisos**. 7 sugerencias de estilo, todas en código original del profesor (antes de esta fase eran 11) |
| `flutter test` | **60 de 60 superadas** |
| `flutter build apk --debug` | ✓ `app-debug.apk` |
| `flutter run -d emulator-5554` | La app se instala y se abre (Splash → Onboarding sin sesión) |
| `flutter test integration_test/app_flow_test.dart -d emulator-5554` | **1 de 1 superada (23 s)** contra el backend y MySQL reales |

### Desglose de los 60 tests

| Archivo | Tests | Cubre |
|---|---|---|
| `services/api_client_test.dart` | 11 | Bearer, JSON, `%2B`, 400 / 401 / 403 / 404 / 409 / 500, red, timeout, JSON inválido, sin sesión |
| `services/session_and_auth_test.dart` | 9 | Guardar y restaurar, sesión vencida, margen, `clear`, login correcto e incorrecto, registro (éxito / 409 / 400), logout, recuperación no disponible |
| `services/domain_services_test.dart` | 11 | Perfil (GET, PATCH, 401), donante (404 → null, 201/200, 400), solicitudes (crear, listar/filtrar/paginar, vacía, detalle), fechas |
| `widgets/auth_flow_test.dart` | 13 | Login (validación, éxito → Home, 401, sin red, doble toque), Register (contraseñas distintas, 409, éxito → Login, Show Password), Splash con y sin sesión, Logout, 401 → Login |
| `widgets/screens_test.dart` | 15 | Home (carga → datos, vacío, error y reintento, Details con id, menú ×4), filtro y paginación, formulario de solicitud (envío, validaciones, 400), **calendario cancelado sin excepción**, donante (201 / precarga y 200), perfil (datos reales / guiones) |
| `widget_test.dart` | 1 | Arranque de la app |

### Flujo de aceptación (prueba integral automatizada en el Pixel 8)

1. Abrir Validei.
2. Registrar un usuario.
3. Iniciar sesión.
4. Consultar el perfil.
5. Registrar los datos de donante.
6. Crear una solicitud.
7. Verla en el feed.
8. Abrir su detalle.
9. Cerrar sesión.
10. Volver a iniciar sesión y comprobar que el perfil muestra los datos de donante (grupo O-, ubicación Santiago, RD).

### Comprobación en MySQL tras la prueba integral

Usuario `it.1792019865720@validei.test`:

| Tabla | Datos persistidos |
|---|---|
| `users` | id 8, hash `$2a$12$…`, nombre en UTF-8 correcto (`…C3B36E` = "ón") |
| `donors` | O-, Santiago, RD, `last_donation_date` = 2026-10-14 |
| `blood_requests` | id 4: AB+, 2 bolsas, contactos normalizados, `patient_gender` = MALE, `need_before` = 2026-10-14, `location` = NULL, `others` = "Prueba integral" |

### Comprobaciones manuales en el emulador

| Comprobación | Resultado |
|---|---|
| Login desde la UI | Abre Home con el feed real |
| `am force-stop` y reabrir | **Sesión restaurada**: entra directamente en Home (`docs/visual/restauracion_sesion.png`) |
| Call | Abre el marcador con "+1 809-224-9304", sin llamar automáticamente |
| Message | Abre Google Messages con ese número |

## 8. Errores corregidos

1. **Calendario:** cancelar lanzaba `Null check operator used on a null value` (`find_donor_date_picker.dart:26`). Ahora se conserva la fecha anterior.
2. **Login:** tras un login correcto no se navegaba a ninguna parte (esperaba un `StreamBuilder` inexistente).
3. **Registro:** no se validaba que las contraseñas coincidieran, y *Show Password* no hacía nada.
4. **Contraseña inconsistente:** el registro aplicaba `trim()` y el login no, así que una contraseña con espacios no podía usarse.
5. **Menú lateral:** la navegación estaba comentada y Logout nunca se ejecutaba, porque el `InkWell` interno absorbía el toque.
6. **Botones inertes:** Find Donors, Complete, Call y Message no tenían acción.
7. **Formularios sin datos:** no entregaban sus valores (sin controladores ni callbacks).
8. **Firebase:** Login, Register y Forgot fallaban con `[core/no-app]`.
9. **Back con el menú abierto:** cerraba la app (ver §9).
10. **SnackBars de validación encolados:** el usuario veía el error anterior durante 4 s. Ahora se reemplaza el mensaje.
11. **SnackBar arrastrado:** el mensaje de confirmación de la pantalla anterior **tapaba el botón principal** del formulario siguiente (lo detectó la prueba integral). Ahora se descarta al abrir el formulario.

## 9. Cambios de navegación

| Cambio | Antes | Ahora |
|---|---|---|
| Ruta inicial | Home (provisional) | Splash, con el flujo original del profesor |
| Login correcto | No navegaba | `pushNamedAndRemoveUntil(Home)`: el usuario no vuelve al login con Back |
| Registro correcto / "Login Here" | Acumulaba pantallas de Login | `pop` hasta Login |
| Logout y sesión vencida | — | Login, borrando el historial |
| Find Donors y Complete | Sin acción | Vuelven a Home tras guardar; el feed se recarga |
| Menú lateral | Sin acción | Cierra el menú y abre la pantalla |
| Details | Sin solicitud asociada | Envía el `id` como argumento de la ruta |

**Back con el menú abierto:** se implementó con `PopScope` y `onDrawerChanged`. Se verificó en el emulador: el primer Back cierra el menú y la app sigue en primer plano; el segundo Back sale de Home, que es la pantalla raíz, como es normal en Android.

## 10. Preservación visual

Se tomaron capturas en el mismo Pixel 8 **antes** de la integración (con los datos fijos originales) y **después** (con datos reales), recorriendo las mismas pantallas: Home, menú, formulario de solicitud (3 desplazamientos), Requests, formulario de donante (2), Detalle y Perfil.

- **Archivos:** `docs/visual/antes_1.png`, `antes_2.png`, `despues_1.png` y `despues_2.png`.
- **Comparación:** colores, Poppins, iconos, tarjetas, bordes, sombras, espaciados y distribución son idénticos. Solo cambian los textos de datos.
- **Valores ausentes:** donde el backend no devuelve un dato (ubicación de la solicitud, género no informado), se muestra "—" en lugar de un valor inventado.
- **Pantallas de autenticación:** no había captura "antes", porque fallaban por Firebase. Su código solo cambió en lógica (servicio, validador y navegación).
- **Observación:** con grupos de tres caracteres ("AB+") la insignia de la tarjeta queda más ajustada que con "A+", el valor fijo original. El texto no se recorta y no se modificó el tamaño.

## 11. Funcionalidades bloqueadas o pendientes

| Tema | Estado | Decisión pendiente |
|---|---|---|
| Edit Profile | La API y el servicio existen; falta el diseño de la pantalla | D7 (profesor) |
| Foto del donante | El backend no la admite | D6 |
| Recuperación de contraseña y OTP | El backend no tiene endpoints (requieren SMTP o SMS) | D1 / D5 |
| Búsqueda de donantes | No existe el endpoint; "Find a donor" publica una solicitud | D3 |
| Ubicación de la solicitud | El formulario no la pide; se muestra "—" | D4 |
| Zona horaria de `createdAt` | El backend envía hora local sin zona. Funciona con el móvil y el servidor en la misma zona (verificado: "55 minute ago"). Recomendación: enviar UTC en el backend | Riesgo menor |
| Mensajes de error mixtos | La validación local está en inglés (como la UI del profesor); los mensajes del servidor llegan en español | Decidir el idioma |
| Datos de prueba | Quedan usuarios `@validei.test` en MySQL (se pueden borrar en cascada, ver el reporte del backend) | — |

## 12. Cómo ejecutar Flutter y Spring Boot juntos

1. **MySQL** (volumen existente):

   ```bash
   cd validei-api && docker compose up -d
   ```

2. **Backend:**

   ```bash
   cd validei-api && mvnw.cmd spring-boot:run
   ```

   Lee `.env`. Comprobación rápida: `curl http://localhost:8080/api/v1/health`.

3. **Emulador:** arrancar Pixel_8 desde Device Manager. Si se queda en "Installing…", hacer *Cold Boot*.

4. **App**, desde `proyecto-final/`:

   ```bash
   flutter pub get
   flutter run -d emulator-5554
   ```

   Para un dispositivo físico, usar la IP del PC:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080/api/v1
   ```

   En ese caso también hay que añadir esa IP a `network_security_config.xml`, solo en debug.

5. **Pruebas:**

   ```bash
   flutter test
   flutter test integration_test/app_flow_test.dart -d emulator-5554
   ```

   La segunda requiere el backend en marcha.
