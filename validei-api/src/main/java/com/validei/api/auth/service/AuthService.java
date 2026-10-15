package com.validei.api.auth.service;

import com.validei.api.auth.dto.AuthResponse;
import com.validei.api.auth.dto.LoginRequest;
import com.validei.api.auth.dto.RegisterRequest;
import com.validei.api.common.exception.ConflictException;
import com.validei.api.common.exception.InvalidCredentialsException;
import com.validei.api.user.dto.UserResponse;
import com.validei.api.user.entity.User;
import com.validei.api.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService
    ) {
       this.userRepository = userRepository;
       this.passwordEncoder = passwordEncoder;
       this.jwtService = jwtService;
    }

    @Transactional
    public UserResponse register(RegisterRequest request) {

        String email = normalizeEmail(request.email());

        String name = request.name().trim();

        if(name.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "el nombre es obligatorio"
            );
        }

        if(userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("El correo ya esta registrado");
        }

        if(PasswordRules.exceedsBcryptLimit(request.password())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "la contraseña es demasiado larga"
            );
        }

        String passwordHash = passwordEncoder.encode(
                request.password()
        );

        User user = new User(
                name,
                email,
                passwordHash
        );

        User savedUser = userRepository.save(user);

        return UserResponse.from(savedUser);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {

        if (PasswordRules.exceedsBcryptLimit(request.password())) {
            throw new InvalidCredentialsException();
        }

        User user = userRepository
                .findByEmailIgnoreCase(normalizeEmail(request.email()))
                .orElseThrow(InvalidCredentialsException::new);

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }

        JwtService.TokenResult token = jwtService.generateToken(user);

        return new AuthResponse(
                "Bearer",
                token.accessToken(),
                token.expiresAt(),
                UserResponse.from(user)
        );
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
