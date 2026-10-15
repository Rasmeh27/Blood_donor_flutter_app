

import 'package:form_field_validator/form_field_validator.dart';

final passwordValidator = MultiValidator([
  RequiredValidator(errorText: 'password is required'),
  MinLengthValidator(8, errorText: 'password must be at least 8 chars long'),
  PatternValidator(r'(?=.*?[#?!@$%^&*-])', errorText: 'password  must have at least one special character')
]);

final emailvalidator = MultiValidator([
  RequiredValidator(errorText: 'email is required'),
  EmailValidator(errorText: 'enter a valid email address')
]);

final nameValidator = MultiValidator([
  RequiredValidator(errorText: "name is required")
]);

//para el registro necesitamos validar que las contrasenas
//coincidan