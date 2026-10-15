package com.validei.api.donor.service;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.dto.PageResponse;
import com.validei.api.common.exception.ResourceNotFoundException;
import com.validei.api.donor.dto.DonorSearchResult;
import com.validei.api.donor.dto.DonorRequest;
import com.validei.api.donor.dto.DonorResponse;
import com.validei.api.donor.entity.Donor;
import com.validei.api.donor.repository.DonorRepository;
import com.validei.api.user.service.UserService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Optional;

@Service
public class DonorService {

    private final DonorRepository donorRepository;
    private final UserService userService;

    public DonorService(DonorRepository donorRepository, UserService userService) {
        this.donorRepository = donorRepository;
        this.userService = userService;
    }

    @Transactional(readOnly = true)
    public DonorResponse getDonorOfUser(Long userId) {
        Donor donor = donorRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("El usuario no está registrado como donante")
                );

        return DonorResponse.from(donor);
    }

    // Crea el registro de donante del usuario o actualiza el existente
    @Transactional
    public SaveResult saveDonorOfUser(Long userId, DonorRequest request) {
        Optional<Donor> existingDonor = donorRepository.findByUserId(userId);

        Donor donor = existingDonor
                .orElseGet(() -> new Donor(userService.findUser(userId)));

        donor.updateDetails(
                request.name(),
                request.contactNumber(),
                request.bloodGroup(),
                request.location(),
                request.lastDonationDate()
        );

        Donor savedDonor = donorRepository.saveAndFlush(donor);

        return new SaveResult(DonorResponse.from(savedDonor), existingDonor.isEmpty());
    }

    @Transactional
    public DonorResponse updateSearchVisibility(Long userId, boolean visibleInSearch) {
        Donor donor = donorRepository.findByUserId(userId)
                .orElseThrow(() ->
                        new ResourceNotFoundException("El usuario no está registrado como donante")
                );

        donor.updateSearchVisibility(visibleInSearch);

        return DonorResponse.from(donorRepository.saveAndFlush(donor));
    }

    /**
     * Búsqueda de donantes que autorizaron aparecer. Excluye al propio usuario.
     * No aplica reglas de compatibilidad sanguínea: filtra por el grupo exacto solicitado.
     */
    @Transactional(readOnly = true)
    public PageResponse<DonorSearchResult> search(
            Long currentUserId,
            BloodGroup bloodGroup,
            String location,
            int page,
            int size
    ) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("fullName", "id"));

        Page<DonorSearchResult> results = donorRepository
                .searchVisible(currentUserId, bloodGroup, toLikePattern(location), pageable)
                .map(DonorSearchResult::from);

        return PageResponse.from(results);
    }

    // Búsqueda parcial sin distinguir mayúsculas; se escapan los comodines que escriba el usuario
    private String toLikePattern(String location) {
        if (location == null || location.isBlank()) {
            return null;
        }
        String escaped = location.trim().toLowerCase(Locale.ROOT)
                .replace("!", "!!")
                .replace("%", "!%")
                .replace("_", "!_");
        return "%" + escaped + "%";
    }

    public record SaveResult(
            DonorResponse donor,
            boolean created
    ) {}
}
