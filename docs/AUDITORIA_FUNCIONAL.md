# Auditoría funcional del frontend: Validei

- **Fecha:** 2026-10-14
- **Alcance:** los 40 archivos de `lib/` (3.171 líneas)
- **Método:** lectura completa del código, más pruebas ejecutadas

## Cómo se verificó

| Tipo de evidencia | Detalle |
|---|---|
| **[T] Test** | Test de widgets temporal: 23 casos sobre una pantalla de Pixel 8 (1080×2400, densidad 2,625). Se borró después de ejecutarlo. |
| **[D] Dispositivo** | Emulador Pixel_8 con Android 17 (API 37), APK de depuración, `adb input` y capturas de pantalla, y `logcat`. |
| **[C] Código** | Conclusión sacada solo de leer el código, sin ejecutarlo. |

> **Aviso sobre los desbordamientos.** En los tests aparecieron *RenderFlex overflow* en `CustomFormText`, en el Drawer y en OTP. Esos tests no cargan la fuente Poppins. En el dispositivo, con Poppins, el formulario de donante y el Drawer se ven sin desbordamientos [D]. Por eso **no se cuentan como defectos**.

---

## 1. Arquitectura actual

```
lib/
├── main.dart                     # Provisional (Fase 0). initialRoute = HomeScreen. Sin Firebase.initializeApp
└── src/
    ├── constants/validators.dart # passwordValidator, emailvalidator, nameValidator
    ├── general/config/           # AppColor, AppConfig.appName
    ├── general/utils/            # responsive.dart, blank_space.dart
    ├── repositories/auth_repository.dart     # Interfaz abstracta: login(), register()
    ├── services/auth_service_firebase.dart   # Implementación Firebase Auth + Firestore
    └── screens/
        ├── main_screen.dart      # Scaffold vacío, sin uso
        └── views/                # 15 pantallas + 20 widgets
```

**Observaciones:**

- **Modelos de datos:** no hay ninguno. No existen clases de dominio, DTO ni `fromJson`/`toJson`. Todo el contenido de las pantallas es texto fijo.
- **Estado:** cada widget guarda su propio estado con `setState`. No se usa Provider, Bloc ni Riverpod.
- **Patrón repositorio:** está iniciado solo para la autenticación (`AuthRepository`). `sendPasswordResetEmail` está en la clase Firebase pero no en la interfaz.
- **Navegación:** mezcla rutas con nombre (`pushNamed`) y `MaterialPageRoute` directo.
- **Dependencias:**

| Paquete | Dónde se usa |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Autenticación |
| `introduction_screen` | Onboarding |
| `form_field_validator` | Validadores |
| `flutter_otp_kit` | Pantalla OTP |

## 2. Rutas

### Rutas registradas en `main.dart`

| Ruta | Pantalla | Cómo se llega |
|---|---|---|
| `/home-screen` (inicial) | `HomeScreen` | Arranque de la app |
| `/splash-screen` | `SplashScreen` | Ninguna pantalla navega hacia ella |
| `/login-screen` | `LoginScreen` | Onboarding y Register, con `MaterialPageRoute` |
| `/register-screen` | `RegisterScreen` | Login |
| `/donor-registraion` *(sic)* | `DonorRegistrationForm` | Home |
| `/find-donor` | `FindDonorScreen` | Home |
| `/all-request` | `AllRequestScreen` | Home (tarjeta y "See all") |
| `/profile` | `ProfileScreen` | Avatar del AppBar |
| `/request-details-screen` | `RequestDetailsScreen` | Botón "Details" del feed |

### Pantallas sin ruta registrada

Se abren con `MaterialPageRoute`, salvo las que se indican:

- `OnboardingScreen`
- `ForgotPasswordScreen`
- `OtpRecoveryScreen`
- `RecoveryScreen`: no se puede llegar a ella. La navegación está comentada en `forgot_password_screen.dart:111`.
- `EditProfileScreen`: **el archivo está vacío (0 líneas)**. La clase no existe.
- `MainScreen`: Scaffold vacío y sin uso.

### Flujo previsto por el código

Splash (3 s) → Onboarding → Login → (Home).

En la práctica no funciona: `main.dart` arranca directamente en Home, y Login falla sin Firebase.

## 3. Inventario por pantalla

**Leyenda:**

| Código | Significado |
|---|---|
| ✅ | Implementada y comprobada |
| 🟡 | Implementada parcialmente |
| ❌ | No implementada |
| 🔒 | Bloqueada por la falta de backend o Firebase |
| ❔ | No verificada |

