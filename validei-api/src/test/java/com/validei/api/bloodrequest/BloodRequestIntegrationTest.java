package com.validei.api.bloodrequest;

import com.jayway.jsonpath.JsonPath;
import com.validei.api.IntegrationTest;
import com.validei.api.TestApi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.net.URI;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class BloodRequestIntegrationTest {

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
    void createsRequestLinkedToAuthenticatedUser() throws Exception {
        createRequest(validRequest("AB+"))
                .andExpect(status().isCreated())
                .andExpect(header().string(HttpHeaders.LOCATION, org.hamcrest.Matchers.startsWith("/api/v1/blood-requests/")))
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.bloodGroup").value("AB+"))
                .andExpect(jsonPath("$.bags").value(2))
                .andExpect(jsonPath("$.patientGender").value("MALE"))
                .andExpect(jsonPath("$.location").value(nullValue()))
                .andExpect(jsonPath("$.createdAt").value(notNullValue()));

        // Fase F: el timestamp viaja en UTC (ISO 8601 con Z) y corresponde al instante real de creación
        String body = createRequest(validRequest("B+")).andReturn().getResponse().getContentAsString();
        String createdAt = JsonPath.read(body, "$.createdAt");
        assertThat(createdAt).endsWith("Z");
        assertThat(java.time.Duration.between(java.time.Instant.parse(createdAt), java.time.Instant.now()).abs())
                .isLessThan(java.time.Duration.ofMinutes(1));
        // needBefore es una fecha de calendario: sin hora ni zona
        String needBefore = JsonPath.read(body, "$.needBefore");
        assertThat(needBefore).matches("\\d{4}-\\d{2}-\\d{2}");

        String requesterEmail = jdbcTemplate.queryForObject(
                "SELECT DISTINCT u.email FROM blood_requests r JOIN users u ON u.id = r.requester_id", String.class);
        assertThat(requesterEmail).isEqualTo("jorge@mail.com");
    }

    @Test
    void listsNewestRequestsFirst() throws Exception {
        createRequest(validRequest("A+")).andExpect(status().isCreated());
        createRequest(validRequest("O-")).andExpect(status().isCreated());

        authorizedGet("/api/v1/blood-requests")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.content[0].bloodGroup").value("O-"))
                .andExpect(jsonPath("$.content[1].bloodGroup").value("A+"));
    }

    @Test
    void filtersByBloodGroup() throws Exception {
        createRequest(validRequest("A+")).andExpect(status().isCreated());
        createRequest(validRequest("O-")).andExpect(status().isCreated());
        createRequest(validRequest("A+")).andExpect(status().isCreated());

        // El "+" se envía codificado (%2B), como lo hace Uri.queryParameters en Flutter.
        // Se usa URI para que MockMvc no vuelva a codificar el "%".
        mockMvc.perform(get(URI.create("/api/v1/blood-requests?bloodGroup=A%2B"))
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.content[*].bloodGroup").value(everyItem(is("A+"))));
    }

    @Test
    void paginatesResults() throws Exception {
        for (int i = 0; i < 3; i++) {
            createRequest(validRequest("B+")).andExpect(status().isCreated());
        }

        authorizedGet("/api/v1/blood-requests?page=1&size=2")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(1))
                .andExpect(jsonPath("$.size").value(2))
                .andExpect(jsonPath("$.totalElements").value(3))
                .andExpect(jsonPath("$.totalPages").value(2))
                .andExpect(jsonPath("$.content.length()").value(1));
    }

    @Test
    void rejectsInvalidListParameters() throws Exception {
        authorizedGet("/api/v1/blood-requests?size=51")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));

        authorizedGet("/api/v1/blood-requests?bloodGroup=Z")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("INVALID_PARAMETER"));
    }

    @Test
    void returnsRequestDetails() throws Exception {
        String body = createRequest(validRequest("AB+"))
                .andReturn().getResponse().getContentAsString();
        Integer id = JsonPath.read(body, "$.id");

        authorizedGet("/api/v1/blood-requests/" + id)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.patientName").value("Jorge Perez"))
                .andExpect(jsonPath("$.contactNumber").value("+18092249304"))
                .andExpect(jsonPath("$.caseDescription").value("Cancer Patient"))
                .andExpect(jsonPath("$.others").value("Need very urgent"));
    }

    @Test
    void returnsNotFoundForUnknownRequest() throws Exception {
        authorizedGet("/api/v1/blood-requests/999999")
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
    }

    @Test
    void rejectsNonNumericId() throws Exception {
        authorizedGet("/api/v1/blood-requests/abc")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("INVALID_PARAMETER"));
    }

    @Test
    void validatesRequiredFields() throws Exception {
        createRequest("{}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fields.length()").value(7));
    }

    @Test
    void validatesBagsAndDates() throws Exception {
        String yesterday = LocalDate.now().minusDays(1).toString();
        String invalid = validRequest("A+")
                .replace("\"bags\": 2", "\"bags\": 0")
                .replace(LocalDate.now().plusDays(5).toString(), yesterday);

        createRequest(invalid)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[*].field").value(hasItem("bags")))
                .andExpect(jsonPath("$.fields[*].field").value(hasItem("needBefore")));

        createRequest(validRequest("A+").replace("\"bags\": 2", "\"bags\": 11"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[0].field").value("bags"));
    }

    @Test
    void requiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/blood-requests"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/blood-requests/1"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/v1/blood-requests")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validRequest("A+")))
                .andExpect(status().isUnauthorized());

        Integer rows = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM blood_requests", Integer.class);
        assertThat(rows).isZero();
    }

    @Test
    void usesProfileLocationWhenRequestHasNone() throws Exception {
        mockMvc.perform(patch("/api/v1/users/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"location\": \"La Romana\"}"))
                .andExpect(status().isOk());

        createRequest(validRequest("A+"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.location").value("La Romana"));
    }

    @Test
    void fallsBackToDonorLocationAndKeepsNullWhenProfileHasNone() throws Exception {
        createRequest(validRequest("A+"))
                .andExpect(jsonPath("$.location").value(nullValue()));

        mockMvc.perform(put("/api/v1/donors/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Jorge", "contactNumber": "+18092249304", "bloodGroup": "A+",
                                 "location": "Santiago", "lastDonationDate": "2026-06-01"}
                                """))
                .andExpect(status().isCreated());

        createRequest(validRequest("A+"))
                .andExpect(jsonPath("$.location").value("Santiago"));

        // La solicitud anterior conserva su valor original
        Integer withoutLocation = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM blood_requests WHERE location IS NULL", Integer.class);
        assertThat(withoutLocation).isEqualTo(1);
    }

    @Test
    void explicitLocationInRequestTakesPrecedence() throws Exception {
        createRequest(validRequest("A+").replace("\"others\"", "\"location\": \"Hospital Central\", \"others\""))
                .andExpect(jsonPath("$.location").value("Hospital Central"));
    }

    @Test
    void deletingUserRemovesTheirRequests() throws Exception {
        createRequest(validRequest("A+")).andExpect(status().isCreated());

        jdbcTemplate.update("DELETE FROM users");

        Integer rows = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM blood_requests", Integer.class);
        assertThat(rows).isZero();
    }

    private String validRequest(String bloodGroup) {
        return """
                {
                  "bloodGroup": "%s",
                  "bags": 2,
                  "contactNumber": "+18092249304",
                  "emergencyContact": "+18095550000",
                  "patientName": "Jorge Perez",
                  "caseDescription": "Cancer Patient",
                  "patientGender": "MALE",
                  "needBefore": "%s",
                  "others": "Need very urgent"
                }
                """.formatted(bloodGroup, LocalDate.now().plusDays(5));
    }

    private ResultActions createRequest(String json) throws Exception {
        return mockMvc.perform(post("/api/v1/blood-requests")
                .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                .contentType(MediaType.APPLICATION_JSON)
                .content(json));
    }

    private ResultActions authorizedGet(String url) throws Exception {
        return mockMvc.perform(get(url).header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)));
    }
}
