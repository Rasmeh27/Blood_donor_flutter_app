# Modelo de datos (MySQL 8): Validei

**Criterio:** cada entidad y cada campo salen de un campo o una pantalla que ya existe en `lib/`. Lo que no tiene esa base se marca como **diferido** y no forma parte del esquema inicial.

## 1. Entidades y de dónde salen

| Entidad | Incluida | En qué se basa |
|---|---|---|
| `users` | **Sí** | Register (nombre, email, contraseña), Login, Firestore `users/{uid}` (uid, name, email, phone, creationDate), Profile (género, ubicación, teléfono) |
| `donors` | **Sí** | DonorRegistrationForm (foto, nombre, contacto, grupo, ubicación, fecha de la última donación). Profile muestra "Blood Group" |
| `blood_requests` | **Sí** | FindDonorScreen (los 9 campos), feed (tiempo transcurrido, ubicación), RequestDetailsScreen (8 campos) |
| Grupo sanguíneo | **Como enum**, sin tabla | Lista fija de 8 valores en `CustomBloodGroupBox` y `CustomBloodFilterBox` ("All" es solo un filtro) |
| Perfil | **Sin tabla** | Profile es una **vista** que combina `users` y `donors` (ver 4) |
| `password_reset_codes` | **Sí** (soporte) | ForgotPasswordScreen y RecoveryScreen (campo "# reset code") |
| Respuestas a solicitudes | **Diferida** | Ninguna pantalla permite responder. "Call" y "Message" usan el teléfono del dispositivo |
| Historial de donaciones | **Diferida** | Solo existe "Last Date of Donation" (un único valor). Ninguna pantalla muestra un historial |

## 2. Diagrama

```
users 1 ──── 0..1 donors
  │
  ├── 1 ──── 0..N blood_requests   (requester_id)
  │
  └── 1 ──── 0..N password_reset_codes
```

## 3. Tablas

### 3.1 `users`

| Columna | Tipo | Restricciones | Origen en la interfaz |
|---|---|---|---|
| `id` | BIGINT | PK, AUTO_INCREMENT | uid de Firebase |
| `full_name` | VARCHAR(100) | NOT NULL | Register: "Enter your name" |
| `email` | VARCHAR(150) | NOT NULL, UNIQUE | Register y Login |
| `password_hash` | VARCHAR(100) | NOT NULL (BCrypt) | Register y Login |
| `phone` | VARCHAR(20) | NULL | Firestore `phone: ""`; Profile: "Mobile Number" |
| `gender` | VARCHAR(10) | NULL; `MALE` o `FEMALE` | Profile: "Gender" (los valores salen de `CustomGenderBox`) |
| `location` | VARCHAR(150) | NULL | Profile: "Location" |
| `created_at` | DATETIME(6) | NOT NULL, por defecto la hora actual | Firestore `creationDate` |
| `updated_at` | DATETIME(6) | NOT NULL | Auditoría |

> Ninguna pantalla pide hoy `phone`, `gender` ni `location` del usuario. Quedan nulos hasta que exista Edit Profile (decisión D7).

### 3.2 `donors` (1:1 con `users`)

| Columna | Tipo | Restricciones | Origen en la interfaz |
|---|---|---|---|
| `id` | BIGINT | PK, AUTO_INCREMENT | — |
| `user_id` | BIGINT | NOT NULL, UNIQUE, FK → `users.id` ON DELETE CASCADE | Un usuario se registra como donante una sola vez |
| `full_name` | VARCHAR(100) | NOT NULL | "Name" (obligatorio) |
| `contact_number` | VARCHAR(20) | NOT NULL | "Contact Number" (obligatorio) |
| `blood_group` | VARCHAR(3) | NOT NULL; uno de los 8 valores | "Blood Group" (obligatorio) |
| `location` | VARCHAR(150) | NOT NULL | "Location" (obligatorio) |
| `last_donation_date` | DATE | NOT NULL | "Last Date of Donation" (obligatorio) |
| `photo_url` | VARCHAR(255) | NULL mientras no se decida D6 | "Select Donor picture" (marcado como obligatorio en la interfaz) |
| `created_at` / `updated_at` | DATETIME(6) | NOT NULL | — |

Índice: `idx_donors_blood_group (blood_group)`, para la búsqueda de donantes si se decide implementarla (D3).

### 3.3 `blood_requests`

| Columna | Tipo | Restricciones | Origen en la interfaz |
|---|---|---|---|
| `id` | BIGINT | PK, AUTO_INCREMENT | Argumento de RequestDetails |
| `requester_id` | BIGINT | NOT NULL, FK → `users.id` | Usuario con sesión que crea la solicitud |
| `blood_group` | VARCHAR(3) | NOT NULL | "Choose Blood Group" (obligatorio); feed y detalle |
| `bags` | TINYINT UNSIGNED | NOT NULL, ≥ 1 | "Number of Bags" (obligatorio); feed: "2 Bag" |
| `contact_number` | VARCHAR(20) | NOT NULL | "Contact Number" (obligatorio); detalle y botón "Call" |
| `emergency_contact` | VARCHAR(20) | NOT NULL | "Emergency Contact" (obligatorio) |
| `patient_name` | VARCHAR(100) | NOT NULL | "Patient Name" (obligatorio); feed y detalle |
| `case_description` | VARCHAR(150) | NOT NULL | "Case" (obligatorio); feed: "Accident"; detalle: "Cause" |
| `patient_gender` | VARCHAR(10) | NULL; `MALE` o `FEMALE` | "Gender" (opcional) |
| `need_before` | DATE | NOT NULL | "Blood Need Before" (obligatorio); feed y detalle: "Blood want before" |
| `location` | VARCHAR(150) | NULL (ver D4) | Feed y detalle muestran "Location", pero el formulario no tiene ese campo |
| `others` | VARCHAR(255) | NULL | "Others" (opcional) |
| `created_at` | DATETIME(6) | NOT NULL | Feed: "2 minute ago" |

