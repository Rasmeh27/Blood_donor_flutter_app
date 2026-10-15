enum Gender {
  male('MALE', 'Male'),
  female('FEMALE', 'Female');

  final String apiValue;
  final String label;

  const Gender(this.apiValue, this.label);

  static Gender? fromApi(String? value) {
    for (final gender in values) {
      if (gender.apiValue == value) return gender;
    }
    return null;
  }

  // CustomGenderBox usa "male" / "female"
  static Gender fromSelector(String value) =>
      value.toLowerCase() == 'female' ? Gender.female : Gender.male;
}
