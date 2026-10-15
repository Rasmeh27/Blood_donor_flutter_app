package com.validei.api.donor;

import com.validei.api.IntegrationTest;
import com.validei.api.TestApi;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@IntegrationTest
class DonorPhotoIntegrationTest {

    private static final byte[] JPEG = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 0x10, 'J', 'F', 'I', 'F'};
    private static final byte[] PNG = {(byte) 0x89, 'P', 'N', 'G', '\r', '\n', 0x1A, '\n', 0, 0, 0, 0x0D};

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${app.storage.donor-photos-dir}")
    private String photosDirectory;

    private String token;

    @BeforeEach
    void setUp() throws Exception {
        TestApi.cleanDatabase(jdbcTemplate);
        token = TestApi.registerAndLogin(mockMvc, "Foto", "foto@mail.com");
        mockMvc.perform(put("/api/v1/donors/me")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"name": "Foto", "contactNumber": "+18092249304", "bloodGroup": "A+",
                                 "location": "Santiago", "lastDonationDate": "2026-06-01"}
                                """))
                .andExpect(status().isCreated());
    }

    @Test
    void storesPhotoOnDiskAndReturnsIt() throws Exception {
        upload(token, "foto.jpg", JPEG)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.hasPhoto").value(true));

        String fileName = jdbcTemplate.queryForObject("SELECT photo_file FROM donors", String.class);
        assertThat(fileName).matches("[0-9a-f-]{36}\\.jpg");
        assertThat(Files.readAllBytes(Path.of(photosDirectory, fileName))).isEqualTo(JPEG);

        mockMvc.perform(get("/api/v1/donors/me/photo").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, "image/jpeg"))
                .andExpect(content().bytes(JPEG));
    }

    @Test
    void replacingPhotoDeletesThePreviousFile() throws Exception {
        upload(token, "uno.jpg", JPEG).andExpect(status().isOk());
        String firstFile = jdbcTemplate.queryForObject("SELECT photo_file FROM donors", String.class);

        upload(token, "dos.png", PNG).andExpect(status().isOk());
        String secondFile = jdbcTemplate.queryForObject("SELECT photo_file FROM donors", String.class);

        assertThat(secondFile).endsWith(".png").isNotEqualTo(firstFile);
        assertThat(Path.of(photosDirectory, firstFile)).doesNotExist();
        mockMvc.perform(get("/api/v1/donors/me/photo").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(header().string(HttpHeaders.CONTENT_TYPE, "image/png"));
    }

    @Test
    void rejectsFilesThatAreNotJpegOrPngEvenWithImageName() throws Exception {
        upload(token, "falsa.jpg", "<script>alert(1)</script>".getBytes())
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("INVALID_PHOTO"));

        assertThat(jdbcTemplate.queryForObject("SELECT photo_file FROM donors", String.class)).isNull();
    }

    @Test
    void rejectsPhotosLargerThanTwoMegabytes() throws Exception {
        byte[] large = Arrays.copyOf(JPEG, 2 * 1024 * 1024 + 1);

        upload(token, "grande.jpg", large)
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("La imagen no puede superar 2 MB"));
    }

    @Test
    void photoRequiresDonorRegistrationAndExistingPhoto() throws Exception {
        mockMvc.perform(get("/api/v1/donors/me/photo").header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isNotFound());

        String other = TestApi.registerAndLogin(mockMvc, "Sin donante", "sindonante@mail.com");
        upload(other, "foto.jpg", JPEG).andExpect(status().isNotFound());
    }

    @Test
    void requiresAuthenticationAndPhotoPart() throws Exception {
        mockMvc.perform(multipart(HttpMethod.PUT, "/api/v1/donors/me/photo")
                        .file(new MockMultipartFile("photo", "foto.jpg", "image/jpeg", JPEG)))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/donors/me/photo")).andExpect(status().isUnauthorized());

        mockMvc.perform(multipart(HttpMethod.PUT, "/api/v1/donors/me/photo")
                        .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(token)))
                .andExpect(status().isBadRequest());
    }

    private ResultActions upload(String authToken, String fileName, byte[] content) throws Exception {
        return mockMvc.perform(multipart(HttpMethod.PUT, "/api/v1/donors/me/photo")
                .file(new MockMultipartFile("photo", fileName, "image/jpeg", content))
                .header(HttpHeaders.AUTHORIZATION, TestApi.bearer(authToken)));
    }
}
