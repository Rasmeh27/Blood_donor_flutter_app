-- Datos mostrados en ProfileScreen: Location, Gender y Mobile Number.
-- Son opcionales porque el registro solo pide nombre, correo y contraseña.
ALTER TABLE users
    ADD COLUMN phone    VARCHAR(20)  NULL AFTER password_hash,
    ADD COLUMN gender   VARCHAR(10)  NULL AFTER phone,
    ADD COLUMN location VARCHAR(150) NULL AFTER gender,
    ADD CONSTRAINT ck_users_gender CHECK (gender IN ('MALE', 'FEMALE'));
