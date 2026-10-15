# Validei: reporte final de validación

**Fecha:** 2026-10-14
**Alcance:** fases A a G, sobre la integración Flutter ↔ Spring Boot ↔ MySQL ya existente.

Todos los resultados de este documento proceden de ejecuciones reales en esta sesión. Las capturas están en `docs/visual/`.

**Leyenda de estados:**

| Símbolo | Significado |
|---|---|
| ✅V | Implementado y verificado con pruebas automáticas **y** en el emulador Pixel 8 contra el backend real |
| ✅T | Implementado y verificado con pruebas automáticas |
| ⛔ | Pendiente o fuera de alcance; no se implementó un comportamiento supuesto |

## 0. Estado inicial verificado

| Componente | Comprobación al inicio |
|---|---|
| Backend | `mvnw.cmd test`: **63/63** |
| Flutter | `flutter test`: **60/60**; `flutter analyze`: 0 errores (7 sugerencias, todas del código original) |
| Base de datos | `validei_db` en versión Flyway **V4** |
| Zona horaria del equipo | *SA Western Standard Time* (UTC−4, sin horario de verano) |

## 1. Funcionalidades implementadas

| Fase | Funcionalidad | Estado |
|---|---|---|
| **A** | Recuperación de contraseña por correo con OTP: solicitar, verificar y restablecer. Pantallas originales Forgot Password → OTP → Recovery. Mailpit para desarrollo | ✅V |
| **B** | **Edit Profile** (el archivo estaba vacío): nombre, teléfono, ubicación y género, que son los campos de `UpdateProfileRequest`. Precarga, validación, confirmación, recarga de Profile y bloqueo de doble envío | ✅V |
| **C** | **Búsqueda real de donantes**, paginada y filtrada por grupo y ubicación. Consentimiento explícito (desactivado por defecto), sin teléfonos ni correos, solo para usuarios autenticados. Pantalla de resultados nueva | ✅V |
| **D** | La **ubicación de la solicitud** se toma del perfil autenticado (`users.location` y, si falta, la del donante). Si no hay ninguna, queda nula y se avisa al usuario | ✅V |
| **E** | **Foto del donante**: cámara o galería, validación de formato y tamaño, vista previa, almacenamiento en disco y avatar en Profile | ✅V |
| **F** | **Fechas:** los timestamps se transmiten como `Instant` en UTC (ISO 8601 con `Z`); las fechas de calendario siguen como `LocalDate` sin conversión. Los datos históricos no se modificaron | ✅V |

### Fase A: recuperación de contraseña

**Flujo**

1. **Forgot Password (SEND)** llama a `POST /auth/password/forgot`. Responde siempre 202 con el mismo mensaje, exista o no la cuenta.
2. **OTP (Verify)** llama a `POST /auth/password/verify` con correo y código.
3. **Recovery (RESET PASSWORD)** llama a `POST /auth/password/reset` con correo, código y nueva contraseña, y vuelve al Login.

**Seguridad aplicada**

| Requisito | Cómo se cumple |
|---|---|
| Código seguro | 6 dígitos generados con `SecureRandom` |
| Nunca en texto plano | Solo se guarda el hash BCrypt |
| No se devuelve en HTTP | Solo viaja por correo |
| Expiración | 10 minutos |
| Intentos | 5 fallidos invalidan el código; los intentos se registran aunque la petición falle (`noRollbackFor`) |
| Un solo uso | El código usado se marca como consumido |
| Códigos anteriores | Un código nuevo invalida los pendientes |
| Frecuencia | 1 solicitud por minuto y 5 por hora por correo. Se aplica también a correos inexistentes, para no revelar cuáles están registrados |
| Respuestas indistinguibles | Mismo mensaje en todos los casos (código erróneo, vencido, usado o correo inexistente); comparación BCrypt de referencia para igualar tiempos; envío del correo asíncrono |
| Sin JWT | La recuperación no usa el token de acceso |
| Logs | Sin códigos ni contraseñas (verificado con `grep`) |
| Nueva contraseña | Mismas reglas que el registro, guardada con BCrypt |

