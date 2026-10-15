package com.validei.api.donor;

import com.validei.api.IntegrationTest;
import com.validei.api.TestApi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class DonorIntegrationTest {

    private static final String VALID_DONOR = """
            {
              "name": "Jorge Perez",
              "contactNumber": "+18092249304",
              "bloodGroup": "AB+",
              "location": "Santo Domingo, RD",
              "lastDonationDate": "2026-06-01"
            }
            """;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private String token;

    @BeforeEach
    void setUp() throws Exception {
        TestApi.cleanDatabase(jdbcTemplate);
        token = TestApi.registerAndLogin(mockMvc, "Jorge", "jorge@mail.com");
    }

    @Test
    void returnsNotFoundBeforeRegisteringAsDonor() throws Exception {
        mockMvc.perform(get("/api/v1/donors/me").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
    }

    @Test
    void registersDonorLinkedToAuthenticatedUser() throws Exception {
        saveDonor(VALID_DONOR)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name").value("Jorge Perez"))
                .andExpect(jsonPath("$.bloodGroup").value("AB+"))
                .andExpect(jsonPath("$.lastDonationDate").value("2026-06-01"));

        String storedGroup = jdbcTemplate.queryForObject(
                "SELECT d.blood_group FROM donors d JOIN users u ON u.id = d.user_id WHERE u.email = 'jorge@mail.com'",
                String.class);
        assertThat(storedGroup).isEqualTo("AB+");
    }

    @Test
    void returnsRegisteredDonor() throws Exception {
        saveDonor(VALID_DONOR).andExpect(status().isCreated());

        mockMvc.perform(get("/api/v1/donors/me").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.contactNumber").value("+18092249304"))
                .andExpect(jsonPath("$.location").value("Santo Domingo, RD"));
    }

    @Test
    void secondSaveUpdatesTheSameRegistration() throws Exception {
        saveDonor(VALID_DONOR).andExpect(status().isCreated());

        saveDonor(VALID_DONOR.replace("\"AB+\"", "\"O-\""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bloodGroup").value("O-"));

        Integer donorRows = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM donors", Integer.class);
        assertThat(donorRows).isEqualTo(1);
    }

    @Test
    void validatesRequiredFields() throws Exception {
        saveDonor("{}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fields.length()").value(5));
    }

    @Test
    void rejectsFutureLastDonationDate() throws Exception {
        String tomorrow = LocalDate.now().plusDays(1).toString();

        saveDonor(VALID_DONOR.replace("2026-06-01", tomorrow))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[*].field").value(hasItem("lastDonationDate")));
    }

    @Test
    void rejectsInvalidPhone() throws Exception {
        saveDonor(VALID_DONOR.replace("+18092249304", "llamame"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[0].field").value("contactNumber"));
    }

    @Test
    void rejectsUnknownBloodGroup() throws Exception {
        saveDonor(VALID_DONOR.replace("\"AB+\"", "\"Z+\""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("MALFORMED_REQUEST"));
    }

    @Test
    void requiresAuthentication() throws Exception {
        mockMvc.perform(put("/api/v1/donors/me").contentType(MediaType.APPLICATION_JSON).content(VALID_DONOR))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/donors/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void databaseAllowsOnlyOneDonorPerUser() throws Exception {
        saveDonor(VALID_DONOR).andExpect(status().isCreated());
        Long userId = jdbcTemplate.queryForObject("SELECT id FROM users", Long.class);

        assertThatThrownBy(() -> jdbcTemplate.update("""
                INSERT INTO donors (user_id, full_name, contact_number, blood_group, location, last_donation_date)
                VALUES (?, 'Copia', '8090000000', 'A+', 'Santiago', '2026-01-01')
                """, userId))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRejectsDonorOfUnknownUser() {
        assertThatThrownBy(() -> jdbcTemplate.update("""
                INSERT INTO donors (user_id, full_name, contact_number, blood_group, location, last_donation_date)
                VALUES (999999, 'Nadie', '8090000000', 'A+', 'Santiago', '2026-01-01')
                """))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void databaseRejectsInvalidBloodGroup() {
        // MySQL informa las restricciones CHECK con el error 3819, que Spring no clasifica como integridad
        assertThatThrownBy(() -> jdbcTemplate.update("""
                INSERT INTO donors (user_id, full_name, contact_number, blood_group, location, last_donation_date)
                SELECT id, 'X', '8090000000', 'Z+', 'Santiago', '2026-01-01' FROM users
                """))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_donors_blood_group");
    }

    @Test
    void deletingUserRemovesDonorRegistration() throws Exception {
        saveDonor(VALID_DONOR).andExpect(status().isCreated());

        jdbcTemplate.update("DELETE FROM users");

        Integer donorRows = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM donors", Integer.class);
        assertThat(donorRows).isZero();
    }

    private ResultActions saveDonor(String json) throws Exception {
        return mockMvc.perform(put("/api/v1/donors/me")
                .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                .contentType(MediaType.APPLICATION_JSON)
                .content(json));
    }
}
