import '../general/utils/date_format.dart';

// Corresponde a DonorResponse del backend
class Donor {
  final int id;
  final String name;
  final String contactNumber;
  final String bloodGroup;
  final String location;
  final DateTime lastDonationDate;
  // Consentimiento para aparecer en la búsqueda de donantes
  final bool visibleInSearch;
  final bool hasPhoto;

  const Donor({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.bloodGroup,
    required this.location,
    required this.lastDonationDate,
    this.visibleInSearch = false,
    this.hasPhoto = false,
  });

  factory Donor.fromJson(Map<String, dynamic> json) {
    return Donor(
      id: json['id'] as int,
      name: json['name'] as String,
      contactNumber: json['contactNumber'] as String,
      bloodGroup: json['bloodGroup'] as String,
      location: json['location'] as String,
      lastDonationDate: parseApiDate(json['lastDonationDate'] as String),
      visibleInSearch: json['visibleInSearch'] as bool? ?? false,
      hasPhoto: json['hasPhoto'] as bool? ?? false,
    );
  }
}

// Corresponde a DonorSearchResult: datos públicos, sin teléfono ni correo
class DonorSearchResult {
  final int id;
  final String name;
  final String bloodGroup;
  final String location;
  final DateTime lastDonationDate;

  const DonorSearchResult({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.location,
    required this.lastDonationDate,
  });

  factory DonorSearchResult.fromJson(Map<String, dynamic> json) {
    return DonorSearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      bloodGroup: json['bloodGroup'] as String,
      location: json['location'] as String,
      lastDonationDate: parseApiDate(json['lastDonationDate'] as String),
    );
  }
}
