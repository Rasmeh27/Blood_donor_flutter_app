
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/date_format.dart';
import '../../../../general/utils/form_rules.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/blood_request.dart';
import '../../../../models/gender.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../donor_search/screens/donor_search_screen.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/custom_blood_group_box.dart';
import '../../components/widgets/custom_find_screen_item.dart';
import '../../components/widgets/custom_form_textfield.dart';
import '../../components/widgets/custom_gender_box.dart';
import '../../components/widgets/custom_red_btn.dart';
import '../../components/widgets/find_donor_date_picker.dart';


class FindDonorScreen extends StatefulWidget {
  static const pageRoute = '/find-donor';

  const FindDonorScreen({super.key});

  @override
  State<FindDonorScreen> createState() => _FindDonorScreenState();
}

class _FindDonorScreenState extends State<FindDonorScreen> {
  final _bloodRequestService = AppServices.instance.bloodRequests;

  final _bagsController = TextEditingController();
  final _contactController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _caseController = TextEditingController();
  final _othersController = TextEditingController();

  // Valores iniciales iguales a la preselección visual del diseño (A+ y male)
  String _bloodGroup = 'A+';
  String _gender = 'male';
  DateTime? _needBefore;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dismissPreviousMessage();
  }

  // Un mensaje de la pantalla anterior podría tapar el botón "Find Donors"
  void _dismissPreviousMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  void dispose() {
    for (final controller in [
      _bagsController,
      _contactController,
      _emergencyContactController,
      _patientNameController,
      _caseController,
      _othersController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate() => firstError([
        () => numberOfBags(_bagsController.text),
        () => phoneNumber(_contactController.text, 'Contact number'),
        () => phoneNumber(_emergencyContactController.text, 'Emergency contact'),
        () => requiredText(_patientNameController.text, 'Patient name', maxLength: 120),
        () => requiredText(_caseController.text, 'Case', maxLength: 150),
        () => _needBefore == null ? 'Choose the date the blood is needed before' : null,
        () => _othersController.text.trim().length > 255 ? 'Others must have at most 255 characters' : null,
      ]);

  // "Find Donors" publica la solicitud y luego abre la búsqueda de donantes del mismo grupo
  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final error = _validate();
    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final created = await _bloodRequestService.create(NewBloodRequest(
        bloodGroup: _bloodGroup,
        bags: int.parse(_bagsController.text.trim()),
        contactNumber: normalizePhone(_contactController.text),
        emergencyContact: normalizePhone(_emergencyContactController.text),
        patientName: _patientNameController.text.trim(),
        caseDescription: _caseController.text.trim(),
        patientGender: Gender.fromSelector(_gender),
        needBefore: _needBefore!,
        others: _othersController.text.trim(),
      ));
      if (!mounted) return;
      // La ubicación se toma del perfil; si aún no la tiene se indica dónde configurarla
      _showMessage(created.location == null
          ? 'Blood request published. Add your location in Edit Profile so it appears in your requests.'
          : 'Blood request published');
      // "Find Donors": tras publicar se muestran los donantes disponibles del mismo grupo
      Navigator.pushReplacementNamed(context, DonorSearchScreen.pageRoute, arguments: _bloodGroup);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    // Reemplaza el mensaje anterior para que el usuario vea siempre el error actual
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
        titlee: "Request for Blood Donor",
        actionTrue: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: twentyPixelWidth(context),
            right: twentyPixelWidth(context),
            bottom: twentyPixelHeight(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(twentyPixelHeight(context)),
              Center(
                child: Text(
                  "Patient Details",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.blackColor,
                      fontFamily: "Poppins"),
                  textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                ),
              ),
              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Choose Blood Group",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              Padding(
                padding:  EdgeInsets.only(
                  left: twentyPixelWidth(context)*1.5,
                  right: twentyPixelWidth(context)*1.5,
                ),
                child: CustomBloodGroupBox(onChanged: (group) => _bloodGroup = group),
              ),

              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Number of Bags",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              Row(
                children: [
                  Expanded(
                      child: CustomFormTextfield(
                    hintTextt: "3",
                    prefixFalse: false,
                    controller: _bagsController,
                    keyboardType: TextInputType.number,
                  )),
                  horizontalSpace(twentyPixelWidth(context) * .5),
                  const Text(
                    "Bags",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: "Poppins",
                      color: AppColor.blackColor,
                    ),
                  )
                ],
              ),
              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Contact Number",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                  hintTextt: "+880188888888", prefixxIcon: Icons.call,
                  controller: _contactController, keyboardType: TextInputType.phone),

              //Emergency Contact
              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Emergency Contact",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                hintTextt: "+88019999999",
                prefixFalse: true,
                prefixxIcon: Icons.call,
                controller: _emergencyContactController,
                keyboardType: TextInputType.phone,
              ),

              //Patient Nabe
              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Patient Name",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                  hintTextt: "Jorge Perez",
                  prefixFalse: true,
                  prefixxIcon: Icons.person,
                  controller: _patientNameController),

              //Case
              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Case",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                  hintTextt: "Cancer Patient",
                  prefixFalse: false,
                  prefixxIcon: Icons.person,
                  controller: _caseController),

              //Gender
              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Gender",
                isRequired: false,
              ),
              verticalSpace(twentyPixelHeight(context) * 1.5),

              Padding(
                padding:  EdgeInsets.only(
                  left: twentyPixelWidth(context)*3,
                  right: twentyPixelWidth(context)*3,
                ),
                child: CustomGenderBox(onChanged: (gender) => _gender = gender),
              ),

              verticalSpace(twentyPixelHeight(context) * 1.5),
              const CustomFormText(
                  textt: "Blood Need Before", isRequired: true),
              verticalSpace(twentyPixelHeight(context) * .5),

              FindDonorDatePicker(
                firstDate: today(),
                onChanged: (date) => _needBefore = date,
              ),
              


              verticalSpace(twentyPixelHeight(context)),
              const CustomFormText(
                textt: "Others",
                isRequired: false,
              ),
              verticalSpace(twentyPixelHeight(context) * .5),
              CustomFormTextfield(
                  hintTextt: "Others",
                  prefixFalse: true,
                  prefixxIcon: Icons.person,
                  controller: _othersController),
              verticalSpace(twentyPixelHeight(context) * 2),
              CustomRedBtn(
                textt: "Find Donors",
                textColor: AppColor.whiteColor,
                fillColor: AppColor.redColor,
                borderClr: Colors.transparent,
                onTap: _submit,
              )
            ],
          ),
        ),
      ),
    );
  }
}