**Integración de las pantallas**

- **OTP:** el botón *Verify* original (`MainButton`, antes con la acción vacía) ahora verifica el código, y *Resend* pide uno nuevo.
- **Cambio visual justificado:** se pasó de 4 a **6 casillas**, porque el código tiene 6 dígitos por seguridad. El espaciado bajó de 12 a 8 dp para que la sexta casilla no quedara cortada. El tamaño y el estilo de las casillas no cambiaron.
- **"Verify Using Number Here":** abre la verificación del código si ya hay un correo válido escrito. Su texto original habla de "número", pero no existe SMS; ver §9.
- **Recovery:** el código llega precargado; se añadieron validadores, y los botones "X" ahora vacían su campo (antes hacían `setState(() {})`).

### Fase B: Edit Profile

- **Campos:** solo los que admite `PATCH /api/v1/users/me` (nombre, teléfono, género y ubicación). El correo y la contraseña no se editan aquí.
- **Seguridad:** no hay ningún identificador de usuario en la petición; el backend toma el usuario del JWT.
- **Componentes:** solo los del profesor (`CustomAppBar`, `CustomFormText`, `CustomFormTextfield`, `CustomGenderBox`, `CustomRedBtn`) y los mismos espaciados que DonorRegistrationForm.
- **Género:** si nunca se eligió, no se envía, aunque el selector muestre *male* preseleccionado como en el diseño.
- **Limitación conocida:** dejar vacíos el teléfono o la ubicación no los borra, porque el PATCH ignora los campos nulos. Ver §9.

### Fase C: búsqueda de donantes

**Revisión del diseño**

- El formulario "Request for Blood Donor" **publica una solicitud**. Se conservó tal cual.
- Su botón **"Find Donors"**, después de publicar, ahora abre la búsqueda filtrada por el grupo de la solicitud. Ese es el significado que sugiere la etiqueta.
- `DonorSearchScreen` es una **pantalla nueva**, porque el diseño no tenía pantalla de resultados. Replica la estructura y los estilos de AllRequestScreen; su tarjeta `DonorResultItem` replica los de `CustomRequestFeedItem`.

**Privacidad**

| Medida | Detalle |
|---|---|
| Consentimiento | Columna `visible_in_search` con valor `FALSE` por defecto: los **5 donantes que ya existían quedaron ocultos** |
| Mecanismo explícito | Interruptor "Show me in donor search" en Edit Profile (solo si el usuario es donante), con el texto de qué se muestra. Llama a `PATCH /donors/me/visibility` |
| Datos expuestos | `DonorSearchResult` solo contiene id, nombre, grupo, ubicación y fecha de la última donación. **Sin teléfono, correo ni id de usuario** |
| Autor de la búsqueda | Se excluye de sus propios resultados |
| Autenticación | Obligatoria (401 sin token) |
| Ubicación | Búsqueda parcial sin distinguir mayúsculas; los comodines `%`, `_` y `!` se escapan |
| Compatibilidad | **No** se aplican reglas de compatibilidad sanguínea: el filtro usa el grupo exacto |

### Fase D: ubicación de solicitudes

- **Backend:** `BloodRequestService.resolveLocation` usa la ubicación enviada, si la hay; si no, la de `users.location`; si no, la de `donors.location`; y si no hay ninguna, nula.
- **ProfileScreen:** se unificó la misma prioridad (perfil primero, que es el dato editable).
- **Sin ubicación configurada:** la solicitud se guarda con `location = NULL`, el feed y el detalle muestran "—", y la app avisa: *"Add your location in Edit Profile so it appears in your requests."*
- **Solicitudes anteriores:** conservan su valor (verificado en MySQL: los ids 1 a 4 siguen en `NULL`).
- **Sin GPS** y sin permisos nuevos.

### Fase E: foto del donante

