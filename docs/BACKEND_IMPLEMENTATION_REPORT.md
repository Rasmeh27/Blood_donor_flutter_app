# Reporte de implementación del backend: Validei API

- **Fecha:** 2026-10-14
- **Proyecto:** `validei-api/`
- **Stack:** Java 17, Spring Boot 4.1.1, Spring Security 7.1.1 (OAuth2 Resource Server), Hibernate 7.4, Flyway 12.4 y MySQL 8.4 (Docker)

Todos los resultados de este documento proceden de ejecuciones reales (ver §8). El frontend Flutter (`lib/`) no se modificó: se comprobó con `diff` contra la copia de seguridad.

## Matriz de estado

| Módulo | Implementado | Probado | Endpoints |
|---|---|---|---|
| Auth | Sí | Sí (17 automáticas + manual + Postman) | `POST /api/v1/auth/register`, `POST /api/v1/auth/login` |
| User | Sí | Sí (11 automáticas + manual + Postman) | `GET /api/v1/users/me`, `PATCH /api/v1/users/me` |
| Donor | Sí | Sí (13 automáticas + manual + Postman) | `GET /api/v1/donors/me`, `PUT /api/v1/donors/me` |
| BloodRequest | Sí | Sí (12 automáticas + manual + Postman) | `POST /api/v1/blood-requests`, `GET /api/v1/blood-requests`, `GET /api/v1/blood-requests/{id}` |
| Health | Sí (ya existía) | Sí (manual + Postman) | `GET /api/v1/health` |

---

## 1. Módulos implementados

### Estado inicial (auditoría de la fase A)

| Elemento | Estado encontrado |
|---|---|
| `JwtService` | Completo: emisor, `sub` = id, `iat`, `exp` y firma HS256. **Problema:** `expiresAt` incluía nanosegundos y no coincidía con el `exp` del token, que va en segundos |
| `JwtConfig` | Completo: clave en Base64 de al menos 32 bytes, `JwtEncoder` y `JwtDecoder` con validación del emisor |
| `LoginRequest` / `AuthResponse` | Existían. `LoginRequest` tenía erratas en los mensajes ("corre es invalido", "debe obligatoria") |
| `AuthService` / `AuthController` | Solo registro. **El login no existía** |
| `SecurityConfig` | **No tenía el Resource Server configurado**: ningún token se validaba. Solo permitía el health check y el registro |
| `UserService` | Tenía `getUserById` sin controlador. No existía `UserController` |
| `UserRepository` | Contenía `List<User> id(long id)`, generado por accidente y sin uso |
| `RegisterRequest` | **Sin `@Email`** (aceptaba "x" como correo) y sin la regla de carácter especial del frontend |
| Manejo de errores | No existía (`ResponseStatusException` con la respuesta por defecto de Spring) |
| `JWT_SECRET_BASE64` | **No estaba definida** en Windows, en IntelliJ ni en `.env`. La aplicación no podía arrancar |
| `.gitignore` | **No excluía `.env`**, que contiene contraseñas |
| Pruebas | Solo `contextLoads`, que dependía de variables de entorno |

### Lo que se implementó

| Fase | Resultado |
|---|---|
| **B: JWT y login** | Login con BCrypt, JWT firmado y Resource Server nativo de Spring Security, sin filtro personalizado |
| **C: errores** | `GlobalExceptionHandler` (`@RestControllerAdvice`) y `SecurityErrorHandler`, que lleva los 401 y 403 al mismo formato JSON |
| **D: User** | Consulta y actualización parcial del perfil propio, identificado solo por el JWT |
| **E: Donor** | Registro único por usuario (crear o actualizar) y consulta |
| **F: BloodRequest** | Crear, listar (paginado y con filtro por grupo) y detalle |
| **G: Flyway** | V2, V3 y V4. V1 queda intacta |
| **H: pruebas** | 63 automáticas con JUnit 6, Mockito, MockMvc y MySQL 8.4 real (Testcontainers) |
| **I: validación** | Pruebas manuales con `curl` y colección de Postman ejecutada con Postman CLI |

## 2. Archivos creados