### 3.1 SplashScreen (`onboarding/splash_screen.dart`)

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Imagen `splash.png` a pantalla completa | ✅ | [T] |
| Pasa a Onboarding a los 3 s | ✅ | [T] |
| Es la entrada de la app | ❌ | [C] `main.dart` usa Home como ruta inicial |

### 3.2 OnboardingScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| 3 páginas: Save lives, Secure, Easy to Use | ✅ | [T] La página 1 se ve correctamente |
| Botones "Skip" y "Let's Start!" llevan a Login | 🔒 | [T] Navegan, pero Login lanza `[core/no-app] No Firebase App` |
| Textos | 🟡 | [C] Son *Lorem ipsum* |
| `onDone` | ❌ | [C] Está vacío. No afecta porque `showDoneButton: false` |

### 3.3 LoginScreen (`auth/login_screen.dart`)

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Construir la pantalla | 🔒 | [T] Excepción `[core/no-app]` al crear `AuthServiceFirebase()`, que inicializa `FirebaseAuth.instance` como campo |
| Validación de email y contraseña | ❔ | [C] Contraseña: mínimo 8 caracteres y al menos uno especial. No se probó por el bloqueo anterior |
| Mostrar u ocultar contraseña | ❔ | [C] Implementado |
| Autenticación | 🔒 | [C] Usa Firebase `signInWithEmailAndPassword` |
| **Navegar a Home tras iniciar sesión** | ❌ | [C] El comentario de la línea 49 espera un `StreamBuilder` en `main.dart` que **no existe**. Si el login funcionara, la pantalla se quedaría en "cargando" |
| Enlaces "Forgot Your Password?" y "Register Here" | ❔ | [C] Implementados con `Navigator.push` |

### 3.4 RegisterScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Construir la pantalla | 🔒 | [T] Excepción `[core/no-app]` |
| Campos nombre, email, contraseña y confirmación | 🟡 | [C] Se valida cada campo, pero **no se comprueba que las dos contraseñas coincidan** (pendiente según `validators.dart:20`) |
| Botón "Show Password" | ❌ | [C] `onPressed: (){}` |
| Registro | 🔒 | [C] Firebase Auth y documento `users/{uid}` en Firestore con uid, name, email, phone="" y creationDate |
| Tras registrarse | 🟡 | [C] Hace `push` a Login, con lo que la pila de pantallas crece. El login, en cambio, no navega |
| Diferencia de `trim()` | ⚠️ | [C] El registro recorta los espacios de la contraseña y el login no. Una contraseña con espacios al final nunca coincidiría |

### 3.5 ForgotPasswordScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Construir la pantalla | 🔒 | [C] Crea `AuthServiceFirebase()` igual que Login, así que se espera el mismo `[core/no-app]` |
| Validar el email y el botón "X" para limpiar el campo | ❔ | [C] |
| Enviar el enlace de recuperación | 🔒 | [C] Firebase `sendPasswordResetEmail` |
| "Verify Using Number Here" lleva a OTP | ❔ | [C] |
| Pasar a RecoveryScreen | ❌ | [C] Está comentado. Hay un import sin usar (aviso de `flutter analyze`) |

### 3.6 RecoveryScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Campos código, nueva contraseña y confirmación | 🟡 | [T] Se construye. No hay `Form` ni validadores |
| Botón "RESET PASSWORD" | ❌ | [T] La acción está vacía |
| Botones "X" | ❌ | [C] Hacen `setState(() {})` vacío |
| Se puede llegar a ella | ❌ | [C] No |

### 3.7 OtpRecoveryScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Interfaz de `OtpKit` | ✅ | [T] Se construye |
| Verificar y reenviar el código | ❌ | [C] `verifyOtpWithBackend` y `resendOtp` están vacías. El botón "Verify" tiene `action: (){}` |
| Indicar el número de teléfono | ❌ | [C] Ninguna pantalla pide el teléfono |

