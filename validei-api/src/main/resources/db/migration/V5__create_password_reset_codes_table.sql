-- Códigos de recuperación de contraseña (ForgotPassword -> OTP -> Recovery).
-- Solo se guarda el hash BCrypt del código; consumed_at marca códigos usados, agotados o reemplazados.
CREATE TABLE password_reset_codes (
    id              BIGINT      NOT NULL AUTO_INCREMENT,
    user_id         BIGINT      NOT NULL,
    code_hash       VARCHAR(100) NOT NULL,
    expires_at      DATETIME(6) NOT NULL,
    failed_attempts INT         NOT NULL DEFAULT 0,
    consumed_at     DATETIME(6) NULL,
    created_at      DATETIME(6) NOT NULL,

    CONSTRAINT pk_password_reset_codes PRIMARY KEY (id),
    CONSTRAINT fk_password_reset_codes_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT ck_password_reset_codes_attempts CHECK (failed_attempts >= 0),
    INDEX idx_password_reset_codes_user_created (user_id, created_at)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;