**Revisión del diseño**

- DonorRegistrationForm tiene una acción explícita ("Select Donor picture *required" con iconos de cámara y galería), así que se implementó la foto.
- El avatar de Profile es decorativo: no se añadió subida, solo se muestra la foto del donante si existe. Sin foto se mantiene la imagen original.

**Backend**

- **Almacenamiento:** archivos en disco (`uploads/donor-photos`, excluido de git) con un nombre UUID generado por el servidor y protección contra rutas manipuladas. La tabla solo guarda `photo_file`, **no la imagen binaria**.
- **Validación:** el formato se comprueba por los primeros bytes del archivo (JPEG `FFD8FF` o PNG `89504E47`), no por el nombre ni la cabecera, con 2 MB como máximo. Sobre HTTP real un archivo mayor devuelve **413** (`PHOTO_TOO_LARGE`) y uno no válido **400** (`INVALID_PHOTO`).
- **Reemplazo:** al subir una foto nueva se borra el archivo anterior.

**Flutter**

- `image_picker` reduce la imagen a 1024 px con calidad 85 y se validan las mismas reglas antes de subirla.
- La vista previa ocupa el mismo lugar y tamaño que el placeholder.
- Al pulsar *Complete* se guardan los datos y luego se sube la foto.

### Fase F: fechas y zona horaria

| Tipo de dato | Campos | Tratamiento |
|---|---|---|
| Fechas de calendario | `needBefore`, `lastDonationDate` | `LocalDate` → `"yyyy-MM-dd"`; en Dart se leen como `DateTime(y, m, d)` local, **sin conversión de zona** |
| Timestamps | `createdAt` de usuario y de solicitud | Ahora `Instant` en UTC (`"2026-10-15T00:23:32.879487Z"`); en Dart se convierten con `DateTime.parse(...).toLocal()` |
| Timestamps nuevos | `password_reset_codes` | `Instant` guardado en UTC por Hibernate (verificado: 00:01 UTC frente a 20:01 local) |
| Datos históricos | `created_at` y `updated_at` existentes | **No se modificaron.** Hibernate los escribió en hora local del servidor (UTC−4), así que `ServerTime.toInstant` los convierte al serializar usando esa misma zona |

- **Zona fijada:** el backend fija `America/Santo_Domingo` al arrancar (UTC−4 todo el año, igual que la zona del equipo). Así los valores históricos no cambian de significado si el servidor se ejecuta en otra zona.
- **Verificado:** el feed muestra tiempos relativos correctos ("2 minute ago", "1 hour ago").

## 2. Archivos creados y modificados

### Backend (`validei-api/`)

**Creados**

| Área | Archivos |
|---|---|
| Recuperación | `auth/controller/PasswordResetController`, `auth/dto/{ForgotPasswordRequest, VerifyResetCodeRequest, ResetPasswordRequest}`, `auth/entity/PasswordResetCode`, `auth/repository/PasswordResetCodeRepository`, `auth/service/{PasswordResetService, PasswordResetMailer, PasswordResetRateLimiter, PasswordRules}` |
| Comunes | `common/dto/MessageResponse`, `common/exception/{InvalidResetCodeException, TooManyRequestsException, InvalidPhotoException}`, `common/time/ServerTime`, `config/TimeConfig` (reloj y `@EnableAsync`) |
| Donantes | `donor/dto/{DonorSearchResult, DonorVisibilityRequest}`, `donor/service/{DonorPhotoService, DonorPhotoStorage}` |
| Migraciones | `V5__create_password_reset_codes_table.sql`, `V6__add_search_consent_to_donors.sql`, `V7__add_photo_to_donors.sql` |
| Pruebas | `PasswordResetIntegrationTest`, `PasswordResetRateLimiterTest`, `DonorSearchIntegrationTest`, `DonorPhotoIntegrationTest`, `ServerTimeTest` |

**Modificados**

