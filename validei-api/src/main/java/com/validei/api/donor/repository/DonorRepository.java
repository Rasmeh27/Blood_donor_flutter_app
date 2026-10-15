package com.validei.api.donor.repository;

import com.validei.api.common.domain.BloodGroup;
import com.validei.api.donor.entity.Donor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DonorRepository extends JpaRepository<Donor, Long> {

    Optional<Donor> findByUserId(Long userId);

    // Solo donantes que dieron su consentimiento; los filtros nulos no se aplican
    @Query("""
            select d from Donor d
             where d.visibleInSearch = true
               and d.user.id <> :excludedUserId
               and (:bloodGroup is null or d.bloodGroup = :bloodGroup)
               and (:locationPattern is null or lower(d.location) like :locationPattern escape '!')
            """)
    Page<Donor> searchVisible(
            @Param("excludedUserId") Long excludedUserId,
            @Param("bloodGroup") BloodGroup bloodGroup,
            @Param("locationPattern") String locationPattern,
            Pageable pageable
    );
}
