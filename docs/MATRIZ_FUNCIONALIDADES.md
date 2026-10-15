# Matriz de funcionalidades: Validei

Los códigos de estado y de evidencia ([T] test, [D] dispositivo, [C] código) se explican en [AUDITORIA_FUNCIONAL.md](AUDITORIA_FUNCIONAL.md).

## 1. Resumen

| Estado | Cantidad | Funcionalidades |
|---|---|---|
| ✅ Implementada y comprobada | 14 | Splash con temporizador, páginas del onboarding, navegación desde Home (6 accesos), apertura del Drawer, interfaz de los formularios, AppBar con "volver" y avatar, apertura del calendario, interfaz OTP |
| 🟡 Parcial | 9 | Selector de grupo y selector de género (no comunican el valor), campos de texto (sin controller), calendario (falla al cancelar), filtro de solicitudes, validación del registro (sin confirmar contraseña), RecoveryScreen (sin `Form`), textos del onboarding, navegación tras registrarse |
| ❌ No implementada | 16 | Ver sección 2 |
| 🔒 Bloqueada por backend o Firebase | 9 | Login, Registro, Forgot password, feed, listado, detalle, perfil, nombre en el Drawer, Onboarding → Login |
| ❔ No verificada | 5 | Validadores de Login y Registro en ejecución, mostrar u ocultar contraseña en Login, enlaces Login ↔ Register ↔ Forgot, botón "X" de Forgot, botón cerrar del Drawer |

## 2. Lista detallada

| ID | Funcionalidad | Pantalla | Estado | Evidencia | Requiere backend | Requiere tocar el frontend (sin cambiar el diseño) |
|---|---|---|---|---|---|---|
| F01 | La app arranca en Splash y sigue a Onboarding y Login | main, Splash | 🟡 | [T] Funciona si se abre Splash; `main` arranca en Home | No | Ruta inicial y comprobación de sesión en `main.dart` |
| F02 | Iniciar sesión | Login | 🔒 | [T] `[core/no-app]` | Sí | Cambiar `AuthServiceFirebase` por el servicio API; navegar a Home al iniciar sesión |
| F03 | Registrar usuario | Register | 🔒 | [T] | Sí | Cambiar el servicio; validar la confirmación de contraseña |
| F04 | Confirmar que las contraseñas coinciden | Register | ❌ | [C] | No | Validador |
| F05 | Botón "Show Password" en Registro | Register | ❌ | [C] | No | Lógica del `onPressed` |
| F06 | Pedir la recuperación por email | Forgot | 🔒 | [C] | Sí, con envío de email | Cambiar el servicio; ampliar `AuthRepository` |
| F07 | Restablecer la contraseña con un código | Recovery | ❌ | [T] | Sí | Hacer accesible la pantalla, añadir `Form` y acción |
| F08 | Verificar por SMS (OTP) | OTP | ❌ | [C] | Sí, con proveedor de SMS | Funciones `verify` y `resend`, y el número de teléfono |
| F09 | Cerrar sesión | Drawer | ❌ | [T] | Sí (o solo borrar el token en el móvil) | Arreglar el toque y cambiar `FirebaseAuth` por el servicio |
| F10 | Navegar desde el Drawer (4 elementos) | Drawer | ❌ | [T] | No | Activar `Navigator.pushNamed` en `CustomDrawerItem` |
| F11 | Back con el Drawer abierto cierra la app | Drawer | ⚠️ defecto | [D] 2 de 2 veces | No | Investigar el *predictive back* de API 37 |
| F12 | Nombre de usuario en el Drawer | Drawer | 🔒 | [C] | Sí | Leer el usuario de la sesión |
| F13 | Feed de solicitudes (Home) | Home | 🔒 | [C] | Sí | `CustomRequestFeedItem` debe recibir un modelo |
| F14 | Listado de solicitudes | AllRequests | 🔒 | [C] | Sí | Lista dinámica |
| F15 | Filtrar por grupo sanguíneo | AllRequests | 🟡 | [C] | Sí | `onChanged` en `CustomBloodFilterBox` |
| F16 | Detalle de una solicitud | RequestDetails | 🔒 | [C] | Sí | Recibir el `id` como argumento de la ruta |
| F17 | Llamar al contacto | RequestDetails | ❌ | [T] | No (intent `tel:`) | `onTap` en `CustomCallButton`; paquete `url_launcher` |
| F18 | Enviar un mensaje al contacto | RequestDetails | ❌ | [T] | No (intent `sms:`) | Igual que F17 |
| F19 | Crear una solicitud de sangre | FindDonor | ❌ | [T] Botón inerte | Sí | Controllers, callbacks y `onTap` en `CustomRedBtn` |
| F20 | Elegir grupo y género | FindDonor, DonorReg | 🟡 | [C] | No | Añadir `onChanged` |
| F21 | Calendario | FindDonor, DonorReg | 🟡 | [T][D] Falla al cancelar | No | Comprobar si la fecha es nula; añadir `onChanged` |
| F22 | Ubicación de la solicitud | FindDonor | ⚠️ | [C] No hay campo | Sí | **Decisión D4** |
| F23 | Registrarse como donante | DonorReg | ❌ | [T] Botón inerte | Sí | Controllers, callbacks y `onTap` |
| F24 | Foto del donante (cámara o galería) | DonorReg | ❌ | [C] | Sí (subida de archivo) | Paquete `image_picker` y acción en los iconos: **decisión D6** |
| F25 | Ver el perfil | Profile | 🔒 | [C] | Sí | Datos dinámicos |
| F26 | Botón "Edit Profile" | Profile | ❌ | [T] | No | `onTap` |
| F27 | Pantalla de edición del perfil | EditProfile | ❌ | [C] Archivo vacío | Sí | **Falta el diseño: decisión D7** |
| F28 | Buscar donantes (resultados) | — | ❌ | [C] No existe la pantalla | Sí | **Decisión D3** |
| F29 | Mostrar u ocultar contraseña en Login | Login | ❔ | [C] | No | — |
| F30 | Avatar del AppBar lleva a Perfil | Todas | ✅ | [T] | No | — |
| F31 | Tarjetas, "See all" y "Details" de Home | Home | ✅ | [T] | No | — |
| F32 | Volver (`CustomAppBar`) | Secundarias | ✅ | [C][D] | No | — |
| F33 | Splash y Onboarding | Onboarding | ✅ / 🟡 | [T] Textos *Lorem ipsum* | No | — (los textos son del profesor) |

