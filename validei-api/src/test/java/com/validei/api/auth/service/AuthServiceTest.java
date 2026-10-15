package com.validei.api.auth.service;

import com.validei.api.auth.dto.AuthResponse;
import com.validei.api.auth.dto.LoginRequest;
import com.validei.api.auth.dto.RegisterRequest;
import com.validei.api.common.exception.ConflictException;
import com.validei.api.common.exception.InvalidCredentialsException;
import com.validei.api.user.entity.User;
import com.validei.api.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthService authService;

    @Test
    void registerNormalizesEmailAndStoresHash() {
        when(userRepository.existsByEmailIgnoreCase("ana@mail.com")).thenReturn(false);
        when(passwordEncoder.encode("Secreta#1")).thenReturn("hash-bcrypt");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        var response = authService.register(new RegisterRequest(" Ana ", " ANA@Mail.com ", "Secreta#1"));

        assertThat(response.email()).isEqualTo("ana@mail.com");
        assertThat(response.name()).isEqualTo("Ana");
    }

    @Test
    void registerRejectsDuplicatedEmail() {
        when(userRepository.existsByEmailIgnoreCase("ana@mail.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(new RegisterRequest("Ana", "ana@mail.com", "Secreta#1")))
                .isInstanceOf(ConflictException.class);
        verify(userRepository, never()).save(any());
    }

    @Test
    void loginReturnsTokenWhenCredentialsAreValid() {
        User user = existingUser();
        Instant expiresAt = Instant.now().plusSeconds(3600);
        when(userRepository.findByEmailIgnoreCase("ana@mail.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("Secreta#1", "hash-bcrypt")).thenReturn(true);
        when(jwtService.generateToken(user)).thenReturn(new JwtService.TokenResult("token", expiresAt));

        AuthResponse response = authService.login(new LoginRequest(" ANA@mail.com ", "Secreta#1"));

        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.accessToken()).isEqualTo("token");
        assertThat(response.expiresAt()).isEqualTo(expiresAt);
        assertThat(response.user().id()).isEqualTo(1L);
    }

    @Test
    void loginRejectsWrongPassword() {
        when(userRepository.findByEmailIgnoreCase("ana@mail.com")).thenReturn(Optional.of(existingUser()));
        when(passwordEncoder.matches("Incorrecta#1", "hash-bcrypt")).thenReturn(false);

        assertThatThrownBy(() -> authService.login(new LoginRequest("ana@mail.com", "Incorrecta#1")))
                .isInstanceOf(InvalidCredentialsException.class);
        verify(jwtService, never()).generateToken(any());
    }

    @Test
    void loginRejectsUnknownEmail() {
        when(userRepository.findByEmailIgnoreCase("nadie@mail.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.login(new LoginRequest("nadie@mail.com", "Secreta#1")))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void loginRejectsPasswordLongerThanBcryptLimit() {
        String longPassword = "ñ".repeat(40); // 80 bytes en UTF-8

        assertThatThrownBy(() -> authService.login(new LoginRequest("ana@mail.com", longPassword)))
                .isInstanceOf(InvalidCredentialsException.class);
        verify(passwordEncoder, never()).matches(any(), any());
    }

    private User existingUser() {
        User user = new User("Ana", "ana@mail.com", "hash-bcrypt");
        ReflectionTestUtils.setField(user, "id", 1L);
        return user;
    }
}
