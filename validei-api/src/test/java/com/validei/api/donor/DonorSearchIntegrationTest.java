package com.validei.api.donor;

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

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class DonorSearchIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private String searcherToken;

    @BeforeEach
    void setUp() throws Exception {
        TestApi.cleanDatabase(jdbcTemplate);
        searcherToken = TestApi.registerAndLogin(mockMvc, "Buscador", "buscador@mail.com");
        registerDonor(searcherToken, "Buscador", "O-", "Santiago");
        setVisibility(searcherToken, true);

        String visibleONeg = donorUser("visible.o@mail.com", "Visible O", "O-", "Santo Domingo, DN");
        setVisibility(visibleONeg, true);
        donorUser("oculto@mail.com", "Oculto O", "O-", "Santo Domingo, DN");
        String visibleAPos = donorUser("visible.a@mail.com", "Visible A", "A+", "Santiago de los Caballeros");
        setVisibility(visibleAPos, true);
    }

    @Test
    void newDonorsAreHiddenByDefault() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Nuevo", "nuevo@mail.com");

        registerDonor(token, "Nuevo", "B+", "La Vega")
                .andExpect(jsonPath("$.visibleInSearch").value(false));
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM donors WHERE visible_in_search = TRUE", Integer.class)).isEqualTo(3);
    }

    @Test
    void returnsOnlyConsentingDonorsAndExcludesTheSearcher() throws Exception {
        search("/api/v1/donors")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.content[*].name").value(containsInAnyOrder("Visible O", "Visible A")));
    }

    @Test
    void doesNotExposeContactOrAccountData() throws Exception {
        search("/api/v1/donors")
                .andExpect(jsonPath("$.content[0].contactNumber").doesNotExist())
                .andExpect(jsonPath("$.content[0].email").doesNotExist())
                .andExpect(jsonPath("$.content[0].userId").doesNotExist())
                .andExpect(content().string(not(containsString("8092249304"))))
                .andExpect(content().string(not(containsString("@mail.com"))));
    }

    @Test
    void filtersByBloodGroupAndLocation() throws Exception {
        search("/api/v1/donors?bloodGroup=O-")
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].name").value("Visible O"));

        search("/api/v1/donors?bloodGroup=A%2B&location=SANTIAGO")
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].bloodGroup").value("A+"));

        search("/api/v1/donors?location=santo")
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].location").value("Santo Domingo, DN"));
    }

    @Test
    void locationWildcardsAreTreatedAsText() throws Exception {
        search("/api/v1/donors?location=%25")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void paginatesResults() throws Exception {
        search("/api/v1/donors?page=0&size=1")
                .andExpect(jsonPath("$.content.length()").value(1))
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.totalPages").value(2))
                .andExpect(jsonPath("$.content[0].name").value("Visible A"));

        search("/api/v1/donors?page=1&size=1")
                .andExpect(jsonPath("$.content[0].name").value("Visible O"));

        search("/api/v1/donors?size=51").andExpect(status().isBadRequest());
        search("/api/v1/donors?bloodGroup=Z").andExpect(status().isBadRequest());
    }

    @Test
    void withdrawingConsentRemovesDonorFromResults() throws Exception {
        String token = TestApi.login(mockMvc, "visible.o@mail.com");
        setVisibility(token, false).andExpect(jsonPath("$.visibleInSearch").value(false));

        search("/api/v1/donors?bloodGroup=O-").andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void visibilityRequiresDonorRegistration() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Sin registro", "sinregistro@mail.com");

        setVisibility(token, true).andExpect(status().isNotFound());
    }

    @Test
    void searchAndConsentRequireAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/donors")).andExpect(status().isUnauthorized());
        mockMvc.perform(patch("/api/v1/donors/me/visibility")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"visibleInSearch\": true}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void visibilityValueIsRequired() throws Exception {
        mockMvc.perform(patch("/api/v1/donors/me/visibility")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(searcherToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[0].field").value("visibleInSearch"));
    }

    private String donorUser(String email, String name, String bloodGroup, String location) throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, name, email);
        registerDonor(token, name, bloodGroup, location);
        return token;
    }

    private ResultActions registerDonor(String token, String name, String bloodGroup, String location) throws Exception {
        return mockMvc.perform(put("/api/v1/donors/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "%s", "contactNumber": "+18092249304", "bloodGroup": "%s",
                                 "location": "%s", "lastDonationDate": "2026-06-01"}
                                """.formatted(name, bloodGroup, location)))
                .andExpect(status().isCreated());
    }

    private ResultActions setVisibility(String token, boolean visible) throws Exception {
        return mockMvc.perform(patch("/api/v1/donors/me/visibility")
                .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"visibleInSearch\": %s}".formatted(visible)));
    }

    private ResultActions search(String url) throws Exception {
        return mockMvc.perform(get(URI.create(url))
                .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(searcherToken)));
    }
}