**Código principal** (`src/main/java/com/validei/api/`):

| Archivo | Responsabilidad |
|---|---|
| `common/exception/ApiError.java` | Formato JSON de error |
| `common/exception/GlobalExceptionHandler.java` | Manejo centralizado de errores |
| `common/exception/ResourceNotFoundException.java` | 404 |
| `common/exception/ConflictException.java` | 409 |
| `common/exception/InvalidCredentialsException.java` | 401 en el login |
| `common/security/CurrentUser.java` | Obtiene el id del usuario desde el claim `sub` |
| `common/domain/BloodGroup.java` | Enum con las etiquetas `"A+"`… y su JSON |
| `common/domain/BloodGroupConverter.java` | Guarda el grupo en MySQL como `"A+"` |
| `common/domain/StringToBloodGroupConverter.java` | Lee `?bloodGroup=A%2B` de la URL |
| `common/domain/Gender.java` | `MALE` / `FEMALE` |
| `common/dto/PageResponse.java` | Respuesta paginada |
| `config/SecurityErrorHandler.java` | Envía los 401 y 403 de los filtros de seguridad al manejador global |
| `user/controller/UserController.java` | `/users/me` |
| `user/dto/UpdateProfileRequest.java` | Actualización parcial del perfil |
| `donor/controller/DonorController.java` | Endpoints de donante |
| `donor/service/DonorService.java` | Lógica de donante |
| `donor/repository/DonorRepository.java` | Acceso a datos de donantes |
| `donor/entity/Donor.java` | Entidad |
| `donor/dto/DonorRequest.java`, `donor/dto/DonorResponse.java` | DTO |
| `bloodrequest/controller/BloodRequestController.java` | Endpoints de solicitudes |
| `bloodrequest/service/BloodRequestService.java` | Lógica de solicitudes |
| `bloodrequest/repository/BloodRequestRepository.java` | Acceso a datos de solicitudes |
| `bloodrequest/entity/BloodRequest.java` | Entidad |
| `bloodrequest/dto/CreateBloodRequest.java`, `bloodrequest/dto/BloodRequestResponse.java` | DTO |

**Migraciones** (`src/main/resources/db/migration/`): `V2__add_profile_fields_to_users.sql`, `V3__create_donors_table.sql` y `V4__create_blood_requests_table.sql`.

**Pruebas** (`src/test/`):

| Archivo | Contenido |
|---|---|
| `TestcontainersConfiguration.java` | MySQL 8.4 en Docker con `@ServiceConnection` |
| `IntegrationTest.java` | Meta-anotación: `@SpringBootTest`, MockMvc, perfil `test` y Testcontainers |
| `TestApi.java` | Limpieza de tablas, registro y login para las pruebas |
| `auth/AuthIntegrationTest.java`, `auth/service/AuthServiceTest.java`, `auth/service/JwtServiceTest.java` | Autenticación |
| `user/UserIntegrationTest.java` | Usuarios |
| `donor/DonorIntegrationTest.java` | Donantes |
| `bloodrequest/BloodRequestIntegrationTest.java` | Solicitudes |
| `common/domain/BloodGroupTest.java` | Enum de grupo sanguíneo |
| `resources/application-test.properties` | Perfil de pruebas con una clave JWT **ficticia, solo para tests** |

**Otros:** `postman/Validei-API.postman_collection.json` (22 peticiones con aserciones).

## 3. Archivos modificados

