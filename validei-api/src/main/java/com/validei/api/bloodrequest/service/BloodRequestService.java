package com.validei.api.bloodrequest.service;

import com.validei.api.bloodrequest.dto.BloodRequestResponse;
import com.validei.api.bloodrequest.dto.CreateBloodRequest;
import com.validei.api.bloodrequest.entity.BloodRequest;
import com.validei.api.bloodrequest.repository.BloodRequestRepository;
import com.validei.api.common.domain.BloodGroup;
import com.validei.api.common.dto.PageResponse;
import com.validei.api.common.exception.ResourceNotFoundException;
import com.validei.api.donor.entity.Donor;
import com.validei.api.donor.repository.DonorRepository;
import com.validei.api.user.entity.User;
import com.validei.api.user.service.UserService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BloodRequestService {

    // Las más recientes primero, como en el feed de HomeScreen
    private static final Sort NEWEST_FIRST = Sort.by(
            Sort.Order.desc("createdAt"),
            Sort.Order.desc("id")
    );

    private final BloodRequestRepository bloodRequestRepository;
    private final UserService userService;
    private final DonorRepository donorRepository;

    public BloodRequestService(
            BloodRequestRepository bloodRequestRepository,
            UserService userService,
            DonorRepository donorRepository
    ) {
        this.bloodRequestRepository = bloodRequestRepository;
        this.userService = userService;
        this.donorRepository = donorRepository;
    }

    @Transactional
    public BloodRequestResponse create(Long requesterId, CreateBloodRequest request) {
        User requester = userService.findUser(requesterId);

        BloodRequest savedRequest = bloodRequestRepository.saveAndFlush(
                new BloodRequest(requester, request, resolveLocation(requester, request.location()))
        );

        return BloodRequestResponse.from(savedRequest);
    }

    /**
     * FindDonorScreen no pide ubicación: se usa la declarada en el perfil del solicitante
     * (users.location y, si falta, la de su registro de donante). Si no hay ninguna queda nula.
     */
    private String resolveLocation(User requester, String requestedLocation) {
        if (requestedLocation != null && !requestedLocation.isBlank()) {
            return requestedLocation;
        }
        if (requester.getLocation() != null && !requester.getLocation().isBlank()) {
            return requester.getLocation();
        }
        return donorRepository.findByUserId(requester.getId())
                .map(Donor::getLocation)
                .orElse(null);
    }

    // bloodGroup null equivale al filtro "All" de AllRequestScreen
    @Transactional(readOnly = true)
    public PageResponse<BloodRequestResponse> list(BloodGroup bloodGroup, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, NEWEST_FIRST);

        Page<BloodRequest> requests = bloodGroup == null
                ? bloodRequestRepository.findAll(pageable)
                : bloodRequestRepository.findByBloodGroup(bloodGroup, pageable);

        return PageResponse.from(requests.map(BloodRequestResponse::from));
    }

    @Transactional(readOnly = true)
    public BloodRequestResponse getById(Long id) {
        BloodRequest request = bloodRequestRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Solicitud de sangre no encontrada")
                );

        return BloodRequestResponse.from(request);
    }
}