### 3.8 HomeScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Se muestra al arrancar | ✅ | [T][D] |
| Tarjeta "Find a donor" | ✅ | [T] Abre `FindDonorScreen` |
| Tarjeta "Requests" | ✅ | [T] Abre `AllRequestScreen` |
| Tarjeta "I want to donate" | ✅ | [T][D] Abre `DonorRegistrationForm` |
| "See all" | ✅ | [T] Abre `AllRequestScreen` |
| Botón "Details" del feed | ✅ | [T] Abre `RequestDetailsScreen`, pero **sin indicar qué solicitud** |
| Avatar | ✅ | [T] Abre `ProfileScreen` |
| Icono de menú | ✅ | [D] Abre el Drawer |
| Feed de solicitudes | 🔒 | [C] Son 10 copias del mismo elemento fijo (`CustomRequestFeedItem` es `const` y no recibe parámetros) |

### 3.9 HomeDrawer (`components/widgets/home_drawer.dart`)

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Se ve correctamente | ✅ | [D] |
| Botón "X" para cerrar | ❔ | [C] `Navigator.pop` |
| Donor Registration, Find Donors, Blood Requests y Profile | ❌ | [T] Al pulsarlos no pasa nada y el Drawer sigue abierto. [C] `custom_drawer_item.dart:22` tiene `//Navigator.pushNamed(context, onTapp);` comentado |
| Logout | ❌ | [T] No ocurre nada, ni siquiera la excepción de Firebase. [C] El `InkWell` interno de `CustomDrawerItem` absorbe el toque, así que `TextButton.onPressed` y `signOut()` nunca se ejecutan |
| Nombre de usuario | 🔒 | [C] Fijo: "Jorge Perez" |
| Tecla *Back* con el Drawer abierto | ⚠️ | [D] Visto 2 de 2 veces en API 37: **la app se cierra y vuelve al launcher** en lugar de cerrar el Drawer |

### 3.10 FindDonorScreen ("Request for Blood Donor" / "Patient Details")

> **Nota:** por su título y sus campos, esta pantalla es en realidad un **formulario para crear una solicitud de sangre**. No es un buscador de donantes, y no existe ninguna pantalla de resultados.

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Interfaz: grupo sanguíneo, bolsas, contacto, contacto de emergencia, paciente, caso, género, fecha límite y otros | ✅ | [T] Se construye |
| Selección de grupo sanguíneo y de género | 🟡 | [C] Funciona dentro del widget, pero **no comunica el valor elegido** (no hay callback). Vienen preseleccionados A+ y male |
| Campos de texto | 🟡 | [C] `CustomFormTextfield` acepta un `controller`, pero **ninguna pantalla le pasa uno**. Los valores no se pueden leer. No hay validación |
| Calendario "Blood Need Before" | 🟡 | [T][D] Se abre. **Si se cancela, la app falla con `Null check operator used on a null value`** (`find_donor_date_picker.dart:26`). Acepta fechas pasadas (de 2000 a 2050) y la fecha elegida no se comunica al formulario |
| Botón "Find Donors" | ❌ | [T] `CustomRedBtn` no tiene parámetro `onTap` |
| No hay campo "Location" | ⚠️ | [C] El feed y el detalle sí muestran una ubicación |

### 3.11 AllRequestScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Filtro horizontal (All y los 8 grupos) | 🟡 | [C] Cambia el elemento seleccionado, pero no filtra nada ni comunica el valor |
| Lista de solicitudes | 🔒 | [C] 6 elementos fijos escritos a mano |
| Botón "Details" | ✅ | [T] Desde Home |

### 3.12 RequestDetailsScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Ocho datos: fecha límite, paciente, ubicación, grupo, contacto, causa, bolsas y otros | 🔒 | [C] Todo fijo. No recibe argumentos |
| Botones "Call" y "Message" | ❌ | [T] `CustomCallButton` no tiene `onTap` |

### 3.13 DonorRegistrationForm ("I want to donate")

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Interfaz | ✅ | [T][D] Se ve correctamente |
| Foto con cámara o galería | ❌ | [C] Son iconos `Image.asset` sin acción y no hay ningún paquete de selección de imágenes |
| Nombre, contacto y ubicación | 🟡 | [C] Sin `controller` ni validación |
| Grupo sanguíneo | 🟡 | [C] Igual que en 3.10 |
| "Last Date of Donation" | 🟡 | [D] El mismo widget que en 3.10, con el mismo fallo al cancelar. Acepta fechas futuras |
| Botón "Complete" | ❌ | [T] Sin acción |

### 3.14 ProfileScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Nombre, ubicación, género, grupo y teléfono | 🔒 | [C] Valores fijos ("Jorge Perez", "B+"…) |
| Botón "Edit Profile" | ❌ | [T] Sin acción |

### 3.15 EditProfileScreen