| Archivo | Cambio | Motivo |
|---|---|---|
| `auth/service/JwtService.java` | `Instant.now().truncatedTo(SECONDS)` | `expiresAt` de la respuesta no coincidía con el `exp` del token (lo detectó `JwtServiceTest`) |
| `auth/service/AuthService.java` | Añadido `login()`; `ConflictException` en el registro; métodos `normalizeEmail` y `exceedsBcryptLimit` reutilizados | Fase B, sin duplicar lógica |
| `auth/controller/AuthController.java` | `POST /login` | Fase B |
| `auth/dto/LoginRequest.java` | Mensajes corregidos; el correo se recorta antes de validarse | Las erratas, y `@Email` rechazaba `" ana@mail.com "` |
| `auth/dto/RegisterRequest.java` | `@Email`, `@Pattern` de carácter especial y recorte del correo | Igualar `passwordValidator` y `emailvalidator` del frontend y el contrato API |
| `config/SecurityConfig.java` | `oauth2ResourceServer().jwt()`, manejo de errores y autorización explícita por ruta y método. Se conservan el dispatcher `ERROR` y `anyRequest().denyAll()` | Fases B a F |
| `user/entity/User.java` | `phone`, `gender` y `location` con sus métodos `update*` | Datos mostrados en ProfileScreen |
| `user/dto/UserResponse.java` | Los tres campos nuevos | Perfil |
| `user/service/UserService.java` | `findUser()` (lanza 404) y `updateProfile()` | Lo reutilizan Donor y BloodRequest |
| `user/repository/UserRepository.java` | Eliminado `List<User> id(long id)` | Accidental y sin uso |
| `application.properties` | `spring.mvc.log-resolved-exception=false` | **Fuga detectada:** DevTools registraba `rejected value [<contraseña>]` en los logs |
| `application-local.properties` | `spring.config.import=optional:file:.env[.properties]` | Leer `DB_PASSWORD` y `JWT_SECRET_BASE64` del `.env` local. Las variables de entorno de IntelliJ siguen teniendo prioridad |
| `ValideiApiApplicationTests.java` | Usa `@IntegrationTest` | Ya no depende de variables de entorno |
| `pom.xml` | Dependencias **de test**: `spring-boot-testcontainers`, `testcontainers-junit-jupiter` y `testcontainers-mysql`. Versiones gestionadas por Boot 4.1.1 | Pruebas contra MySQL real (sin H2) |
| `.gitignore` | Añadido `.env` | Evitar que se versionen las contraseñas |
| `.env` (no versionado) | Añadidos `DB_PASSWORD` (= `MYSQL_APP_PASSWORD`) y `JWT_SECRET_BASE64` (aleatorio de 48 bytes) | Necesarios para arrancar. Hay copia del `.env` original |
| `.env.example` | Añadidas las dos claves con valores de ejemplo | Documentación |

## 4. Endpoints disponibles

Todas las rutas empiezan por `/api/v1`. 🔓 = público, 🔐 = `Authorization: Bearer <token>`.

| Método | Ruta | Auth | Request | Respuesta correcta | Errores |
|---|---|---|---|---|---|
| GET | `/health` | 🔓 | — | 200 | — |
| POST | `/auth/register` | 🔓 | `{name, email, password}` | 201 `UserResponse` | 400, 409 |
| POST | `/auth/login` | 🔓 | `{email, password}` | 200 `AuthResponse` | 400, 401 |
| GET | `/users/me` | 🔐 | — | 200 `UserResponse` | 401, 404 |
| PATCH | `/users/me` | 🔐 | `{name?, phone?, gender?, location?}` | 200 `UserResponse` | 400, 401 |
| GET | `/donors/me` | 🔐 | — | 200 `DonorResponse` | 401, 404 |
| PUT | `/donors/me` | 🔐 | `DonorRequest` | 201 (creado) o 200 (actualizado) | 400, 401 |
| POST | `/blood-requests` | 🔐 | `CreateBloodRequest` | 201 con cabecera `Location` | 400, 401 |
| GET | `/blood-requests?bloodGroup=&page=&size=` | 🔐 | — | 200 `PageResponse` | 400, 401 |
| GET | `/blood-requests/{id}` | 🔐 | — | 200 `BloodRequestResponse` | 400, 401, 404 |

Cualquier otra ruta o método responde **401 sin token** o **403 con token**.

### Ejemplos reales

Son respuestas capturadas con `curl` el 2026-10-14.

**Login, 200** (token acortado):

```json
{"tokenType":"Bearer","accessToken":"eyJraWQiOiJT...","expiresAt":"2026-10-14T23:27:04Z",
 "user":{"id":2,"name":"Prueba Manual","email":"manual.prueba@validei.test","phone":null,"gender":null,"location":null,"createdAt":"2026-10-14T18:27:03.936313"}}
```

