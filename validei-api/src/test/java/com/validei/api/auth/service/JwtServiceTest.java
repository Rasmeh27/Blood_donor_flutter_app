package com.validei.api.auth.service;

import com.validei.api.config.JwtConfig;
import com.validei.api.user.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.test.util.ReflectionTestUtils;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private static final String SECRET = Base64.getEncoder()
            .encodeToString("clave-de-prueba-unitaria-de-32-bytes!!".getBytes());
    private static final String ISSUER = "validei-api";

    private final JwtConfig jwtConfig = new JwtConfig();
    private JwtEncoder encoder;
    private JwtDecoder decoder;
    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        SecretKey key = jwtConfig.jwtSecretKey(SECRET);
        encoder = jwtConfig.jwtEncoder(key);
        decoder = jwtConfig.jwtDecoder(key, ISSUER);
        jwtService = new JwtService(encoder, ISSUER, 60);
    }

    @Test
    void generatedTokenContainsUserIdIssuerAndExpiration() {
        JwtService.TokenResult result = jwtService.generateToken(userWithId(7L));

        Jwt jwt = decoder.decode(result.accessToken());

        assertThat(jwt.getSubject()).isEqualTo("7");
        assertThat(jwt.getClaimAsString("iss")).isEqualTo(ISSUER);
        assertThat(jwt.getIssuedAt()).isNotNull();
        assertThat(jwt.getExpiresAt()).isEqualTo(result.expiresAt());
        assertThat(ChronoUnit.MINUTES.between(jwt.getIssuedAt(), jwt.getExpiresAt())).isEqualTo(60);
    }

    @Test
    void alteredTokenIsRejected() {
        String token = jwtService.generateToken(userWithId(7L)).accessToken();
        String[] parts = token.split("\\.");
        String forgedPayload = Base64.getUrlEncoder().withoutPadding()
                .encodeToString("{\"sub\":\"1\",\"iss\":\"validei-api\"}".getBytes());

        String alteredToken = parts[0] + "." + forgedPayload + "." + parts[2];

        assertThatThrownBy(() -> decoder.decode(alteredToken)).isInstanceOf(JwtException.class);
    }

    @Test
    void expiredTokenIsRejected() {
        Instant past = Instant.now().minus(2, ChronoUnit.HOURS);
        String expiredToken = encode(JwtClaimsSet.builder()
                .issuer(ISSUER)
                .subject("7")
                .issuedAt(past)
                .expiresAt(past.plus(1, ChronoUnit.MINUTES))
                .build());

        assertThatThrownBy(() -> decoder.decode(expiredToken)).isInstanceOf(JwtException.class);
    }

    @Test
    void tokenFromAnotherIssuerIsRejected() {
        Instant now = Instant.now();
        String foreignToken = encode(JwtClaimsSet.builder()
                .issuer("otro-emisor")
                .subject("7")
                .issuedAt(now)
                .expiresAt(now.plus(5, ChronoUnit.MINUTES))
                .build());

        assertThatThrownBy(() -> decoder.decode(foreignToken)).isInstanceOf(JwtException.class);
    }

    @Test
    void rejectsNonPositiveExpiration() {
        assertThatThrownBy(() -> new JwtService(encoder, ISSUER, 0))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsSecretShorterThan32Bytes() {
        String shortSecret = Base64.getEncoder().encodeToString("corta".getBytes());

        assertThatThrownBy(() -> jwtConfig.jwtSecretKey(shortSecret))
                .isInstanceOf(IllegalStateException.class);
    }

    private String encode(JwtClaimsSet claims) {
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    private User userWithId(Long id) {
        User user = new User("Ana", "ana@mail.com", "hash");
        ReflectionTestUtils.setField(user, "id", id);
        return user;
    }
}
