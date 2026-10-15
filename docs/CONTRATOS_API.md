# Contrato REST preliminar: Validei

**Stack:** Java 17, Spring Boot 3.x (Web, Validation, Data JPA, Security), MySQL 8 y JWT.

## Convenciones generales

| Aspecto | Convención |
|---|---|
| URL base | `/api/v1`. Desde el emulador: `http://10.0.2.2:8080/api/v1` |
| Formato | JSON en UTF-8. Las fechas siguen ISO-8601: `LocalDate` → `"2026-10-14"` e `Instant` → `"2026-10-14T16:20:00Z"` |
| Nombres de campos | `camelCase` |
| Autenticación | `Authorization: Bearer <JWT>`. 🔓 = público, 🔐 = requiere token |
| Paginación | `?page=0&size=10&sort=createdAt,desc`, con la respuesta `PageResponse<T>` |
| Errores | `application/problem+json` (`ProblemDetail` de Spring 6) |
| Grupo sanguíneo | Texto exacto: `"A+"`, `"B+"`, `"AB+"`, `"O+"`, `"A-"`, `"B-"`, `"AB-"` u `"O-"` |
| Género | `"MALE"` o `"FEMALE"`. La interfaz muestra "male"/"female" |

### Formato de error

```json
{
  "type": "about:blank",
  "title": "Bad Request",
  "status": 400,
  "detail": "Validation failed",
  "instance": "/api/v1/auth/register",
  "errors": [ { "field": "email", "message": "enter a valid email address" } ]
}
```

Los mensajes de validación repiten **los mismos textos** de `lib/src/constants/validators.dart`, para que la app se comporte igual tanto si valida el móvil como el servidor.

### Respuesta paginada (`PageResponse<T>`)

```json
{ "content": [ ... ], "page": 0, "size": 10, "totalElements": 42, "totalPages": 5 }
```

---

## 1. Autenticación

### 1.1 `POST /auth/register` 🔓

- **Objetivo:** crear una cuenta de usuario.
- **Pantalla:** `RegisterScreen` (botón "REGISTER").

**Request: `RegisterRequest`**

```json
{ "name": "Jorge Perez", "email": "jorge@mail.com", "password": "Secreta#1", "confirmPassword": "Secreta#1" }
```

**Validación:**

| Campo | Reglas |
|---|---|
| `name` | `@NotBlank` → "name is required"; máximo 100 caracteres |
| `email` | `@NotBlank` → "email is required"; `@Email` → "enter a valid email address"; máximo 150 |
| `password` | `@NotBlank`; `@Size(min=8)` → "password must be at least 8 chars long"; `@Pattern(".*[#?!@$%^&*-].*")` → "password  must have at least one special character" |
| `confirmPassword` | Debe ser igual a `password` → "passwords do not match" (validación de clase) |

**Respuestas:**

| Código | Contenido |
|---|---|
| 201 | `UserResponse` |
| 400 | Error de validación |
| 409 | "The account exists for the email provided" (mismo texto que el servicio Firebase) |

**Response: `UserResponse`**

```json
{ "id": 1, "name": "Jorge Perez", "email": "jorge@mail.com", "createdAt": "2026-10-14T16:20:00Z" }
```

### 1.2 `POST /auth/login` 🔓

- **Objetivo:** autenticar al usuario y entregar un JWT.
- **Pantalla:** `LoginScreen` (botón "LOGIN").

**Request: `LoginRequest`**

```json
{ "email": "jorge@mail.com", "password": "Secreta#1" }
```

- **Validación:** email con `@NotBlank` y `@Email`; password con `@NotBlank`. En el login no se comprueba la complejidad de la contraseña.

**Respuestas:**

| Código | Contenido |
|---|---|
| 200 | `AuthResponse` |
| 400 | Error de validación |
| 401 | "Invalid email or password" (mensaje genérico) |

**Response: `AuthResponse`**

```json
{
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": { "id": 1, "name": "Jorge Perez", "email": "jorge@mail.com" }
}
```

> **Diferencia con Firebase:** Firebase distingue entre "User not found" y "Wrong password". Por seguridad, la API responde con un único mensaje genérico. La app sigue recibiendo un `String` distinto de `"Success"`, así que la pantalla no cambia.

### 1.3 `POST /auth/logout` 🔐 (opcional)

- **Objetivo:** cerrar la sesión.
- **Pantalla:** `HomeDrawer` ("Logout").
- **Request:** sin cuerpo.
- **Respuesta:** 204.

Con un JWT sin estado en el servidor, cerrar sesión consiste en **borrar el token en el móvil**. Este endpoint solo hace falta si se decide mantener una lista de tokens revocados (decisión D2).

### 1.4 `POST /auth/password/forgot` 🔓