**PUT `/donors/me`, 201.** Request:

```json
{"name":"Prueba Manual","contactNumber":"+18092249304","bloodGroup":"B+","location":"Santo Domingo, DN","lastDonationDate":"2026-06-01"}
```

Response:

```json
{"id":1,"name":"Prueba Manual","contactNumber":"+18092249304","bloodGroup":"B+","location":"Santo Domingo, DN","lastDonationDate":"2026-06-01"}
```

**POST `/blood-requests`, 201** (`Location: /api/v1/blood-requests/1`). Request:

```json
{"bloodGroup":"AB+","bags":2,"contactNumber":"+18092249304","emergencyContact":"+18095550000","patientName":"Jorge Perez",
 "caseDescription":"Accident","patientGender":"MALE","needBefore":"2026-10-19","others":"Need very urgent"}
```

Response:

```json
{"id":1,"bloodGroup":"AB+","bags":2,"contactNumber":"+18092249304","emergencyContact":"+18095550000","patientName":"Jorge Perez",
 "caseDescription":"Accident","patientGender":"MALE","needBefore":"2026-10-19","location":null,"others":"Need very urgent","createdAt":"2026-10-14T18:27:06.293918"}
```

**GET `/blood-requests?bloodGroup=AB%2B&page=0&size=10`, 200:**

```json
{"content":[{ "id":1, "bloodGroup":"AB+", "...":"..." }],"page":0,"size":10,"totalElements":1,"totalPages":1}
```

**Error de validación, 400:**

```json
{"status":400,"error":"VALIDATION_ERROR","message":"Los datos enviados no son válidos","path":"/api/v1/auth/register",
 "fields":[{"field":"name","message":"El nombre es obligatorio"},{"field":"email","message":"El correo no es válido"}]}
```

**Errores de autenticación y autorización:**

```json
{"status":401,"error":"UNAUTHORIZED","message":"Se requiere autenticación","path":"/api/v1/users/me"}
{"status":401,"error":"UNAUTHORIZED","message":"El token es inválido o ha expirado","path":"/api/v1/users/me"}
{"status":401,"error":"INVALID_CREDENTIALS","message":"Correo o contraseña incorrectos","path":"/api/v1/auth/login"}
{"status":403,"error":"FORBIDDEN","message":"No tiene permiso para acceder a este recurso","path":"/api/v1/users/me"}
```

### Códigos de error

| Código | Cuándo se produce |
|---|---|
| `VALIDATION_ERROR` | Fallo de validación (incluye la lista `fields`) |
| `MALFORMED_REQUEST` | JSON mal formado, o un grupo o género desconocido |
| `INVALID_PARAMETER` | Parámetro de URL inválido (`bloodGroup=Z` o un id no numérico) |
| `NOT_FOUND` | Recurso inexistente |
| `CONFLICT` | Correo ya registrado o violación de una restricción única o foránea |
| `INVALID_CREDENTIALS` | Correo o contraseña incorrectos |
| `UNAUTHORIZED` | Falta el token, o es inválido o está caducado |
| `FORBIDDEN` | Ruta no autorizada |
| `METHOD_NOT_ALLOWED` | Método HTTP no admitido |
| `INTERNAL_ERROR` | Error inesperado. Se registra en el servidor y no se exponen detalles |

### Reglas de validación

| DTO | Reglas |
|---|---|
| `RegisterRequest` | `name`: obligatorio, máximo 120<br>`email`: obligatorio, formato válido, máximo 254<br>`password`: 8 a 64 caracteres, al menos uno de `#?!@$%^&*-`, máximo 72 bytes (límite de BCrypt) |
| `LoginRequest` | `email`: obligatorio y con formato válido<br>`password`: obligatoria |
| `UpdateProfileRequest` | Todos opcionales; los ausentes no se modifican<br>`name`: no vacío, máximo 120<br>`phone`: `^\+?[0-9]{7,15}$`<br>`gender`: `MALE` o `FEMALE`<br>`location`: no vacía, máximo 150 |
| `DonorRequest` | Todos obligatorios<br>`name`: máximo 120<br>`contactNumber`: patrón de teléfono<br>`bloodGroup`: uno de los 8<br>`location`: máximo 150<br>`lastDonationDate`: hoy o en el pasado |
| `CreateBloodRequest` | Obligatorios: `bloodGroup`; `bags` (1 a 10); `contactNumber` y `emergencyContact` (teléfono); `patientName` (máximo 120); `caseDescription` (máximo 150); `needBefore` (hoy o futuro)<br>Opcionales: `patientGender`, `location` (máximo 150) y `others` (máximo 255) |
| Listado | `page` ≥ 0; `size` entre 1 y 50 (por defecto 10). Orden: más recientes primero |

