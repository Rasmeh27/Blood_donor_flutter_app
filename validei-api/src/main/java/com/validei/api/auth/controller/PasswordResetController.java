package com.validei.api.auth.controller;

import com.validei.api.auth.dto.ForgotPasswordRequest;
import com.validei.api.auth.dto.ResetPasswordRequest;
import com.validei.api.auth.dto.VerifyResetCodeRequest;
import com.validei.api.auth.service.PasswordResetService;
import com.validei.api.common.dto.MessageResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth/password")
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    public PasswordResetController(PasswordResetService passwordResetService) {
        this.passwordResetService = passwordResetService;
    }

    // Siempre 202 con el mismo mensaje, exista o no la cuenta
    @PostMapping("/forgot")
    public ResponseEntity<MessageResponse> requestCode(@Valid @RequestBody ForgotPasswordRequest request) {
        passwordResetService.requestCode(request.email());
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(new MessageResponse(
                "Si el correo está registrado, recibirás un código de verificación"
        ));
    }

    @PostMapping("/verify")
    public ResponseEntity<Void> verifyCode(@Valid @RequestBody VerifyResetCodeRequest request) {
        passwordResetService.verifyCode(request.email(), request.code());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/reset")
    public ResponseEntity<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.resetPassword(request.email(), request.code(), request.newPassword());
        return ResponseEntity.noContent().build();
    }
}