- **Objetivo:** generar un código de recuperación y enviarlo por email.
- **Pantalla:** `ForgotPasswordScreen` (botón "SEND").

**Request: `ForgotPasswordRequest`**

```json
{ "email": "jorge@mail.com" }
```

- **Validación:** `@NotBlank` y `@Email`.
- **Respuesta:** **202 siempre**, exista o no la cuenta, para no revelar qué emails están registrados. La app ya muestra "Link sent!".
- **Depende de:** un servidor SMTP (decisión D1).

### 1.5 `POST /auth/password/reset` 🔓

- **Objetivo:** cambiar la contraseña usando el código recibido.
- **Pantalla:** `RecoveryScreen` (botón "RESET PASSWORD").

**Request: `ResetPasswordRequest`**

```json
{ "email": "jorge@mail.com", "code": "482913", "newPassword": "Nueva#123", "confirmPassword": "Nueva#123" }
```

**Validación:**

| Campo | Reglas |
|---|---|
| `email` | `@Email`. RecoveryScreen no tiene campo de email, así que lo **recibe como argumento** desde ForgotPassword |
| `code` | `@Pattern("\\d{6}")` |
| `newPassword` | Las mismas reglas que en el registro |
| `confirmPassword` | Debe coincidir con `newPassword` |

**Respuestas:**

| Código | Contenido |
|---|---|
| 204 | Contraseña cambiada |
| 400 | "Invalid or expired code" |

### 1.6 OTP por SMS: **diferido** (decisión D5)

`OtpRecoveryScreen` usa `flutter_otp_kit` con `verifyOtpWithBackend` y `resendOtp` vacíos. Ninguna pantalla pide el número de teléfono y haría falta un proveedor de SMS de pago.

Si se aprueba, los endpoints serían:

- `POST /auth/otp/send` con `{ "phone" }`
- `POST /auth/otp/verify` con `{ "phone", "code" }` → `AuthResponse`

---

## 2. Usuario y perfil

### 2.1 `GET /users/me` 🔐

- **Objetivo:** devolver los datos del usuario con sesión y su información de donante.
- **Pantallas:** `ProfileScreen`, `HomeDrawer` (nombre), avatar del AppBar y comprobación de sesión al arrancar.
- **Respuestas:** 200 con `ProfileResponse`; 401 si el token falta o caducó.

**Response: `ProfileResponse`**

```json
{
  "id": 1,
  "name": "Jorge Perez",
  "email": "jorge@mail.com",
  "phone": "+18092249304",
  "gender": "MALE",
  "location": "Santo Domingo, DN",
  "bloodGroup": "B+",
  "photoUrl": null,
  "isDonor": true
}
```

Cómo se calcula cada campo: ver [MODELO_DATOS.md §4](MODELO_DATOS.md).

### 2.2 `PATCH /users/me` 🔐: **pendiente de diseño** (decisión D7)

- **Pantalla:** `EditProfileScreen` (hoy el archivo está vacío).

**Request: `UpdateProfileRequest`** (todos los campos son opcionales)

```json
{ "name": "Jorge Perez", "phone": "+18092249304", "gender": "MALE", "location": "Santo Domingo, DN" }
```

**Validación:**

| Campo | Reglas |
|---|---|
| `name` | `@Size(1..100)` |
| `phone` | `@Pattern("^\\+?[0-9]{7,15}$")` |
| `gender` | Valor del enum |
| `location` | `@Size(max=150)` |

- **Respuesta:** 200 con `ProfileResponse`.

---

## 3. Donantes

### 3.1 `GET /donors/me` 🔐

- **Objetivo:** cargar el registro de donante del usuario, si existe.
- **Pantalla:** `DonorRegistrationForm` (precargar los campos).
- **Respuestas:** 200 con `DonorResponse`; 404 si todavía no es donante.

### 3.2 `PUT /donors/me` 🔐

- **Objetivo:** crear o actualizar el registro de donante. Como cada usuario tiene como máximo uno, se usa una operación idempotente.
- **Pantalla:** `DonorRegistrationForm` (botón "Complete").

**Request: `DonorRequest`**

```json
{
  "name": "Jorge Perez",
  "contactNumber": "+18092249304",
  "bloodGroup": "A+",
  "location": "Santo Domingo, RD",
  "lastDonationDate": "2026-06-01"
}
```

**Validación:**

| Campo | Reglas |
|---|---|
| `name` | `@NotBlank`; máximo 100 |
| `contactNumber` | `@NotBlank`; `@Pattern("^\\+?[0-9]{7,15}$")` |
| `bloodGroup` | `@NotNull`; valor del enum |
| `location` | `@NotBlank`; máximo 150 |
| `lastDonationDate` | `@NotNull`; `@PastOrPresent` (regla propuesta: hoy la interfaz admite fechas futuras) |