## 5. Entidades y relaciones

```
users (1) ──── (0..1) donors           donors.user_id UNIQUE, FK ON DELETE CASCADE
users (1) ──── (0..N) blood_requests   blood_requests.requester_id FK ON DELETE CASCADE
```

### `users` (V1 y V2)

| Columnas | Restricciones |
|---|---|
| `id`, `name` (120), `email` (254), `password_hash` (255) | PK; `email` UNIQUE |
| `phone` (20), `gender` (10), `location` (150) | Opcionales; CHECK en `gender` |
| `created_at`, `updated_at` | — |

### `donors` (V3)

| Columnas | Restricciones |
|---|---|
| `id`, `user_id` | PK; `user_id` UNIQUE con FK en cascada |
| `full_name` (120), `contact_number` (20), `blood_group` (3), `location` (150), `last_donation_date` (DATE) | CHECK con los 8 grupos sanguíneos; índice por grupo |
| `created_at`, `updated_at` | — |

### `blood_requests` (V4)

| Columnas | Restricciones |
|---|---|
| `id`, `requester_id` | PK; FK en cascada |
| `blood_group` (3), `bags` (TINYINT UNSIGNED), `contact_number` (20), `emergency_contact` (20), `patient_name` (120), `case_description` (150), `need_before` (DATE) | Obligatorios. CHECK en el grupo y en `bags` ≥ 1 |
| `patient_gender` (10), `location` (150), `others` (255) | Opcionales. CHECK en `patient_gender` |
| `created_at` | Índices `(created_at)` y `(blood_group, created_at)` |

### Decisiones del modelo

- No hay tabla de grupos sanguíneos (es un enum).
- No hay tabla de perfil: el perfil son los datos de `users` más `GET /donors/me`.
- No se crearon tablas de historial de donaciones, respuestas a solicitudes ni mensajería, que quedan fuera del alcance.
- `ddl-auto=validate` confirma en cada arranque que las entidades coinciden con el esquema. Se comprobó tanto en `validei_db` como en MySQL de Testcontainers.

## 6. Migraciones ejecutadas

| Versión | Descripción | `validei_db` (Docker) | MySQL de tests |
|---|---|---|---|
| 1 | create users table | Ya aplicada (sin cambios) | Aplicada |
| 2 | add profile fields to users | **Aplicada** 2026-10-14 18:26 | Aplicada |
| 3 | create donors table | **Aplicada** | Aplicada |
| 4 | create blood requests table | **Aplicada** | Aplicada |

- **Resultado en Flyway:** "Successfully applied 3 migrations to schema `validei_db`, now at version v4". En el siguiente arranque: "Schema is up to date".
- **Datos existentes:** el usuario original (`id=1`) se conserva. No se borró ninguna tabla ni volumen.
- **Copia previa:** antes de migrar se hizo un `mysqldump` de `validei_db` en el directorio temporal de la sesión.
- **Datos de prueba que quedan en `validei_db`:**
  - Usuarios: `manual.prueba@validei.test`, `segunda.prueba@validei.test` y uno `postman.<timestamp>@validei.test`.
  - Sus registros de donante y dos solicitudes.
  - Se pueden borrar sin riesgo con `DELETE FROM users WHERE email LIKE '%@validei.test'`; la cascada elimina el resto.

## 7. Configuración de seguridad

