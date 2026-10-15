package com.validei.api.user.controller;

import com.validei.api.common.security.CurrentUser;
import com.validei.api.user.dto.UpdateProfileRequest;
import com.validei.api.user.dto.UserResponse;
import com.validei.api.user.service.UserService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// Solo existe "/me": el usuario se identifica por el JWT, nunca por un id enviado por el cliente
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public UserResponse getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        return userService.getUserById(CurrentUser.id(jwt));
    }

    @PatchMapping("/me")
    public UserResponse updateCurrentUser(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody UpdateProfileRequest request
    ) {
        return userService.updateProfile(CurrentUser.id(jwt), request);
    }
}