| Archivo | Cambio |
|---|---|
| `ValideiApiApplication` | Zona horaria fija |
| `AuthService` | Usa `PasswordRules` |
| `BloodRequestService` / `BloodRequest` | Ubicación desde el perfil |
| `BloodRequestResponse`, `UserResponse` | `createdAt` como `Instant` |
| `Donor`, `DonorResponse` | `visibleInSearch`, `photoFile` / `hasPhoto` |
| `DonorRepository` | Consulta `searchVisible` |
| `DonorService` | Búsqueda y consentimiento |
| `DonorController` | `GET /donors`, `PATCH /me/visibility`, `PUT` y `GET /me/photo` |
| `GlobalExceptionHandler` | 400 `INVALID_RESET_CODE`, 429, 400 `INVALID_PHOTO`, 413, parte multipart ausente |
| `SecurityConfig` | Rutas nuevas autorizadas de forma explícita; se mantiene `denyAll` |
| `application*.properties` | Correo, recuperación y almacenamiento de fotos |
| `pom.xml` | `+spring-boot-starter-mail` |
| `compose.yaml` | Servicio `mailpit` (v1.31.5) |
| `.gitignore` | `uploads/` |
| `TestApi`, `BloodRequestIntegrationTest`, `application-test.properties` | Ajustes de las pruebas |

### Frontend (`proyecto-final/`)

**Creados**

| Archivo | Contenido |
|---|---|
| `screens/views/edit_profile/screens/edit_profile_screen.dart` | Antes estaba vacío |
| `screens/views/donor_search/screens/donor_search_screen.dart` | Pantalla nueva de resultados |
| `screens/views/donor_search/widgets/donor_result_item.dart` | Tarjeta de donante |
| `general/utils/photo_picker.dart` | Selector y validación de la foto |
| `integration_test/visual_capture_test.dart` | Recorrido auxiliar para las capturas del reporte |
| `test/widgets/{password_reset_flow, edit_profile, donor_search, donor_photo}_test.dart` | Pruebas nuevas |

**Modificados**

| Archivo | Cambio |
|---|---|
| `auth_repository.dart` | `+verifyResetCode` y `+resetPassword` |
| `auth_service_api.dart` | Endpoints de recuperación |
| `api_client.dart` | Multipart, descarga de bytes y manejo de errores unificado |
| `donor_api_service.dart` | Búsqueda, consentimiento y foto |
| `models/{donor, blood_request}.dart` | Campos nuevos y timestamps UTC |
| `date_format.dart` | `parseTimestamp` |
| `forgot_password_screen.dart` | Abre el OTP |
| `otp_recovery_screen.dart` | Verificación real, 6 casillas |
| `recovery_screen.dart` | Restablecimiento real |
| `login_screen.dart` | Descarta el mensaje anterior al entrar a Home |
| `find_donor_screen.dart` | Abre la búsqueda; aviso de ubicación |
| `donor_registration_screen.dart` | Foto |
| `profile_screen.dart` | Edit Profile, foto, prioridad de la ubicación |
| `custom_gender_box.dart`, `custom_blood_filter_box.dart` | `initialValue` opcional |
| `request_list_status.dart` | Mensaje de lista vacía configurable |
| `main.dart` | Rutas nuevas |
| `pubspec.yaml` | `+image_picker` |
| `integration_test/app_flow_test.dart` | Flujo ampliado |
| `test/support/fake_backend.dart`, `screens_test.dart`, `session_and_auth_test.dart` | Ajustes de las pruebas |

### Dependencias nuevas

| Dependencia | Motivo |
|---|---|
| `spring-boot-starter-mail` | Enviar el código de recuperación |
| `image_picker` ^1.2.4 | Cámara y galería del formulario de donante |
| Imagen Docker `axllent/mailpit:v1.31.5` | Solo desarrollo |

## 3. Endpoints nuevos