- **Autenticación:** JWT HS256 validado por el **Resource Server nativo** (`oauth2ResourceServer().jwt()` con el `JwtDecoder` de `JwtConfig`). No hay filtro personalizado.
- **Validación del token:** firma, `exp`/`nbf` y emisor (`JwtValidators.createDefaultWithIssuer`). El claim `sub` contiene el id del usuario y la vigencia es de 60 minutos (`app.jwt.expiration-minutes`).
- **Sesión:** sin estado (`STATELESS`). CSRF, formLogin y httpBasic están desactivados.
- **Autorización:** se declara de forma explícita cada combinación de **método y ruta**. Se conserva `dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()` y el resto es `anyRequest().denyAll()`.
- **Sin identificadores de usuario en la URL:** no hay endpoints con id de usuario. Todo `/me` se resuelve desde el JWT, así que un usuario no puede consultar ni modificar a otro (comprobado en test).
- **Contraseñas:** BCrypt con coste 12. Se rechazan las de más de 72 bytes. El login devuelve el mismo mensaje si el correo no existe o la contraseña es incorrecta.
- **Secretos:**
  - `JWT_SECRET_BASE64` y `DB_PASSWORD` se leen de variables de entorno o del `.env` local, que ya no se versiona.
  - La clave de `application-test.properties` es ficticia y solo sirve para los tests.
- **Logs** (comprobado con `grep` sobre el log de ejecución):
  - No aparecen tokens, cabeceras `Bearer` ni contraseñas.
  - Se desactivó el log de excepciones resueltas, que mostraba `rejected value` con contraseñas.

## 8. Pruebas realizadas y resultados

### Automáticas: `mvnw.cmd clean test`, **63 de 63 superadas** (BUILD SUCCESS)

| Clase | Tipo | Tests | Cubre |
|---|---|---|---|
| `JwtServiceTest` | Unitaria (Nimbus real) | 6 | `sub`, `iss`, `iat` y `exp`; token alterado; expirado; otro emisor; duración ≤ 0; clave corta |
| `AuthServiceTest` | Unitaria (Mockito) | 6 | Registro normalizado; duplicado; login correcto; contraseña incorrecta; usuario inexistente; más de 72 bytes |
| `AuthIntegrationTest` | Integración (MySQL) | 11 | 201 con hash `$2a$12$` en la base; 409; validaciones; correo inválido; sin carácter especial; JSON mal formado; login 200; 401 por contraseña; 401 por usuario inexistente (mismo mensaje); validación del login; ruta desconocida |
| `UserIntegrationTest` | Integración | 11 | Perfil 200; sin token; token alterado; token mal formado; **token expirado**; usuario borrado (404); PATCH solo modifica al usuario del token; validaciones; género desconocido; PATCH sin token; `GET /users/{id}` responde 403 |
| `DonorIntegrationTest` | Integración | 13 | 404 antes de registrarse; registro 201 en la base; consulta; actualización 200 sin duplicar; 5 campos obligatorios; fecha futura; teléfono; grupo inválido; autenticación; UNIQUE por usuario; FK; CHECK del grupo; cascada |
| `BloodRequestIntegrationTest` | Integración | 12 | Creación con `requester_id` del token y `Location`; orden; **filtro `A%2B`**; paginación; `size=51` y grupo inválido (400); detalle; 404; id no numérico; 7 obligatorios; bolsas 0 y 11; fecha pasada; autenticación (nada se guarda); cascada |
| `BloodGroupTest` | Unitaria | 3 | Etiquetas y conversor |
| `ValideiApiApplicationTests` | Contexto | 1 | La aplicación arranca con Flyway y `validate` |

Las pruebas de integración usan **MySQL 8.4 real** (Testcontainers 2.0.5 con Docker Desktop), no H2.

### Fallos encontrados y corregidos durante el desarrollo

Todos los detectaron los tests.

1. `expiresAt` con nanosegundos frente a `exp` en segundos, en `JwtService`.
2. `@Email` rechazaba correos con espacios alrededor, lo que rompía en el registro un caso que antes funcionaba.
3. Al probar las restricciones CHECK de MySQL (error 3819), Spring las devuelve como `UncategorizedSQLException`. Solo había que ajustar el test.
4. `MockMvc.get(String)` volvía a codificar `%2B`. Solo había que ajustar el test.

