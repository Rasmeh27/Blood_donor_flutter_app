package com.validei.api.user.service;

import com.validei.api.common.exception.ResourceNotFoundException;
import com.validei.api.user.dto.UpdateProfileRequest;
import com.validei.api.user.dto.UserResponse;
import com.validei.api.user.entity.User;
import com.validei.api.user.repository.UserRepository;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


@Service
public class UserService {

    private final UserRepository userRepository;

    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public UserResponse getUserById(Long id) {

        return UserResponse.from(findUser(id));
    }

    @Transactional
    public UserResponse updateProfile(Long id, UpdateProfileRequest request) {
        User user = findUser(id);

        if (request.name() != null) {
            user.updateName(request.name());
        }
        if (request.phone() != null) {
            user.updatePhone(request.phone());
        }
        if (request.gender() != null) {
            user.updateGender(request.gender());
        }
        if (request.location() != null) {
            user.updateLocation(request.location());
        }

        // Escritura inmediata para que updated_at y la respuesta reflejen el cambio
        return UserResponse.from(userRepository.saveAndFlush(user));
    }

    @Transactional(readOnly = true)
    public boolean emailExist(String email) {
        return userRepository.existsByEmailIgnoreCase(email);
    }

    // Usado también por otros módulos para obtener al usuario autenticado
    @Transactional(readOnly = true)
    public User findUser(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() ->
                        new ResourceNotFoundException("Usuario no encontrado")
                );
    }
}