| Método | Ruta | Auth | Request | Respuesta correcta | Errores |
|---|---|---|---|---|---|
| POST | `/api/v1/auth/password/forgot` | 🔓 | `{email}` | 202 `{message}` (igual siempre) | 400, 429 |
| POST | `/api/v1/auth/password/verify` | 🔓 | `{email, code}` | 204 | 400 `INVALID_RESET_CODE` |
| POST | `/api/v1/auth/password/reset` | 🔓 | `{email, code, newPassword}` | 204 | 400 |
| GET | `/api/v1/donors?bloodGroup=&location=&page=&size=` | 🔐 | — | 200 `PageResponse<DonorSearchResult>` | 400, 401 |
| PATCH | `/api/v1/donors/me/visibility` | 🔐 | `{visibleInSearch}` | 200 `DonorResponse` | 400, 401, 404 |
| PUT | `/api/v1/donors/me/photo` | 🔐 | multipart, campo `photo` | 200 `DonorResponse` (`hasPhoto: true`) | 400, 401, 404, 413 |
| GET | `/api/v1/donors/me/photo` | 🔐 | — | 200 `image/jpeg` o `image/png` | 401, 404 |

**Cambios de contrato en endpoints existentes**

- `createdAt` (en `UserResponse` y `BloodRequestResponse`) ahora termina en `Z` (UTC).
- `DonorResponse` incluye `visibleInSearch` y `hasPhoto`.
- `POST /blood-requests` completa `location` desde el perfil cuando no se envía.

## 4. Migraciones nuevas

| Versión | Contenido | Aplicada en `validei_db` |
|---|---|---|
| V5 | Tabla `password_reset_codes`: `code_hash`, `expires_at`, `failed_attempts`, `consumed_at`, `created_at`; FK en cascada e índice | ✅ |
| V6 | `donors.visible_in_search BOOLEAN NOT NULL DEFAULT FALSE` + índice `(visible_in_search, blood_group)` | ✅ |
| V7 | `donors.photo_file VARCHAR(100) NULL` | ✅ |

- **Historial de Flyway:** V1 a V7, todas con `success = 1`. V1–V4 no se modificaron.
- **Datos conservados:** 11 usuarios previos y las solicitudes 1–4 con sus `created_at` originales. No se borró ningún registro ni volumen.

## 5. Pruebas realizadas

### Backend: `mvnw.cmd clean test`, 97 tests

| Clase | Tests | Cubre |
|---|---|---|
| `PasswordResetIntegrationTest` (**nueva**) | 9 | Correo con código y solo el hash en base de datos; correo inexistente (misma respuesta, sin correo); restablecer y no reutilizar; 5 intentos invalidan el código; código vencido; un código nuevo invalida el anterior; límite por hora (429), también para correos inexistentes; formatos; mismo mensaje con correo inexistente |
| `PasswordResetRateLimiterTest` (**nueva**) | 3 | Espera de 1 minuto, 5 por hora (con reloj controlado), independencia entre correos |
| `DonorSearchIntegrationTest` (**nueva**) | 10 | Oculto por defecto; solo con consentimiento y sin el propio usuario; sin contacto ni correo; filtros por grupo y ubicación; comodines escapados; paginación y parámetros inválidos; retirar consentimiento; 404 sin registro de donante; 401; valor obligatorio |
| `DonorPhotoIntegrationTest` (**nueva**) | 6 | Disco y descarga idéntica; reemplazo que borra el archivo anterior; archivo falso con nombre `.jpg`; más de 2 MB; 404 sin registro o sin foto; 401 y parte ausente |
| `ServerTimeTest` (**nueva**) | 3 | 18:27 local = 22:27 UTC; zona sin horario de verano; nulos |
| `BloodRequestIntegrationTest` (+3) | 15 | Ubicación del perfil; respaldo con la del donante y nula conservada; ubicación explícita; `createdAt` en UTC y `needBefore` como fecha |
| Suites anteriores | 51 | Auth, User, Donor, JWT, BloodGroup y contexto: **sin regresiones** |