### Manuales: aplicación arrancada (`spring-boot:run`, perfil `local`) contra `validei_db`

- 20 casos con `curl`, todos con el código esperado: 201, 409, 400, 401, 200, 401, 200, 401, 200, 404, 201, 200, 200, 201, 200, 200, 404, 400, 403 y 401.
- Datos comprobados en MySQL: hash BCrypt, perfil, donante y solicitud con `requester_id` correcto.
- Tras corregir el log, el registro original sigue respondiendo 201.

### Postman CLI 1.73.0: `postman collection run postman/Validei-API.postman_collection.json`

**22 peticiones, 35 aserciones, 0 fallos.**

## 9. Funcionalidades pendientes y decisiones abiertas

| Tema | Estado | Referencia |
|---|---|---|
| Ubicación de la solicitud | `location` es opcional y queda nula, porque el formulario de FindDonorScreen no la pide. Falta decidir si se toma del perfil del solicitante | D4 |
| Búsqueda de donantes `GET /donors` | No implementada: ninguna pantalla muestra resultados | D3 |
| Disponibilidad para donar | No implementada: ninguna pantalla la define | — |
| Foto del donante | No implementada (requiere subida de archivos) | D6 |
| Recuperación de contraseña y OTP | No implementados (requieren SMTP o SMS) | D1, D5 |
| Logout | No hace falta endpoint: el cliente borra el token (JWT sin estado) | D2 |
| Pantalla Edit Profile | El endpoint `PATCH /users/me` existe, pero la pantalla sigue sin diseño | D7 |
| Estado, cancelación y "mis solicitudes" | No implementados: ninguna pantalla los usa | D9 |
| Zona horaria de `createdAt` | `LocalDateTime` sin zona (se mantuvo el estilo de `UserResponse`). Para el texto "hace 2 minutos" funciona si el móvil y el servidor están en la misma zona. **Alternativa:** pasar a `Instant`/UTC antes de integrar Flutter | Riesgo menor |
| Integración con Flutter | Pendiente: `AuthServiceApi`, permiso `INTERNET` y HTTP sin cifrar solo en debug (ver PLAN_IMPLEMENTACION, fase 3) | Fase siguiente |
| Logs del perfil local | `logging.level.org.springframework.security=TRACE` genera mucho volumen. No se encontraron secretos, pero conviene bajarlo a INFO para la presentación | Opcional |
| `HealthController` | Las claves del JSON son `"Status: "` y `"message: "` (con dos puntos y espacio). No se cambió porque funciona | Cosmético |
| `User.id` | Es `long` primitivo, pero su getter devuelve `Long`. No se cambió porque funciona | Cosmético |

## 10. Cómo ejecutar el backend

1. **Levantar MySQL**, con el volumen existente:

   ```bash
   docker compose up -d
   ```

2. **Configurar los secretos:** copiar `.env.example` a `.env` y completar `MYSQL_ROOT_PASSWORD`, `MYSQL_APP_PASSWORD`, `DB_PASSWORD` (el mismo valor que `MYSQL_APP_PASSWORD`) y `JWT_SECRET_BASE64`. Para generar la clave:

   ```bash
   openssl rand -base64 48
   ```

   Las variables de entorno definidas en IntelliJ tienen prioridad sobre `.env`.

3. **Ejecutar las pruebas.** Requieren Docker en marcha:

   ```bash
   mvnw.cmd clean test
   ```

4. **Arrancar la API:**

   ```bash
   mvnw.cmd spring-boot:run
   ```

   También se puede ejecutar `ValideiApiApplication` desde IntelliJ, con el directorio de trabajo en `validei-api`. La API queda en `http://localhost:8080/api/v1`; desde el emulador Android, en `http://10.0.2.2:8080/api/v1`.

5. **Probar con Postman:** importar `postman/Validei-API.postman_collection.json` y ejecutar la colección en orden, o desde la terminal:

   ```bash
   postman collection run postman/Validei-API.postman_collection.json
   ```
