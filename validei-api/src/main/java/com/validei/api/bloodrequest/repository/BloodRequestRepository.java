package com.validei.api.bloodrequest.repository;

import com.validei.api.bloodrequest.entity.BloodRequest;
import com.validei.api.common.domain.BloodGroup;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BloodRequestRepository extends JpaRepository<BloodRequest, Long> {

    Page<BloodRequest> findByBloodGroup(BloodGroup bloodGroup, Pageable pageable);
}
