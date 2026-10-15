package com.validei.api.auth;

import com.validei.api.IntegrationTest;
import com.validei.api.TestApi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.after;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class PasswordResetIntegrationTest {

    private static final String NEW_PASSWORD = "NuevaClave#2026";
    private static final Pattern CODE_IN_MAIL = Pattern.compile("código de verificación es: (\\d{6})");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockitoBean
    private JavaMailSender mailSender;

    // Correo distinto en cada prueba: el limitador de frecuencia guarda estado en memoria
    private String email;

    @BeforeEach
    void setUp() throws Exception {
        jdbcTemplate.update("DELETE FROM password_reset_codes");
        TestApi.cleanDatabase(jdbcTemplate);
        email = "reset." + UUID.randomUUID() + "@mail.com";
        TestApi.register(mockMvc, "Ana", email);
        clearInvocations(mailSender);
    }

    @Test
    void sendsCodeByMailAndStoresOnlyItsHash() throws Exception {
        forgot(email)
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").value("Si el correo está registrado, recibirás un código de verificación"));

        SimpleMailMessage mail = capturedMail();
        String code = codeFrom(mail);
        assertThat(mail.getTo()).containsExactly(email);

        String storedHash = jdbcTemplate.queryForObject("SELECT code_hash FROM password_reset_codes", String.class);
        assertThat(storedHash).startsWith("$2a$").doesNotContain(code);
    }

    @Test
    void unknownEmailGetsSameResponseAndNoMail() throws Exception {
        forgot("nadie." + UUID.randomUUID() + "@mail.com")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.message").value("Si el correo está registrado, recibirás un código de verificación"));

        verify(mailSender, after(500).never()).send(any(SimpleMailMessage.class));
        assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM password_reset_codes", Integer.class)).isZero();
    }

    @Test
    void validCodeResetsPasswordAndCannotBeReused() throws Exception {
        forgot(email);
        String code = codeFrom(capturedMail());

        verifyCode(email, code).andExpect(status().isNoContent());
        reset(email, code, NEW_PASSWORD)
                .andExpect(status().isNoContent())
                .andExpect(content().string(not(containsString(code))));

        login(email, NEW_PASSWORD).andExpect(status().isOk());
        login(email, TestApi.PASSWORD).andExpect(status().isUnauthorized());

        reset(email, code, "OtraClave#2026")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("INVALID_RESET_CODE"));
        verifyCode(email, code).andExpect(status().isBadRequest());
    }

    @Test
    void wrongCodeCountsAttemptsAndFiveAttemptsInvalidateTheCode() throws Exception {
        forgot(email);
        String code = codeFrom(capturedMail());
        String wrongCode = code.equals("000000") ? "111111" : "000000";

        for (int attempt = 1; attempt <= 5; attempt++) {
            verifyCode(email, wrongCode)
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.message").value("El código es inválido o ha expirado"));
        }

        assertThat(jdbcTemplate.queryForObject("SELECT failed_attempts FROM password_reset_codes", Integer.class)).isEqualTo(5);
        verifyCode(email, code).andExpect(status().isBadRequest());
        reset(email, code, NEW_PASSWORD).andExpect(status().isBadRequest());
        login(email, TestApi.PASSWORD).andExpect(status().isOk());
    }

    @Test
    void expiredCodeIsRejected() throws Exception {
        forgot(email);
        String code = codeFrom(capturedMail());
        jdbcTemplate.update("UPDATE password_reset_codes SET expires_at = DATE_SUB(expires_at, INTERVAL 11 MINUTE)");

        verifyCode(email, code).andExpect(status().isBadRequest());
        reset(email, code, NEW_PASSWORD).andExpect(status().isBadRequest());
    }

    @Test
    void newRequestInvalidatesPreviousCode() throws Exception {
        forgot(email);
        String firstCode = codeFrom(capturedMail());
        clearInvocations(mailSender);

        forgot(email);
        String secondCode = codeFrom(capturedMail());

        if (!firstCode.equals(secondCode)) {
            verifyCode(email, firstCode).andExpect(status().isBadRequest());
        }
        verifyCode(email, secondCode).andExpect(status().isNoContent());
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM password_reset_codes WHERE consumed_at IS NULL", Integer.class)).isEqualTo(1);
    }

    @Test
    void limitsRequestsPerEmailEvenForUnknownAccounts() throws Exception {
        String unknown = "limite." + UUID.randomUUID() + "@mail.com";
        for (int i = 0; i < 3; i++) {
            forgot(unknown).andExpect(status().isAccepted());
        }

        forgot(unknown)
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error").value("TOO_MANY_REQUESTS"));
    }

    @Test
    void validatesRequestFormats() throws Exception {
        forgot("no-es-correo").andExpect(status().isBadRequest());
        verifyCode(email, "12ab").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[0].field").value("code"));
        reset(email, "123456", "debil").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
    }

    @Test
    void codeForUnknownEmailIsRejectedWithSameMessage() throws Exception {
        verifyCode("nadie@mail.com", "123456")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("El código es inválido o ha expirado"));
    }

    private SimpleMailMessage capturedMail() {
        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mailSender, timeout(3000)).send(captor.capture());
        return captor.getValue();
    }

    private String codeFrom(SimpleMailMessage mail) {
        Matcher matcher = CODE_IN_MAIL.matcher(mail.getText());
        assertThat(matcher.find()).as("el correo contiene un código de 6 dígitos").isTrue();
        return matcher.group(1);
    }

    private ResultActions forgot(String address) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/password/forgot")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\": \"%s\"}".formatted(address)));
    }

    private ResultActions verifyCode(String address, String code) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/password/verify")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\": \"%s\", \"code\": \"%s\"}".formatted(address, code)));
    }

    private ResultActions reset(String address, String code, String password) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/password/reset")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\": \"%s\", \"code\": \"%s\", \"newPassword\": \"%s\"}"
                        .formatted(address, code, password)));
    }

    private ResultActions login(String address, String password) throws Exception {
        return mockMvc.perform(post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\": \"%s\", \"password\": \"%s\"}".formatted(address, password)));
    }
}
