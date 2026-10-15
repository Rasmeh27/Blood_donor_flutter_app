-- Campos de FindDonorScreen ("Request for Blood Donor"), mostrados en el feed y en RequestDetailsScreen.
-- location es opcional: el formulario actual no la solicita (decisión D4 pendiente).
CREATE TABLE blood_requests (
    id                BIGINT           NOT NULL AUTO_INCREMENT,
    requester_id      BIGINT           NOT NULL,
    blood_group       VARCHAR(3)       NOT NULL,
    bags              TINYINT UNSIGNED NOT NULL,
    contact_number    VARCHAR(20)      NOT NULL,
    emergency_contact VARCHAR(20)      NOT NULL,
    patient_name      VARCHAR(120)     NOT NULL,
    case_description  VARCHAR(150)     NOT NULL,
    patient_gender    VARCHAR(10)      NULL,
    need_before       DATE             NOT NULL,
    location          VARCHAR(150)     NULL,
    others            VARCHAR(255)     NULL,
    created_at        DATETIME(6)      NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    CONSTRAINT pk_blood_requests PRIMARY KEY (id),
    CONSTRAINT fk_blood_requests_requester FOREIGN KEY (requester_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT ck_blood_requests_blood_group CHECK (blood_group IN ('A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-')),
    CONSTRAINT ck_blood_requests_bags CHECK (bags >= 1),
    CONSTRAINT ck_blood_requests_gender CHECK (patient_gender IN ('MALE', 'FEMALE')),
    INDEX idx_blood_requests_created (created_at),
    INDEX idx_blood_requests_group_created (blood_group, created_at)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;
