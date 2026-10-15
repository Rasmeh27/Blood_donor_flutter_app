package com.validei.api.auth;

import com.validei.api.IntegrationTest;
import com.validei.api.TestApi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class AuthIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void cleanDatabase() {
        TestApi.cleanDatabase(jdbcTemplate);
    }

    @Test
    void registerCreatesUserAndStoresBcryptHash() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Ana Perez", "email": "ANA@Mail.com", "password": "Secreta#123"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.email").value("ana@mail.com"))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist());

        String storedHash = jdbcTemplate.queryForObject(
                "SELECT password_hash FROM users WHERE email = 'ana@mail.com'", String.class);
        assertThat(storedHash).startsWith("$2a$12$").doesNotContain("Secreta#123");
    }

    @Test
    void registerRejectsDuplicatedEmail() throws Exception {
        TestApi.register(mockMvc, "Ana", "ana@mail.com");

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Otra", "email": "Ana@mail.com", "password": "Secreta#123"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("CONFLICT"))
                .andExpect(jsonPath("$.path").value("/api/v1/auth/register"));
    }

    @Test
    void registerValidatesRequiredFields() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": " ", "email": "", "password": "corta"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fields[*].field").value(hasItem("name")))
                .andExpect(jsonPath("$.fields[*].field").value(hasItem("email")))
                .andExpect(jsonPath("$.fields[*].field").value(hasItem("password")));
    }

    @Test
    void registerRejectsInvalidEmailFormat() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Ana", "email": "no-es-correo", "password": "Secreta#123"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[0].field").value("email"));
    }

    @Test
    void registerRejectsPasswordWithoutSpecialCharacter() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Ana", "email": "ana@mail.com", "password": "Secreta123"}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[0].field").value("password"));
    }

    @Test
    void registerRejectsMalformedJson() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": "))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("MALFORMED_REQUEST"));
    }

    @Test
    void loginReturnsSignedTokenAndPublicUserData() throws Exception {
        TestApi.register(mockMvc, "Ana", "ana@mail.com");

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email": " ANA@mail.com ", "password": "Secreta#123"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.accessToken").value(notNullValue()))
                .andExpect(jsonPath("$.expiresAt").value(notNullValue()))
                .andExpect(jsonPath("$.user.email").value("ana@mail.com"))
                .andExpect(jsonPath("$.user.passwordHash").doesNotExist());
    }

    @Test
    void loginRejectsWrongPassword() throws Exception {
        TestApi.register(mockMvc, "Ana", "ana@mail.com");

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email": "ana@mail.com", "password": "Incorrecta#1"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("INVALID_CREDENTIALS"))
                .andExpect(content().string(not(org.hamcrest.Matchers.containsString("Incorrecta#1"))));
    }

    @Test
    void loginRejectsUnknownUserWithSameMessage() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email": "nadie@mail.com", "password": "Secreta#123"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Correo o contraseña incorrectos"));
    }

    @Test
    void loginValidatesFields() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email": "no-es-correo", "password": ""}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
    }

    @Test
    void unknownRouteIsDeniedWithoutLeakingDetails() throws Exception {
        mockMvc.perform(post("/api/v1/admin/users"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHORIZED"));
    }
}
