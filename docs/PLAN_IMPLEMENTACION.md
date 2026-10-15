# Plan de implementación: Validei

**Orden:** primero lo que bloquea a lo demás (dependencias) y, dentro de eso, por prioridad.

**Regla para todo el frontend:** solo se tocan la lógica, los parámetros y la navegación. Los colores, las tipografías, los tamaños, la distribución y las imágenes del profesor no cambian.

## 0. Decisiones pendientes (resolver antes o durante la fase indicada)

| ID | Decisión | Opciones | Recomendación | Bloquea |
|---|---|---|---|---|
| D1 | Envío de emails para recuperar la contraseña | SMTP de Gmail con contraseña de aplicación; Mailtrap o MailHog en desarrollo; dejarlo fuera del alcance | MailHog en Docker para desarrollo; SMTP real solo si se presenta en vivo | Fase 6 |
| D2 | Gestión de la sesión | JWT de acceso de 24 h sin refresh; JWT con *refresh token* | Un JWT de 24 h y logout borrando el token en el móvil; guardarlo con `flutter_secure_storage` | Fase 3 |
| D3 | Qué significa "Find Donors" | (a) crear una solicitud que aparece en el feed; (b) buscar donantes, para lo que falta una pantalla de resultados | **(a)**, porque es lo que respaldan el título y los campos | Fase 4 y `GET /donors` |
| D4 | Ubicación de la solicitud (el feed la muestra, el formulario no la pide) | Tomar la ubicación del perfil o del donante; dejarla nula; añadir un campo (cambia el diseño, requiere permiso) | Usar `users.location` o `donors.location` del solicitante; si no hay, nula | Fase 4 |
| D5 | OTP por SMS | Proveedor de pago (Twilio…); dejarlo fuera del alcance | Fuera del alcance; queda documentado | — |
| D6 | Foto del donante | `image_picker` y almacenamiento en disco o S3; posponerla | Posponerla. `photo_url` se deja nulo | Fase 7 |
| D7 | EditProfileScreen (archivo vacío y sin diseño) | Pedir el diseño al profesor; construirla con los widgets existentes | **Consultar al profesor**. Hasta entonces, sin implementar | Fase 7 |
| D8 | De dónde salen los datos de Profile (ubicación y teléfono) | Ver MODELO_DATOS §4 | La propuesta de §4 | Fase 5 |
| D9 | ¿Ocultar las solicitudes vencidas (`needBefore` pasado)? | Sí; no | No por ahora (no aparece en la interfaz) | Fase 4 |
| D10 | Migraciones de la base de datos | Flyway; `ddl-auto=update` | Flyway (V1 en MODELO_DATOS §6) | Fase 1 |
| D11 | MySQL local | Instalar MySQL Server 8.4; contenedor Docker `mysql:8.4` | Docker (ya está instalado) | Fase 1 |

## Fase 1: Base del backend (P1)

1. Instalar o levantar MySQL (D11) y crear la base `validei` con un usuario propio.
2. Crear el proyecto con Spring Initializr desde IntelliJ:

   | Opción | Valor |
   |---|---|
   | Lenguaje | Java 17 |
   | Build | Maven |
   | Group | `edu.intec` |
   | Artifact | `validei-backend` |
   | Dependencias | Web, Validation, Data JPA, MySQL Driver, Security, Flyway |

   Ubicarlo en una carpeta hermana del proyecto Flutter (`appmobiles/validei-backend`).
3. Configurar `application.yml` con perfiles `dev` y `test`. Las credenciales van en variables de entorno.
4. Crear la migración Flyway `V1__init.sql` (MODELO_DATOS §6).
5. Añadir un `GlobalExceptionHandler` que devuelva `ProblemDetail` con `errors[]`.
6. Configurar CORS y seguridad: rutas `/auth/**` públicas y el resto con token.
7. **Prueba:** el proyecto arranca, las migraciones se aplican y el health check responde 200.

## Fase 2: Autenticación en el backend (P1). Depende de la fase 1

1. Entidad `User`, repositorio y `PasswordEncoder` BCrypt.
2. `POST /auth/register` y `POST /auth/login`, con emisión y validación del JWT (filtro).
3. `GET /users/me`.
4. **Pruebas:** `@WebMvcTest` para la validación y un test de integración con MySQL (Testcontainers o base de prueba). Colección Postman: 201, 409, 400, 200, 401.

## Fase 3: Integración de la autenticación en Flutter (P1). Depende de la fase 2

