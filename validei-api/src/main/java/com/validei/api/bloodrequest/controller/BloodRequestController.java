package com.validei.api.bloodrequest.controller;

import com.validei.api.bloodrequest.dto.BloodRequestResponse;
import com.validei.api.bloodrequest.dto.CreateBloodRequest;
import com.validei.api.bloodrequest.service.BloodRequestService;
import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.dto.PageResponse;
import com.validei.api.common.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/blood-requests")
public class BloodRequestController {

    private final BloodRequestService bloodRequestService;

    public BloodRequestController(BloodRequestService bloodRequestService) {
        this.bloodRequestService = bloodRequestService;
    }

    @PostMapping
    public ResponseEntity<BloodRequestResponse> create(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateBloodRequest request
    ) {
        BloodRequestResponse created = bloodRequestService.create(CurrentUser.id(jwt), request);

        return ResponseEntity
                .created(URI.create("/api/v1/blood-requests/" + created.id()))
                .body(created);
    }

    @GetMapping
    public PageResponse<BloodRequestResponse> list(
            @RequestParam(required = false) BloodGroup bloodGroup,
            @RequestParam(defaultValue = "0")
            @Min(value = 0, message = "La página no puede ser negativa") int page,
            @RequestParam(defaultValue = "10")
            @Min(value = 1, message = "El tamaño mínimo es 1")
            @Max(value = 50, message = "El tamaño máximo es 50") int size
    ) {
        return bloodRequestService.list(bloodGroup, page, size);
    }

    @GetMapping("/{id}")
    public BloodRequestResponse getById(@PathVariable Long id) {
        return bloodRequestService.getById(id);
    }
}
