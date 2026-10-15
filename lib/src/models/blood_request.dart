import '../general/utils/date_format.dart';
import 'gender.dart';

// Corresponde a BloodRequestResponse del backend
class BloodRequest {
  final int id;
  final String bloodGroup;
  final int bags;
  final String contactNumber;
  final String emergencyContact;
  final String patientName;
  final String caseDescription;
  final Gender? patientGender;
  final DateTime needBefore;
  final String? location;
  final String? others;
  final DateTime createdAt;

  const BloodRequest({
    required this.id,
    required this.bloodGroup,
    required this.bags,
    required this.contactNumber,
    required this.emergencyContact,
    required this.patientName,
    required this.caseDescription,
    required this.needBefore,
    required this.createdAt,
    this.patientGender,
    this.location,
    this.others,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] as int,
      bloodGroup: json['bloodGroup'] as String,
      bags: json['bags'] as int,
      contactNumber: json['contactNumber'] as String,
      emergencyContact: json['emergencyContact'] as String,
      patientName: json['patientName'] as String,
      caseDescription: json['caseDescription'] as String,
      patientGender: Gender.fromApi(json['patientGender'] as String?),
      needBefore: parseApiDate(json['needBefore'] as String),
      location: json['location'] as String?,
      others: json['others'] as String?,
      createdAt: parseTimestamp(json['createdAt'] as String),
    );
  }
}

/// Datos que el usuario introduce en FindDonorScreen (CreateBloodRequest del backend).
class NewBloodRequest {
  final String bloodGroup;
  final int bags;
  final String contactNumber;
  final String emergencyContact;
  final String patientName;
  final String caseDescription;
  final Gender? patientGender;
  final DateTime needBefore;
  final String? others;

  const NewBloodRequest({
    required this.bloodGroup,
    required this.bags,
    required this.contactNumber,
    required this.emergencyContact,
    required this.patientName,
    required this.caseDescription,
    required this.needBefore,
    this.patientGender,
    this.others,
  });

  // El formulario no tiene campo de ubicación, por lo que no se envía (decisión D4 pendiente)
  Map<String, dynamic> toJson() => {
        'bloodGroup': bloodGroup,
        'bags': bags,
        'contactNumber': contactNumber,
        'emergencyContact': emergencyContact,
        'patientName': patientName,
        'caseDescription': caseDescription,
        'patientGender': patientGender?.apiValue,
        'needBefore': toApiDate(needBefore),
        if (others != null && others!.isNotEmpty) 'others': others,
      };
}