| Funcionalidad | Estado | Evidencia |
|---|---|---|
| Pantalla de edición | ❌ | [C] `edit_profile_screen.dart` tiene **0 bytes**. No hay diseño de referencia |

## 4. Componentes reutilizables

| Widget | Uso | Observación |
|---|---|---|
| `CustomAppBar` | 5 pantallas | Volver con `pop` y avatar que lleva a Profile. Funciona [T] |
| `MainButton` | Pantallas de autenticación | Recibe `action` e `isLoading`. Funciona |
| `CustomRedBtn` y `CustomCallButton` | Formularios, Perfil y Detalle | **No tienen callback**, así que ningún botón que los use hace nada |
| `CustomFormTextfield` | Formularios | Acepta `controller`, pero nadie se lo pasa |
| `CustomBloodGroupBox`, `CustomGenderBox` y `CustomBloodFilterBox` | Selectores | Solo estado interno, sin `onChanged` |
| `FindDonorDatePicker` | 2 formularios | Falla al cancelar y no comunica la fecha |
| `CustomRequestFeedItem` | Home y Requests | `const` sin parámetros, con datos fijos |
| `RequestDetailsItem` | Detalle y Perfil | Recibe parámetros. Sirve para datos reales |
| Sin uso | — | `CustomBloodGroupIcon`, `BloodGroupFilterIcon`, `CustomGenderBtn`, `CustomAuthText` y `MainScreen` |

## 5. Validadores (`constants/validators.dart`)

| Validador | Reglas | Dónde se usa |
|---|---|---|
| `passwordValidator` | Obligatoria, mínimo 8 caracteres, al menos uno de `#?!@$%^&*-` | Login y Register |
| `emailvalidator` | Obligatorio y con formato de email | Login, Register y Forgot |
| `nameValidator` | Obligatorio | Register |

Falta:

- Comprobar que la contraseña y su confirmación coinciden.
- Cualquier validación en los formularios de solicitud y de donante.

## 6. Dependencias de Firebase

| Ubicación | Uso | Impacto |
|---|---|---|
| `services/auth_service_firebase.dart` | `FirebaseAuth.instance` y `FirebaseFirestore.instance` como campos | Falla al crear cualquier pantalla que lo instancie |
| `auth/login_screen.dart:19` | `AuthServiceFirebase()` | Pantalla bloqueada [T] |
| `auth/register_screen.dart:21` | `AuthRepository _authService = AuthServiceFirebase()` | Pantalla bloqueada [T] |
| `auth/forgot_password_screen.dart:20` | `AuthServiceFirebase()`, usando el tipo concreto | Bloqueada [C] |
| `widgets/home_drawer.dart:91` | `FirebaseAuth.instance.signOut()` | Nunca se ejecuta (ver 3.9) |

Además:

- **Configuración que falta:** `google-services.json`, el plugin `com.google.gms.google-services` y la llamada a `Firebase.initializeApp()`.
- **Aviso de compilación:** `firebase_auth` y `firebase_core` usan el plugin de Kotlin para Gradle (KGP). Flutter avisa de que en versiones futuras dejará de compilar los plugins que lo usen.

## 7. Datos fijos en el código

| Dato | Pantallas |
|---|---|
| "Jorge Perez" | Feed, Detalle, Perfil y Drawer |
| "A+" / "AB+" / "B+" | Feed, Detalle y Perfil (no coinciden entre sí) |
| "2 Bag \| Accident", "2 minute ago", "10 February 2024" | Feed |
| "Santo Domingo, DN/RD" | Feed, Detalle y Perfil |
| "+18092249304" | Detalle y Perfil |
| "Cancer Patient", "2 Bags", "Need very urgent" | Detalle |
| "Male" | Perfil |
| `assets/images/profile.png` | Avatar de AppBar, Drawer y Perfil |
| 10 elementos (Home) y 6 (Requests) | Listas |
| Textos *Lorem ipsum* | Onboarding |

Los textos de ayuda de los campos ("+880…", "Jorge Perez", "3"…) son solo ejemplos visuales, no datos.

## 8. Otros hallazgos de Android

- El permiso `INTERNET` solo está en `android/app/src/debug/AndroidManifest.xml`. Hay que añadirlo al manifiesto `main` para que la versión *release* pueda llamar a la API.
- Para llamar al backend local por HTTP (`10.0.2.2:8080`) en desarrollo hay que permitir tráfico sin cifrar, solo en el build de depuración.
