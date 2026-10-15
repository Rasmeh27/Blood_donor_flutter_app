package com.validei.api;

import com.jayway.jsonpath.JsonPath;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// Operaciones repetidas en las pruebas de integración: limpiar datos, registrar e iniciar sesión
public final class TestApi {

    public static final String PASSWORD = "Secreta#123";

    private TestApi() {
    }

    // Orden inverso a las claves foráneas
    public static void cleanDatabase(JdbcTemplate jdbcTemplate) {
        jdbcTemplate.update("DELETE FROM password_reset_codes");
        jdbcTemplate.update("DELETE FROM blood_requests");
        jdbcTemplate.update("DELETE FROM donors");
        jdbcTemplate.update("DELETE FROM users");
    }

    public static void register(MockMvc mockMvc, String name, String email) throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "%s", "email": "%s", "password": "%s"}
                                """.formatted(name, email, PASSWORD)))
                .andExpect(status().isCreated());
    }

    public static String login(MockMvc mockMvc, String email) throws Exception {
        String body = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email": "%s", "password": "%s"}
                                """.formatted(email, PASSWORD)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        return JsonPath.read(body, "$.accessToken");
    }

    public static String registerAndLogin(MockMvc mockMvc, String name, String email) throws Exception {
        register(mockMvc, name, email);
        return login(mockMvc, email);
    }

    public static String bearer(String token) {
        return "Bearer " + token;
    }
}
