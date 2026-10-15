package com.validei.api.donor.controller;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.dto.PageResponse;
import com.validei.api.common.security.CurrentUser;
import com.validei.api.donor.dto.DonorSearchResult;
import com.validei.api.donor.dto.DonorVisibilityRequest;
import com.validei.api.donor.dto.DonorRequest;
import com.validei.api.donor.dto.DonorResponse;
import com.validei.api.donor.service.DonorPhotoService;
import com.validei.api.donor.service.DonorService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/donors")
public class DonorController {

    private final DonorService donorService;
    private final DonorPhotoService donorPhotoService;

    public DonorController(DonorService donorService, DonorPhotoService donorPhotoService) {
        this.donorService = donorService;
        this.donorPhotoService = donorPhotoService;
    }

    @GetMapping
    public PageResponse<DonorSearchResult> search(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) BloodGroup bloodGroup,
            @RequestParam(required = false)
            @Size(max = 150, message = "La ubicación no puede superar 150 caracteres") String location,
            @RequestParam(defaultValue = "0")
            @Min(value = 0, message = "La página no puede ser negativa") int page,
            @RequestParam(defaultValue = "10")
            @Min(value = 1, message = "El tamaño mínimo es 1")
            @Max(value = 50, message = "El tamaño máximo es 50") int size
    ) {
        return donorService.search(CurrentUser.id(jwt), bloodGroup, location, page, size);
    }

    // Consentimiento explícito para aparecer (o dejar de aparecer) en la búsqueda
    @PatchMapping("/me/visibility")
    public DonorResponse updateMySearchVisibility(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody DonorVisibilityRequest request
    ) {
        return donorService.updateSearchVisibility(CurrentUser.id(jwt), request.visibleInSearch());
    }

    // Foto del formulario de donante (multipart, campo "photo")
    @PutMapping(path = "/me/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public DonorResponse replaceMyPhoto(
            @AuthenticationPrincipal Jwt jwt,
            @RequestPart("photo") MultipartFile photo
    ) {
        return donorPhotoService.replacePhoto(CurrentUser.id(jwt), photo);
    }

    @GetMapping("/me/photo")
    public ResponseEntity<byte[]> getMyPhoto(@AuthenticationPrincipal Jwt jwt) {
        DonorPhotoService.Photo photo = donorPhotoService.getPhoto(CurrentUser.id(jwt));
        return ResponseEntity.ok()
                .contentType(photo.mediaType())
                .cacheControl(CacheControl.noStore())
                .body(photo.content());
    }

    @GetMapping("/me")
    public DonorResponse getMyDonorRegistration(@AuthenticationPrincipal Jwt jwt) {
        return donorService.getDonorOfUser(CurrentUser.id(jwt));
    }

    // 201 la primera vez (registro), 200 en las siguientes (actualización)
    @PutMapping("/me")
    public ResponseEntity<DonorResponse> saveMyDonorRegistration(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody DonorRequest request
    ) {
        DonorService.SaveResult result = donorService.saveDonorOfUser(CurrentUser.id(jwt), request);

        HttpStatus status = result.created() ? HttpStatus.CREATED : HttpStatus.OK;

        return ResponseEntity.status(status).body(result.donor());
    }
}