## 3. Pantallas, endpoints y entidades

Los endpoints están en [CONTRATOS_API.md](CONTRATOS_API.md) y las entidades en [MODELO_DATOS.md](MODELO_DATOS.md).

| Pantalla Flutter | Acción del usuario | Endpoint(s) | Entidad(es) |
|---|---|---|---|
| SplashScreen / main | Comprobar si hay sesión | `GET /api/v1/users/me` (con el token guardado) | `users` |
| OnboardingScreen | — | — | — |
| LoginScreen | "LOGIN" | `POST /api/v1/auth/login` | `users` |
| RegisterScreen | "REGISTER" | `POST /api/v1/auth/register` | `users` |
| ForgotPasswordScreen | "SEND" | `POST /api/v1/auth/password/forgot` | `users`, `password_reset_codes` |
| RecoveryScreen | "RESET PASSWORD" | `POST /api/v1/auth/password/reset` | `users`, `password_reset_codes` |
| OtpRecoveryScreen | "Verify" / "Resend" | *Diferido (D5)* | — |
| HomeScreen | Feed (10 elementos) | `GET /api/v1/blood-requests?page=0&size=10` | `blood_requests` |
| HomeScreen / Drawer / AppBar | Nombre y avatar | `GET /api/v1/users/me` | `users`, `donors` |
| HomeDrawer | Logout | `POST /api/v1/auth/logout` (opcional) y borrar el token | — |
| FindDonorScreen | "Find Donors" (crear solicitud) | `POST /api/v1/blood-requests` | `blood_requests`, `users` |
| AllRequestScreen | Listar y filtrar | `GET /api/v1/blood-requests?bloodGroup=…` | `blood_requests` |
| RequestDetailsScreen | Ver detalle | `GET /api/v1/blood-requests/{id}` | `blood_requests` |
| RequestDetailsScreen | Call / Message | Ninguno (intents del dispositivo) | — |
| DonorRegistrationForm | Cargar datos previos | `GET /api/v1/donors/me` | `donors` |
| DonorRegistrationForm | "Complete" | `PUT /api/v1/donors/me` | `donors`, `users` |
| DonorRegistrationForm | Foto | `PUT /api/v1/donors/me/photo` *(D6)* | `donors` |
| ProfileScreen | Ver perfil | `GET /api/v1/users/me` | `users`, `donors` |
| EditProfileScreen | Guardar | `PATCH /api/v1/users/me` *(D7)* | `users` |
| *(sin pantalla)* | Buscar donantes | `GET /api/v1/donors?bloodGroup=…` *(D3)* | `donors` |
