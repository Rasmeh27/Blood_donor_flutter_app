
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/date_format.dart';
import '../../../../general/utils/form_rules.dart';
import '../../../../general/utils/photo_picker.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/custom_blood_group_box.dart';
import '../../components/widgets/custom_find_screen_item.dart';
import '../../components/widgets/custom_form_textfield.dart';
import '../../components/widgets/custom_red_btn.dart';
import '../../components/widgets/find_donor_date_picker.dart';


class DonorRegistrationForm extends StatefulWidget {
  static const pageRoute = "/donor-registraion";

  // Selector de imágenes inyectable (las pruebas usan uno simulado)
  final PhotoPicker pickPhoto;

  const DonorRegistrationForm({super.key, this.pickPhoto = pickPhotoFromDevice});

  @override
  State<DonorRegistrationForm> createState() => _DonorRegistrationFormState();
}

class _DonorRegistrationFormState extends State<DonorRegistrationForm> {
  final _donorService = AppServices.instance.donors;

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();

  // Igual a la preselección visual del diseño (A+)
  String _bloodGroup = 'A+';
  DateTime? _lastDonationDate;
  bool _isSubmitting = false;
  // Foto mostrada (guardada o recién elegida) y foto pendiente de subir
  Uint8List? _photoPreview;
  PickedPhoto? _newPhoto;
  // Cambia al precargar datos para que los selectores se reconstruyan con el valor guardado
  int _prefillVersion = 0;

  @override
  void initState() {
    super.initState();
    // Un mensaje de la pantalla anterior podría tapar el botón "Complete"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
    _loadExistingRegistration();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Si el usuario ya es donante se muestran sus datos para actualizarlos (404 = formulario vacío)
  Future<void> _loadExistingRegistration() async {
    try {
      final donor = await _donorService.getMyDonor();
      if (donor == null || !mounted) return;
      setState(() {
        _nameController.text = donor.name;
        _contactController.text = donor.contactNumber;
        _locationController.text = donor.location;
        _bloodGroup = donor.bloodGroup;
        _lastDonationDate = donor.lastDonationDate;
        _prefillVersion++;
      });
      if (donor.hasPhoto) {
        final photo = await _donorService.getMyPhoto();
        if (mounted && _newPhoto == null) setState(() => _photoPreview = photo);
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    }
  }

  Future<void> _choosePhoto(ImageSource source) async {
    try {
      final photo = await widget.pickPhoto(source);
      if (photo == null || !mounted) return; // el usuario canceló
      final error = validatePhoto(photo.bytes);
      if (error != null) {
        _showMessage(error, isError: true);
        return;
      }
      setState(() {
        _newPhoto = photo;
        _photoPreview = photo.bytes;
      });
    } on PlatformException {
      if (mounted) _showMessage('Could not open the camera or gallery on this device.', isError: true);
    }
  }

  String? _validate() => firstError([
        () => requiredText(_nameController.text, 'Name', maxLength: 120),
        () => phoneNumber(_contactController.text, 'Contact number'),
        () => requiredText(_locationController.text, 'Location', maxLength: 150),
        () => _lastDonationDate == null ? 'Choose the last date of donation' : null,
      ]);

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
      final result = await _donorService.saveMyDonor(
        name: _nameController.text.trim(),
        contactNumber: normalizePhone(_contactController.text),
        bloodGroup: _bloodGroup,
        location: _locationController.text.trim(),
        lastDonationDate: _lastDonationDate!,
      );
      final photo = _newPhoto;
      if (photo != null) {
        await _donorService.uploadPhoto(photo.bytes, photo.fileName);
        _newPhoto = null;
      }
      if (!mounted) return;
      _showMessage(result.created ? 'Donor registration completed' : 'Donor information updated');
      Navigator.pop(context);
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
        actionTrue: true,
        titlee: "Donor Registration Form",
        
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomFormText(
                textt: "Select Donor picture",
                isRequired: true,
              ),
              verticalSpace(twentyPixelHeight(context)),
              
              // Vista previa en el mismo lugar y tamaño del placeholder original
              Center(child: _photoPreview == null
                  ? Image.asset("assets/icons/profile.png",width: twentyPixelWidth(context)*5,)
                  : ClipOval(child: Image.memory(_photoPreview!,
                      width: twentyPixelWidth(context)*5,
                      height: twentyPixelWidth(context)*5,
                      fit: BoxFit.cover))),
              verticalSpace(twentyPixelHeight(context)*.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _choosePhoto(ImageSource.camera),
                    child: Image.asset("assets/icons/camera_2.png",width: twentyPixelWidth(context)*1.5,),
                  ),
                  horizontalSpace(twentyPixelWidth(context)),
                  GestureDetector(
                    onTap: () => _choosePhoto(ImageSource.gallery),
                    child: Image.asset("assets/icons/gallary.png",width: twentyPixelWidth(context)*1.5,),
                  ),
                ],
              ),
              verticalSpace(twentyPixelHeight(context)),
            const CustomFormText(textt: 'Name', isRequired: true),
            verticalSpace(twentyPixelHeight(context)*.5),
            CustomFormTextfield(hintTextt: "Jorge Perez",prefixFalse: false, controller: _nameController,),


            verticalSpace(twentyPixelHeight(context)),
            const CustomFormText(textt: 'Contact Number', isRequired: true),
            verticalSpace(twentyPixelHeight(context)*.5),
            CustomFormTextfield(hintTextt: "+18092249304",prefixFalse: false, controller: _contactController, keyboardType: TextInputType.phone,),

            verticalSpace(twentyPixelHeight(context)),
            const CustomFormText(textt: "Blood Group", isRequired: true),
            verticalSpace(twentyPixelHeight(context)),
            
            Padding(
              padding:  EdgeInsets.only(
                left: twentyPixelWidth(context)*1.5,
                right: twentyPixelWidth(context)*1.5,
              ),
              child: CustomBloodGroupBox(
                key: ValueKey('blood-$_prefillVersion'),
                initialValue: _bloodGroup,
                onChanged: (group) => _bloodGroup = group,
              ),
            ),

            verticalSpace(twentyPixelHeight(context)),

        
            const CustomFormText(textt: "Location", isRequired: true),
            verticalSpace(twentyPixelHeight(context)*.5),
            CustomFormTextfield(hintTextt: "Santo Domingo, RD",prefixFalse: true,prefixxIcon:Icons.location_on, controller: _locationController),

            verticalSpace(twentyPixelHeight(context)),
            const CustomFormText(textt: "Last Date of Donation", isRequired: true),
            verticalSpace(twentyPixelHeight(context)*.5),
            FindDonorDatePicker(
              key: ValueKey('date-$_prefillVersion'),
              initialDate: _lastDonationDate,
              lastDate: today(),
              onChanged: (date) => _lastDonationDate = date,
            ),
            verticalSpace(twentyPixelHeight(context)*1.5),
            CustomRedBtn(
              textt: "Complete", 
              textColor: AppColor.whiteColor, 
              fillColor: AppColor.redColor,
              borderClr: Colors.transparent,
              onTap: _submit,
              ),

            
              
            ],
          ),
        ),
      ),
    );
  }
}

