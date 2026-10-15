package com.validei.api.auth.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
public class PasswordResetMailer {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetMailer.class);

    private final JavaMailSender mailSender;
    private final String from;
    private final long codeTtlMinutes;

    public PasswordResetMailer(
            JavaMailSender mailSender,
            @Value("${app.mail.from}") String from,
            @Value("${app.password-reset.code-ttl-minutes}") long codeTtlMinutes
    ) {
        this.mailSender = mailSender;
        this.from = from;
        this.codeTtlMinutes = codeTtlMinutes;
    }

    // Asíncrono: la respuesta HTTP tarda lo mismo exista o no el correo
    @Async
    public void sendCode(String to, String code) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(to);
        message.setSubject("Validei - Código de recuperación de contraseña");
        message.setText("""
                Recibimos una solicitud para restablecer tu contraseña de Validei.

                Tu código de verificación es: %s

                El código vence en %d minutos y solo puede usarse una vez.
                Si no solicitaste este cambio, ignora este mensaje.
                """.formatted(code, codeTtlMinutes));

        try {
            mailSender.send(message);
        } catch (MailException ex) {
            // Nunca se registra el código ni el destinatario completo
            log.warn("No se pudo enviar el correo de recuperación: {}", ex.getClass().getSimpleName());
        }
    }
}