1. Añadir los paquetes `http` y `flutter_secure_storage` (D2).
2. `api_client.dart` con la URL base por `--dart-define` y valor por defecto `http://10.0.2.2:8080/api/v1`.
3. Ampliar `AuthRepository` y crear `AuthServiceApi` (CONTRATOS_API §6).
4. Cambiar la instancia en Login, Register y ForgotPassword.
5. Puerta de sesión en `main.dart`: Splash → Onboarding/Login → Home. La ruta inicial pasa a ser Splash.
6. Navegar a Home al iniciar sesión (`pushNamedAndRemoveUntil`).
7. Validar que la confirmación de contraseña coincide (F04) y unificar el `trim()` entre Login y Register.
8. Drawer: arreglar el toque de Logout, llamar a `logout()` y volver a Login.
9. Android: permiso `INTERNET` en `main` y HTTP sin cifrar solo en debug.
10. Quitar las dependencias de Firebase de `pubspec.yaml` y confirmar con `flutter analyze`.
11. **Pruebas:** test de widgets de Login con `AuthRepository` simulado; recorrido completo en el emulador (registro → login → Home → logout).

## Fase 4: Solicitudes de sangre (P2). Depende de la fase 3

**Backend:**

1. Entidad `BloodRequest`, enum `BloodGroup` y su `AttributeConverter`.
2. `POST /blood-requests`, `GET /blood-requests` (paginado y con filtro) y `GET /blood-requests/{id}`.
3. Pruebas de validación y de paginación.

**Frontend** (solo parámetros, sin cambiar el aspecto):

1. `FindDonorDatePicker`: no fallar si la fecha es nula (bug confirmado) y añadir `onChanged(DateTime)`.
2. `CustomBloodGroupBox`, `CustomGenderBox` y `CustomBloodFilterBox`: añadir `onChanged`, opcional y con el mismo índice inicial.
3. `CustomRedBtn`: añadir `onTap` opcional, usando el mismo `Container` envuelto en `InkWell`.
4. FindDonorScreen: controllers, validación y llamada a `POST`.
5. Modelo `BloodRequestSummary` y `BloodRequestDetail` con `fromJson`.
6. `CustomRequestFeedItem`: recibir el modelo opcional y mostrar los datos reales con el mismo diseño.
7. Home y AllRequests: lista dinámica y filtro; estados de carga y de lista vacía con widgets mínimos neutros.
8. RequestDetails: recibir el `id` por argumentos de la ruta y cargar el detalle.
9. **Pruebas:** tests de los widgets ampliados y recorrido en el emulador (crear solicitud → aparece en el feed → abrir el detalle).

## Fase 5: Donantes y perfil (P3). Depende de la fase 4, porque reutiliza los widgets ya ampliados

1. Backend: entidad `Donor`, `GET /donors/me` y `PUT /donors/me`; ampliar `ProfileResponse` (D8).
2. Flutter: DonorRegistrationForm con controllers, validación y `PUT`.
3. Flutter: Profile, el nombre del Drawer y el avatar a partir de `GET /users/me`.
4. **Pruebas:** recorrido completo (registrarse como donante → ver el grupo en Profile).

## Fase 6: Recuperación de contraseña (P4). Depende de la fase 2 y de D1

1. Backend: tabla `password_reset_codes`, código de 6 dígitos válido 15 minutos, envío por SMTP, y `forgot` y `reset`.
2. Flutter: Forgot → Recovery pasando el email como argumento; `Form` y validadores en Recovery; acción del botón "RESET PASSWORD".

## Fase 7: Funciones complementarias (según las decisiones)

| Tarea | Decisión |
|---|---|
| Drawer: activar la navegación de los 4 elementos | Sin decisión pendiente; puede adelantarse a la fase 3 |
| Investigar por qué *Back* con el Drawer abierto cierra la app (API 37) | Sin decisión pendiente |
| Call y Message con `url_launcher` (`tel:` y `sms:`) | Sin backend |
| Foto del donante | D6 |
| EditProfileScreen y `PATCH /users/me` | D7 |
| Búsqueda de donantes `GET /donors` | D3 |
| OTP | D5 |

## Fase 8: Cierre

- `flutter analyze` sin errores nuevos, `flutter test`, y compilación *release* con `INTERNET`.
- Backend: `mvn verify` y colección Postman exportada en el repositorio del backend.
- Actualizar la documentación (`ENTORNO_DESARROLLO.md` y estos documentos).

## Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Ampliar los widgets del profesor altera el diseño sin querer | Alto (restricción del curso) | Solo parámetros opcionales con los valores por defecto actuales; comparar capturas antes y después en el Pixel 8 |
| No existe diseño de Edit Profile ni de los resultados de búsqueda | Medio | Decisiones D3 y D7 con el profesor antes de implementar |
| El formulario de solicitud no tiene ubicación | Bajo | D4: usar la ubicación del perfil |
| Sin SMTP, la recuperación de contraseña no se puede demostrar | Medio | MailHog en desarrollo |
| Snapshot del emulador desfasado (Fase 1) | Bajo | Arrancar en frío (*cold boot*), como indica `ENTORNO_DESARROLLO.md` |
| El aviso del plugin de Kotlin en Firebase podría romper la compilación en una futura versión de Flutter | Medio | Desaparece al retirar Firebase en la fase 3 |