Índice: `idx_requests_group_created (blood_group, created_at DESC)`, para el feed y el filtro.

> No se añade una columna de estado (abierta o cerrada) porque ninguna pantalla la muestra ni la cambia. Si se quiere ocultar las solicitudes vencidas, puede filtrarse por `need_before >= hoy` (decisión D9).

### 3.4 `password_reset_codes`

| Columna | Tipo | Restricciones |
|---|---|---|
| `id` | BIGINT | PK |
| `user_id` | BIGINT | NOT NULL, FK → `users.id` ON DELETE CASCADE |
| `code_hash` | VARCHAR(100) | NOT NULL (el código nunca se guarda en claro) |
| `expires_at` | DATETIME(6) | NOT NULL (propuesta: 15 minutos) |
| `used_at` | DATETIME(6) | NULL |
| `created_at` | DATETIME(6) | NOT NULL |

## 4. Perfil: de dónde sale cada dato (decisión D8, propuesta)

| Campo en Profile | Fuente |
|---|---|
| Name | `users.full_name` |
| Location | `donors.location` si existe; si no, `users.location` |
| Gender | `users.gender` |
| Blood Group | `donors.blood_group`; si no es donante, `null` (la interfaz mostraría "—") |
| Mobile Number | `users.phone` si existe; si no, `donors.contact_number` |
| Avatar | `donors.photo_url`; si no hay, `assets/images/profile.png` |

## 5. Enum `BloodGroup` (Java)

Se guarda en la base de datos como el texto que ve el usuario:

```java
public enum BloodGroup {
  A_POS("A+"), B_POS("B+"), AB_POS("AB+"), O_POS("O+"),
  A_NEG("A-"), B_NEG("B-"), AB_NEG("AB-"), O_NEG("O-");
}
```

- Se recomienda usar un `AttributeConverter` para guardar `"A+"` tal cual.
- El código **no** contiene reglas de compatibilidad entre grupos. No se añaden.

## 6. Esquema inicial propuesto (migración `V1__init.sql`)

```sql
CREATE TABLE users (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  phone         VARCHAR(20)  NULL,
  gender        VARCHAR(10)  NULL,
  location      VARCHAR(150) NULL,
  created_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT uk_users_email UNIQUE (email),
  CONSTRAINT ck_users_gender CHECK (gender IN ('MALE','FEMALE'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE donors (
  id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id            BIGINT       NOT NULL,
  full_name          VARCHAR(100) NOT NULL,
  contact_number     VARCHAR(20)  NOT NULL,
  blood_group        VARCHAR(3)   NOT NULL,
  location           VARCHAR(150) NOT NULL,
  last_donation_date DATE         NOT NULL,
  photo_url          VARCHAR(255) NULL,
  created_at         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT uk_donors_user UNIQUE (user_id),
  CONSTRAINT fk_donors_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT ck_donors_bg CHECK (blood_group IN ('A+','B+','AB+','O+','A-','B-','AB-','O-')),
  INDEX idx_donors_blood_group (blood_group)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE blood_requests (
  id                BIGINT AUTO_INCREMENT PRIMARY KEY,
  requester_id      BIGINT           NOT NULL,
  blood_group       VARCHAR(3)       NOT NULL,
  bags              TINYINT UNSIGNED NOT NULL,
  contact_number    VARCHAR(20)      NOT NULL,
  emergency_contact VARCHAR(20)      NOT NULL,
  patient_name      VARCHAR(100)     NOT NULL,
  case_description  VARCHAR(150)     NOT NULL,
  patient_gender    VARCHAR(10)      NULL,
  need_before       DATE             NOT NULL,
  location          VARCHAR(150)     NULL,
  others            VARCHAR(255)     NULL,
  created_at        DATETIME(6)      NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_requests_user FOREIGN KEY (requester_id) REFERENCES users(id),
  CONSTRAINT ck_requests_bg CHECK (blood_group IN ('A+','B+','AB+','O+','A-','B-','AB-','O-')),
  CONSTRAINT ck_requests_bags CHECK (bags >= 1),
  CONSTRAINT ck_requests_gender CHECK (patient_gender IN ('MALE','FEMALE')),
  INDEX idx_requests_group_created (blood_group, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE password_reset_codes (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id    BIGINT       NOT NULL,
  code_hash  VARCHAR(100) NOT NULL,
  expires_at DATETIME(6)  NOT NULL,
  used_at    DATETIME(6)  NULL,
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT fk_reset_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_reset_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

## 7. Entidades diferidas (no forman parte de V1)

Se incluyen como referencia para cuando exista una pantalla que las use.

- **`request_responses`** (`id`, `request_id` FK, `donor_id` FK, `status`, `created_at`). Requisito: una acción del tipo "Quiero donar a esta solicitud" en RequestDetails. Hoy solo hay Call y Message, que no pasan por el backend.
- **`donations`** (`id`, `donor_id` FK, `donation_date`, `request_id` FK nullable). Requisito: una pantalla de historial. Mientras no exista, basta con `donors.last_donation_date`.