### Flutter: `flutter test`, 88 tests

| Archivo | Tests | Cubre |
|---|---|---|
| `password_reset_flow_test` (**nuevo**) | 6 | SEND abre el OTP con 6 casillas; el enlace exige un correo válido; código correcto → Recovery con el código precargado; código erróneo; código incompleto; Recovery valida, guarda y vuelve a Login |
| `edit_profile_test` (**nuevo**) | 6 | Precarga; PATCH solo con los campos admitidos y Profile actualizado al volver; validación; error del backend; doble toque → un solo PATCH; el género no se envía si no se eligió |
| `donor_search_test` (**nuevo**) | 8 | Búsqueda con el grupo recibido (`AB%2B`) y solo datos públicos; filtro y "All"; lista vacía; consentimiento (enviar, no visible si no es donante, no enviar si no cambia); timestamp UTC → local; fecha de calendario intacta; tiempo relativo exacto |
| `donor_photo_test` (**nuevo**) | 6 | Cámara y galería con vista previa; *Complete* sube la foto como multipart; cancelar; archivo no válido; precarga de la foto y avatar en Profile; validación de tamaño y formato |
| `session_and_auth_test` (actualizado) | 10 | Endpoints de recuperación públicos y mensajes de error legibles |
| `screens_test` (actualizado) | 16 | *Find Donors* abre la búsqueda; aviso cuando falta la ubicación |
| Resto | 36 | Sin regresiones |

### Prueba integral en el Pixel 8: `integration_test/app_flow_test.dart`

**1 de 1 superada (42 s).** No usa respuestas simuladas: Spring Boot, MySQL y Mailpit son reales. Los pasos:

1. Registro y login.
2. Edit Profile (ubicación y género), comprobado en Profile.
3. Registro de donante.
4. Consentimiento en Edit Profile.
5. Publicar una solicitud AB+ → `DonorSearchScreen` **encuentra al donante que dio su consentimiento** (creado por la API) y no muestra su teléfono.
6. Feed con la ubicación "Santiago, RD" tomada del perfil, y detalle.
7. Logout.
8. Forgot → **el código real se lee desde Mailpit** → OTP → Recovery.
9. Login con la contraseña nueva.

## 6. Resultados finales (ejecutados al cerrar la fase)

| Comando | Resultado |
|---|---|
| `mvnw.cmd clean test` | **97/97**, BUILD SUCCESS |
| `flutter pub get` | OK |
| `flutter analyze` | **0 errores, 0 avisos**; 6 sugerencias de estilo, todas en código original (eran 7) |
| `flutter test` | **88/88** |
| `flutter build apk --debug` | ✓ `app-debug.apk` |
| `flutter test integration_test/app_flow_test.dart -d emulator-5554` | **1/1** |
| `flutter run -d emulator-5554` | App instalada y abierta |

### Verificaciones manuales en HTTP, MySQL y el emulador

| Comprobación | Resultado |
|---|---|
| Recuperación con Mailpit real | Correo recibido; verify incorrecto 400, correcto 204; reset 204; reutilizar 400; login nueva 200 / antigua 401; solicitud inmediata 429 |
| Base de datos tras la recuperación | Hash `$2a$12$`, `failed_attempts` registrado, código consumido, vigencia de 10 minutos |
| Foto por HTTP | PNG subido y descargado byte a byte idéntico; 3 MB → 413; texto → 400 |
| Foto en el emulador | Selector de Android → vista previa en el círculo → *Complete* → JPEG de 600×600 en disco → avatar en Profile (`docs/visual/final_foto_donante.png`) |
| Búsqueda | Solo devuelve el donante que dio su consentimiento, con datos públicos; sin token 401; los 5 donantes previos siguen ocultos |
| Timestamps | `createdAt` = `00:23:32Z` para una creación a las 20:23 locales; `needBefore` = `2026-10-17` |
| Logs | Revisadas 4 360 líneas del backend y la salida de las pruebas: **0** tokens, contraseñas, códigos OTP o `rejected value` |

