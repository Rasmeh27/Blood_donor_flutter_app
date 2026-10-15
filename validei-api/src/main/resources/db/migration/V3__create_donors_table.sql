-- Campos de DonorRegistrationForm. Cada usuario puede registrarse como donante una sola vez.
CREATE TABLE donors (
    id                 BIGINT       NOT NULL AUTO_INCREMENT,
    user_id            BIGINT       NOT NULL,
    full_name          VARCHAR(120) NOT NULL,
    contact_number     VARCHAR(20)  NOT NULL,
    blood_group        VARCHAR(3)   NOT NULL,
    location           VARCHAR(150) NOT NULL,
    last_donation_date DATE         NOT NULL,
    created_at         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at         DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
        ON UPDATE CURRENT_TIMESTAMP(6),

    CONSTRAINT pk_donors PRIMARY KEY (id),
    CONSTRAINT uk_donors_user UNIQUE (user_id),
    CONSTRAINT fk_donors_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT ck_donors_blood_group CHECK (blood_group IN ('A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-')),
    INDEX idx_donors_blood_group (blood_group)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;
