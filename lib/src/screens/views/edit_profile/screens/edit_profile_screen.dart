import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/form_rules.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/donor.dart';
import '../../../../models/gender.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/custom_find_screen_item.dart';
import '../../components/widgets/custom_form_textfield.dart';
import '../../components/widgets/custom_gender_box.dart';
import '../../components/widgets/custom_red_btn.dart';

/// Pantalla añadida: el archivo original estaba vacío. Usa solo los componentes y estilos
/// del profesor (los mismos de DonorRegistrationForm y ProfileScreen).
/// Edita los campos que admite PATCH /api/v1/users/me: nombre, teléfono, ubicación y género.
/// Si el usuario es donante, también su consentimiento para aparecer en la búsqueda de donantes.
class EditProfileScreen extends StatefulWidget {
  static const pageRoute = "/edit-profile";

  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _services = AppServices.instance;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  Gender? _gender;
  Donor? _donor;
  bool _visibleInSearch = false;
  bool _isSaving = false;
  // Cambia al recibir los datos del servidor para reconstruir el selector con el género guardado
  int _prefillVersion = 0;

  @override
  void initState() {
    super.initState();
    // Un mensaje de la pantalla anterior podría tapar el botón inferior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
    final cachedUser = _services.session.currentUser;
    if (cachedUser != null) _fill(cachedUser);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _fill(UserProfile user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _locationController.text = user.location ?? '';
    _gender = user.gender;
    _prefillVersion++;
  }

  Future<void> _loadCurrentUser() async {
    try {
      final results = await Future.wait([
        _services.users.getCurrentUser(),
        _services.donors.getMyDonor(),
      ]);
      if (!mounted) return;
      setState(() {
        _fill(results[0] as UserProfile);
        _donor = results[1] as Donor?;
        _visibleInSearch = _donor?.visibleInSearch ?? false;
      });
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    }
  }

  String? _validate() => firstError([
        () => requiredText(_nameController.text, 'Name', maxLength: 120),
        () => _phoneController.text.trim().isEmpty ? null : phoneNumber(_phoneController.text, 'Mobile number'),
        () => _locationController.text.trim().length > 150 ? 'Location must have at most 150 characters' : null,
      ]);

  Future<void> _save() async {
    if (_isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final error = _validate();
    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Los campos vacíos no se envían: la API conserva el valor guardado (no permite borrarlo)
      final phone = _phoneController.text.trim();
      final location = _locationController.text.trim();
      await _services.users.updateCurrentUser(
        name: _nameController.text.trim(),
        phone: phone.isEmpty ? null : normalizePhone(phone),
        location: location.isEmpty ? null : location,
        gender: _gender,
      );
      final donor = _donor;
      if (donor != null && donor.visibleInSearch != _visibleInSearch) {
        _donor = await _services.donors.updateSearchVisibility(_visibleInSearch);
      }
      if (!mounted) return;
      _showMessage('Profile updated');
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: isError ? Colors.red : null,
        content: Text(message),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titlee: "Edit Profile",
        actionTrue: true,
        profileFalse: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomFormText(textt: 'Name', isRequired: true),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                hintTextt: "Jorge Perez",
                prefixFalse: true,
                prefixxIcon: Icons.person,
                controller: _nameController,
              ),

              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(textt: 'Mobile Number', isRequired: false),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                hintTextt: "+18092249304",
                prefixFalse: true,
                prefixxIcon: Icons.call,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),

              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(textt: 'Location', isRequired: false),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                hintTextt: "Santo Domingo, RD",
                prefixFalse: true,
                prefixxIcon: Icons.location_on,
                controller: _locationController,
              ),

              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(textt: 'Gender', isRequired: false),
              verticalSpace(twentyPixelHeight(context) * 1.5),
              Padding(
                padding: EdgeInsets.only(
                  left: twentyPixelWidth(context) * 3,
                  right: twentyPixelWidth(context) * 3,
                ),
                child: CustomGenderBox(
                  key: ValueKey('gender-$_prefillVersion'),
                  initialValue: _gender == Gender.female ? 'female' : 'male',
                  onChanged: (value) => _gender = Gender.fromSelector(value),
                ),
              ),

              if (_donor != null) ...[
                verticalSpace(twentyPixelHeight(context) * 1.5),
                Row(
                  children: [
                    const Expanded(
                      child: CustomFormText(textt: 'Show me in donor search', isRequired: false),
                    ),
                    Switch(
                      value: _visibleInSearch,
                      activeThumbColor: AppColor.whiteColor,
                      activeTrackColor: AppColor.redColor,
                      onChanged: (value) => setState(() => _visibleInSearch = value),
                    ),
                  ],
                ),
                const Text(
                  'Registered users will see your name, blood group, location and last donation date. '
                  'Your phone number and email are never shown.',
                  style: TextStyle(
                    color: AppColor.textAss,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],

              verticalSpace(twentyPixelHeight(context) * 1.5),
              CustomRedBtn(
                textt: "Save",
                textColor: AppColor.whiteColor,
                fillColor: AppColor.redColor,
                borderClr: Colors.transparent,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