**Respuestas:**

| Código | Contenido |
|---|---|
| 201 | `DonorResponse` (registro creado) |
| 200 | `DonorResponse` (registro actualizado) |
| 400 | Error de validación |

**Response: `DonorResponse`**

```json
{ "id": 7, "name": "Jorge Perez", "contactNumber": "+18092249304", "bloodGroup": "A+",
  "location": "Santo Domingo, RD", "lastDonationDate": "2026-06-01", "photoUrl": null }
```

### 3.3 `PUT /donors/me/photo` 🔐: **pendiente** (decisión D6)

- **Request:** `multipart/form-data` con el campo `file` (JPG o PNG, máximo 2 MB).
- **Respuestas:** 200 con `{ "photoUrl": "/files/donors/7.jpg" }`; 413 si el archivo es demasiado grande; 415 si el formato no es válido.
- **Requiere en Flutter:** el paquete `image_picker` y acciones en los iconos de cámara y galería.

### 3.4 `GET /donors` 🔐: **pendiente** (decisión D3)

- **Objetivo:** buscar donantes compatibles.
- **Parámetros:** `bloodGroup` (opcional), `location` (opcional, búsqueda parcial), `page`, `size`.
- **Respuesta:** 200 con `PageResponse<DonorSummary>`, donde `DonorSummary` contiene `{ id, name, bloodGroup, location, contactNumber, lastDonationDate }`.
- **Pantalla:** **ninguna** de las actuales muestra una lista de donantes.

---

## 4. Solicitudes de sangre

### 4.1 `POST /blood-requests` 🔐

- **Objetivo:** publicar una solicitud de sangre.
- **Pantalla:** `FindDonorScreen` (botón "Find Donors").

**Request: `CreateBloodRequestRequest`**

```json
{
  "bloodGroup": "AB+",
  "bags": 2,
  "contactNumber": "+18092249304",
  "emergencyContact": "+18095550000",
  "patientName": "Jorge Perez",
  "caseDescription": "Cancer Patient",
  "patientGender": "MALE",
  "needBefore": "2026-10-20",
  "location": null,
  "others": "Need very urgent"
}
```

**Validación:**

| Campo | Reglas |
|---|---|
| `bloodGroup` | `@NotNull` |
| `bags` | `@NotNull`; `@Min(1)`; `@Max(10)` (tope propuesto) |
| `contactNumber` / `emergencyContact` | `@NotBlank`; patrón de teléfono |
| `patientName` | `@NotBlank`; máximo 100 |
| `caseDescription` | `@NotBlank`; máximo 150 |
| `patientGender` | Opcional |
| `needBefore` | `@NotNull`; `@FutureOrPresent` (propuesto) |
| `location` | Opcional, máximo 150 (decisión D4) |
| `others` | Opcional, máximo 255 |

**Respuestas:**

| Código | Contenido |
|---|---|
| 201 | `BloodRequestDetail`, con la cabecera `Location: /api/v1/blood-requests/{id}` |
| 400 | Error de validación |
| 401 | Sin sesión |

### 4.2 `GET /blood-requests` 🔐

- **Objetivo:** listar las solicitudes de la más reciente a la más antigua.
- **Pantallas:** `HomeScreen` (feed, `size=10`) y `AllRequestScreen` (con filtro).

**Parámetros:**

| Parámetro | Valores |
|---|---|
| `bloodGroup` | Opcional. Si se omite equivale a "All" |
| `page` | Por defecto 0 |
| `size` | Por defecto 10, máximo 50 |

- **Respuesta:** 200 con `PageResponse<BloodRequestSummary>`.

**`BloodRequestSummary`:** los campos exactos que muestra `CustomRequestFeedItem`

```json
{
  "id": 15,
  "bloodGroup": "A+",
  "patientName": "Jorge Perez",
  "bags": 2,
  "caseDescription": "Accident",
  "location": "Santo Domingo, DN",
  "needBefore": "2024-02-10",
  "createdAt": "2026-10-14T16:18:00Z"
}
```

El texto "2 minute ago" se calcula en el móvil a partir de `createdAt`.

### 4.3 `GET /blood-requests/{id}` 🔐

- **Objetivo:** devolver el detalle completo de una solicitud.
- **Pantalla:** `RequestDetailsScreen`. El `id` llega como argumento de la ruta desde el botón "Details".
- **Respuestas:** 200 con `BloodRequestDetail`; 404 si la solicitud no existe.

**`BloodRequestDetail`:** los 8 campos de la pantalla, más los de identificación