## 7. Capturas antes y después

| Archivo | Contenido |
|---|---|
| `antes_1.png`, `antes_2.png` | Diseño original con los datos fijos (fase de integración) |
| `final_regresion_1.png`, `final_regresion_2.png` | Las mismas 10 pantallas al final: **diseño idéntico**, con datos reales (ubicación tomada del perfil en el feed y el detalle; Profile con datos editados) |
| `final_pantallas_nuevas.png` | Edit Profile (arriba y abajo, con el consentimiento), Available Donors, Forgot Password, OTP (6 casillas sin recorte) y Recovery |
| `final_foto_donante.png` | Formulario → vista previa → avatar en Profile |
| `back_menu.png`, `call_message.png`, `restauracion_sesion.png` | Evidencias de la fase anterior, que siguen vigentes |

## 8. Errores corregidos en esta fase

1. **OTP sin funcionar:** el botón *Verify* del diseño tenía la acción vacía y las funciones `verifyOtpWithBackend` / `resendOtp` estaban vacías.
2. **RecoveryScreen inaccesible y sin acción:** sus botones "X" no hacían nada.
3. **Sexta casilla del OTP cortada** (detectado en las capturas del emulador): corregido reduciendo el espaciado.
4. **SnackBar tapando botones** (detectado por la prueba integral): el mensaje "Account successfully created!" seguía visible al entrar y tapaba *Edit Profile*, y lo mismo podía pasar en Edit Profile. El login y esas pantallas ahora descartan el mensaje pendiente.
5. **Ubicación incoherente en Profile:** mostraba primero la del donante, de modo que editar la del perfil no se reflejaba. Ahora se muestra primero la del perfil.
6. **Escapes en archivos Java:** `\\d` se convertía en `\d` al escribir desde la shell. Se corrigió en los DTO de recuperación y en una prueba antes de ejecutar.

## 9. Funcionalidades pendientes y decisiones abiertas

| Tema | Estado / decisión necesaria |
|---|---|
| SMS / OTP por teléfono | ⛔ Fuera de alcance (no hay proveedor de SMS). El enlace "Verify Using Number Here" lleva a la verificación **por correo**; conviene cambiar su texto (requiere aprobar un cambio de texto del diseño) |
| Proveedor de correo de producción | ⛔ No configurado (no hay credenciales). Basta con definir `MAIL_HOST`, `MAIL_PORT` y las credenciales SMTP en las variables de entorno |
| Contactar a un donante desde la búsqueda | ⛔ No se exponen teléfonos ni correos. Falta decidir cómo contactarlo (por ejemplo, ampliar el consentimiento al teléfono o usar un mensaje interno) |
| Acceso directo a la búsqueda | Solo se entra al publicar una solicitud ("Find Donors"). Un acceso independiente, por ejemplo desde el menú, requiere aprobar el cambio de navegación |
| Borrar teléfono o ubicación en Edit Profile | La API (PATCH) ignora los nulos; para borrar habría que cambiar el contrato |
| Foto obligatoria | El diseño la marca "*required", pero se dejó opcional para no invalidar a los donantes que ya existen |
| Limitador de frecuencia | En memoria: válido para una sola instancia del backend (alcance académico). Con varias instancias habría que usar la base de datos o Redis |
| Género en Edit Profile | El selector del profesor siempre muestra una opción preseleccionada (*male*); solo se guarda si el usuario la toca |
| Datos de prueba | Usuarios `@validei.test` en MySQL y fotos en `uploads/`. Se pueden borrar en cascada (`DELETE FROM users WHERE email LIKE '%@validei.test'`) y vaciando `uploads/donor-photos` |

## 10. Matriz de trazabilidad

Rutas relativas a `/api/v1`.

