-- Consentimiento explícito para aparecer en la búsqueda de donantes.
-- FALSE por defecto: los donantes ya registrados no se publican hasta que lo autoricen.
ALTER TABLE donors
    ADD COLUMN visible_in_search BOOLEAN NOT NULL DEFAULT FALSE AFTER last_donation_date,
    ADD INDEX idx_donors_search (visible_in_search, blood_group);