```json
{
  "id": 15,
  "needBefore": "2024-02-10",
  "patientName": "Jorge Perez",
  "location": "Santo Domingo, RD",
  "bloodGroup": "AB+",
  "contactNumber": "+18092249304",
  "caseDescription": "Cancer Patient",
  "bags": 2,
  "others": "Need very urgent",
  "emergencyContact": "+18095550000",
  "patientGender": "MALE",
  "requesterId": 1,
  "createdAt": "2026-10-14T16:18:00Z"
}
```

"Call" y "Message" usan `contactNumber` con un *intent* `tel:` o `sms:` del dispositivo, **sin llamar al backend**.

---

## 5. Resumen de endpoints

| # | Método | Ruta | Auth | Pantalla | Prioridad |
|---|---|---|---|---|---|
| 1 | POST | `/auth/register` | 🔓 | Register | P1 |
| 2 | POST | `/auth/login` | 🔓 | Login | P1 |
| 3 | GET | `/users/me` | 🔐 | Profile, Drawer, arranque | P1 |
| 4 | POST | `/blood-requests` | 🔐 | FindDonor | P2 |
| 5 | GET | `/blood-requests` | 🔐 | Home, AllRequests | P2 |
| 6 | GET | `/blood-requests/{id}` | 🔐 | RequestDetails | P2 |
| 7 | GET | `/donors/me` | 🔐 | DonorRegistration | P3 |
| 8 | PUT | `/donors/me` | 🔐 | DonorRegistration | P3 |
| 9 | POST | `/auth/password/forgot` | 🔓 | ForgotPassword | P4 (D1) |
| 10 | POST | `/auth/password/reset` | 🔓 | Recovery | P4 (D1) |
| 11 | POST | `/auth/logout` | 🔐 | Drawer | Opcional (D2) |
| 12 | PATCH | `/users/me` | 🔐 | EditProfile | Pendiente (D7) |
| 13 | PUT | `/donors/me/photo` | 🔐 | DonorRegistration | Pendiente (D6) |
| 14 | GET | `/donors` | 🔐 | — | Pendiente (D3) |
| — | POST | `/auth/otp/*` | 🔓 | OTP | Diferido (D5) |

---

## 6. Cómo reemplazar Firebase sin romper las pantallas

Las pantallas ya dependen de `AuthRepository`, que devuelve `Future<String>` con `"Success"` o un mensaje de error. **Se mantiene ese contrato** y solo cambia la implementación.

1. **Ampliar `AuthRepository`**, sin cambios visuales, con:
   - `Future<void> sendPasswordResetEmail(String email)`, que ya existe en la clase Firebase y lanza el mensaje como excepción, como hoy.
   - `Future<void> logout()`.
   - `Future<bool> hasSession()`.
2. **Crear `lib/src/services/auth_service_api.dart`**, que implementa `AuthRepository` con el paquete `http`:
   - `login`: un 200 guarda el token y devuelve `"Success"`; un 401 o 400 devuelve el `detail` o el primer mensaje de `errors[]`.
   - `register`: un 201 devuelve `"Success"`; un 409 devuelve "The account exists for the email provided".
   - En cualquier error de red devuelve "Something went wrong", igual que hoy.
3. **Cliente HTTP compartido** (`lib/src/services/api_client.dart`):
   - URL base configurable con `--dart-define=API_BASE_URL=...`.
   - Añade la cabecera `Authorization`.
   - Ante un 401, borra el token.
4. **Cambiar la instancia en 3 líneas**:
   - `login_screen.dart:19`
   - `register_screen.dart:21`
   - `forgot_password_screen.dart:20` (y cambiar el tipo a `AuthRepository`)

   Se recomienda inyectar la dependencia con un *service locator* sencillo para no repetir la clase concreta.
5. **Drawer:** cambiar `FirebaseAuth.instance.signOut()` por `authRepository.logout()` y la navegación a Login, y arreglar el problema del toque (F09).
6. **`main.dart`:** añadir una puerta de sesión que muestre Splash, luego Onboarding o Login, y Home si `hasSession()` es verdadero. Con eso se cumple lo que esperaba el comentario de `login_screen.dart:49`.
7. **Retirar Firebase:**
   - Quitar `firebase_core`, `firebase_auth` y `cloud_firestore` de `pubspec.yaml`.
   - Borrar `auth_service_firebase.dart`, o conservarlo fuera de `lib/`, según decida el equipo.
   - Con esto desaparece también el aviso del plugin de Kotlin (KGP).
8. **Android:**
   - Añadir `INTERNET` al `AndroidManifest.xml` de `main`.
   - Permitir HTTP sin cifrar **solo en debug** (`network_security_config` para `10.0.2.2`).
9. **Guardar el token:** con `flutter_secure_storage` (recomendado) o `shared_preferences` (decisión D2).

Ninguno de estos pasos cambia colores, tipografías, espacios ni la distribución de las pantallas.
