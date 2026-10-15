package com.validei.api.user;

import com.validei.api.IntegrationTest;
import com.validei.api.TestApi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class UserIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private JwtEncoder jwtEncoder;

    @BeforeEach
    void cleanDatabase() {
        TestApi.cleanDatabase(jdbcTemplate);
    }

    @Test
    void returnsAuthenticatedUserFromDatabase() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Ana Perez", "ana@mail.com");

        mockMvc.perform(get("/api/v1/users/me").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Ana Perez"))
                .andExpect(jsonPath("$.email").value("ana@mail.com"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    @Test
    void rejectsRequestWithoutToken() throws Exception {
        mockMvc.perform(get("/api/v1/users/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.message").value("Se requiere autenticación"));
    }

    @Test
    void rejectsAlteredToken() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Ana", "ana@mail.com");
        String alteredToken = token.substring(0, token.length() - 4) + "abcd";

        mockMvc.perform(get("/api/v1/users/me").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(alteredToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("El token es inválido o ha expirado"));
    }

    @Test
    void rejectsMalformedToken() throws Exception {
        mockMvc.perform(get("/api/v1/users/me").header(HttpHeaders.AUTHORIZATION, "Bearer no-es-un-jwt"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsExpiredToken() throws Exception {
        TestApi.register(mockMvc, "Ana", "ana@mail.com");
        Long userId = jdbcTemplate.queryForObject("SELECT id FROM users", Long.class);
        Instant past = Instant.now().minus(2, ChronoUnit.HOURS);
        String expiredToken = encodeToken(userId, past, past.plus(1, ChronoUnit.MINUTES));

        mockMvc.perform(get("/api/v1/users/me").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(expiredToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHORIZED"));
    }

    @Test
    void returnsNotFoundWhenTokenBelongsToDeletedUser() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Ana", "ana@mail.com");
        jdbcTemplate.update("DELETE FROM users");

        mockMvc.perform(get("/api/v1/users/me").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
    }

    @Test
    void updatesOnlyTheAuthenticatedUser() throws Exception {
        String anaToken = TestApi.registerAndLogin(mockMvc, "Ana", "ana@mail.com");
        TestApi.register(mockMvc, "Luis", "luis@mail.com");

        mockMvc.perform(patch("/api/v1/users/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(anaToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"phone": "+18092249304", "gender": "FEMALE", "location": "Santo Domingo, DN"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Ana"))
                .andExpect(jsonPath("$.phone").value("+18092249304"))
                .andExpect(jsonPath("$.gender").value("FEMALE"))
                .andExpect(jsonPath("$.location").value("Santo Domingo, DN"));

        String anaLocation = jdbcTemplate.queryForObject(
                "SELECT location FROM users WHERE email = 'ana@mail.com'", String.class);
        String luisLocation = jdbcTemplate.queryForObject(
                "SELECT location FROM users WHERE email = 'luis@mail.com'", String.class);
        assertThat(anaLocation).isEqualTo("Santo Domingo, DN");
        assertThat(luisLocation).isNull();
    }

    @Test
    void rejectsInvalidProfileData() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Ana", "ana@mail.com");

        mockMvc.perform(patch("/api/v1/users/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "   ", "phone": "abc"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fields.length()").value(2));
    }

    @Test
    void rejectsUnknownGender() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Ana", "ana@mail.com");

        mockMvc.perform(patch("/api/v1/users/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"gender": "OTHER"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("MALFORMED_REQUEST"));
    }

    @Test
    void rejectsUpdateWithoutToken() throws Exception {
        mockMvc.perform(patch("/api/v1/users/me")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Intruso\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void doesNotExposeOtherUsersById() throws Exception {
        String token = TestApi.registerAndLogin(mockMvc, "Ana", "ana@mail.com");

        mockMvc.perform(get("/api/v1/users/1").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").value("FORBIDDEN"));
    }

    private String encodeToken(Long userId, Instant issuedAt, Instant expiresAt) {
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("validei-api")
                .subject(userId.toString())
                .issuedAt(issuedAt)
                .expiresAt(expiresAt)
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }
}
