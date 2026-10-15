
package com.validei.api.config;

import jakarta.servlet.DispatcherType;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    private final SecurityErrorHandler securityErrorHandler;

    public SecurityConfig(SecurityErrorHandler securityErrorHandler) {
        this.securityErrorHandler = securityErrorHandler;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http
    ) throws Exception {

        http
                .csrf(AbstractHttpConfigurer::disable)

                .formLogin(AbstractHttpConfigurer::disable)

                .httpBasic(AbstractHttpConfigurer::disable)

                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )

                .authorizeHttpRequests(auth -> auth

                        // Permitir el procesamiento interno de errores
                        .dispatcherTypeMatchers(
                                DispatcherType.ERROR
                        ).permitAll()

                        // Health Check
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/health"
                        ).permitAll()

                        // Registro e inicio de sesión públicos
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/v1/auth/register",
                                "/api/v1/auth/login",
                                "/api/v1/auth/password/forgot",
                                "/api/v1/auth/password/verify",
                                "/api/v1/auth/password/reset"
                        ).permitAll()

                        // Perfil del usuario autenticado
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/users/me"
                        ).authenticated()
                        .requestMatchers(
                                HttpMethod.PATCH,
                                "/api/v1/users/me"
                        ).authenticated()

                        // Registro de donante del usuario autenticado
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/donors/me"
                        ).authenticated()
                        .requestMatchers(
                                HttpMethod.PUT,
                                "/api/v1/donors/me"
                        ).authenticated()
                        .requestMatchers(
                                HttpMethod.PATCH,
                                "/api/v1/donors/me/visibility"
                        ).authenticated()
                        .requestMatchers(
                                HttpMethod.PUT,
                                "/api/v1/donors/me/photo"
                        ).authenticated()
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/donors/me/photo"
                        ).authenticated()

                        // Búsqueda de donantes: solo usuarios autenticados (datos personales)
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/donors"
                        ).authenticated()

                        // Solicitudes de sangre (feed, listado, detalle y creación)
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/blood-requests",
                                "/api/v1/blood-requests/*"
                        ).authenticated()
                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/v1/blood-requests"
                        ).authenticated()

                        // Proteger el resto
                        .anyRequest().denyAll()
                )

                // Valida el JWT del encabezado Authorization: Bearer con el JwtDecoder de JwtConfig
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(Customizer.withDefaults())
                        .authenticationEntryPoint(securityErrorHandler)
                        .accessDeniedHandler(securityErrorHandler)
                )

                .exceptionHandling(exceptions -> exceptions
                        .authenticationEntryPoint(securityErrorHandler)
                        .accessDeniedHandler(securityErrorHandler)
                );

        return http.build();
    }
}