| Pantalla | Funcionalidad | Endpoint | Tabla | Prueba | Estado |
|---|---|---|---|---|---|
| ForgotPasswordScreen | Solicitar código | `POST /auth/password/forgot` | `password_reset_codes`, `users` | `PasswordResetIntegrationTest`, `password_reset_flow_test`, integral paso 8 | ✅V |
| OtpRecoveryScreen | Verificar código / reenviar | `POST /auth/password/verify`, `POST /auth/password/forgot` | `password_reset_codes` | Ídem | ✅V |
| RecoveryScreen | Nueva contraseña | `POST /auth/password/reset` | `users`, `password_reset_codes` | Ídem, integral pasos 8 y 9 | ✅V |
| ProfileScreen | Ver perfil, foto y ubicación | `GET /users/me`, `GET /donors/me`, `GET /donors/me/photo` | `users`, `donors` | `screens_test`, `donor_photo_test`, integral paso 2 | ✅V |
| EditProfileScreen (nueva) | Editar nombre, teléfono, ubicación y género | `PATCH /users/me` | `users` | `UserIntegrationTest`, `edit_profile_test`, integral paso 2 | ✅V |
| EditProfileScreen (nueva) | Consentimiento de búsqueda | `PATCH /donors/me/visibility` | `donors.visible_in_search` | `DonorSearchIntegrationTest`, `donor_search_test`, integral paso 4 | ✅V |
| FindDonorScreen | Publicar solicitud con la ubicación del perfil | `POST /blood-requests` | `blood_requests` | `BloodRequestIntegrationTest`, `screens_test`, integral paso 5 | ✅V |
| DonorSearchScreen (nueva) | Buscar donantes (grupo, paginación) | `GET /donors` | `donors` | `DonorSearchIntegrationTest`, `donor_search_test`, integral paso 5 | ✅V |
| DonorRegistrationForm | Foto con cámara o galería | `PUT /donors/me/photo`, `GET /donors/me/photo` | `donors.photo_file` + disco | `DonorPhotoIntegrationTest`, `donor_photo_test`, manual en el emulador | ✅V (galería en el emulador; cámara con prueba de widget) |
| Home / AllRequests / Details | Ubicación y "hace X minutos" con UTC | `GET /blood-requests`, `GET /blood-requests/{id}` | `blood_requests` | `ServerTimeTest`, `donor_search_test` (fechas), integral paso 6 | ✅V |
| Login / Register / Drawer (Logout) | Sin regresiones | `POST /auth/login`, `POST /auth/register` | `users` | `auth_flow_test`, integral pasos 1, 7 y 9 | ✅V |
| OTP por SMS | — | — | — | — | ⛔ |

## 11. Cómo ejecutar el proyecto

1. **Servicios locales:** desde `validei-api/`, `docker compose up -d` (MySQL 8.4 y Mailpit, con el volumen existente).
   - Bandeja de correo: <http://localhost:8025>.
   - Secretos en `.env` (`MYSQL_*`, `DB_PASSWORD`, `JWT_SECRET_BASE64`; ver `.env.example`).
2. **Backend:** `mvnw.cmd spring-boot:run`. Aplica las migraciones Flyway pendientes. Comprobación: `curl http://localhost:8080/api/v1/health`.
3. **Pruebas del backend:** `mvnw.cmd clean test` (requiere Docker en marcha; usa Testcontainers).
4. **App:** desde `proyecto-final/`, `flutter pub get` y luego `flutter run -d emulator-5554`. Usar el emulador Pixel_8 y, si se queda en "Installing…", hacer *Cold Boot*.
5. **Pruebas de Flutter:**
   - `flutter analyze` y `flutter test`.
   - `flutter test integration_test/app_flow_test.dart -d emulator-5554`, con el backend y Mailpit en marcha.
6. **Recuperación manual:** en la app, *Forgot Your Password?* → correo → leer el código en <http://localhost:8025> → OTP → nueva contraseña.
7. **Foto en el emulador:** copiar una imagen con `adb push imagen.jpg /sdcard/Pictures/` y abrir la galería desde el formulario de donante.
