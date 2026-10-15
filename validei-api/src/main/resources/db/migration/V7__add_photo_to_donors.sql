-- Foto del donante (DonorRegistrationForm: "Select Donor picture").
-- La imagen se guarda en disco; aquí solo el nombre de archivo generado por el servidor.
ALTER TABLE donors
    ADD COLUMN photo_file VARCHAR(100) NULL AFTER visible_in_search;
