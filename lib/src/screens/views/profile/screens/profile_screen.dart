
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/donor.dart';
import '../../../../models/user_profile.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../all_request_details/widgets/request_details_item.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/custom_red_btn.dart';
import '../../edit_profile/screens/edit_profile_screen.dart';


class ProfileScreen extends StatefulWidget {
  static const pageRoute = "/profile";

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _missing = '—';

  final _services = AppServices.instance;

  // Mientras llega la respuesta se muestran los datos guardados al iniciar sesión
  late UserProfile? _user = _services.session.currentUser;
  Donor? _donor;
  // Foto del registro de donante; sin foto se mantiene la imagen original del diseño
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    // Un mensaje de la pantalla anterior podría tapar el botón inferior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _services.users.getCurrentUser(),
        _services.donors.getMyDonor(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserProfile;
        _donor = results[1] as Donor?;
      });
      if (_donor?.hasPhoto ?? false) {
        final photo = await _services.donors.getMyPhoto();
        if (mounted) setState(() => _photo = photo);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(error.message)),
      );
    }
  }

  // Al volver de editar se recargan los datos desde el servidor
  Future<void> _openEditProfile() async {
    await Navigator.pushNamed(context, EditProfileScreen.pageRoute);
    if (mounted) _load();
  }

  // Primero los datos del perfil (editables en EditProfileScreen); si faltan, los del registro de donante
  String get _location => _user?.location ?? _donor?.location ?? _missing;
  String get _phone => _user?.phone ?? _donor?.contactNumber ?? _missing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titlee: "Profile", actionTrue: true, profileFalse: true,),
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: twentyPixelWidth(context),
            vertical: twentyPixelHeight(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: twentyPixelWidth(context) * 6.5,
                    height: twentyPixelWidth(context) * 6.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      border: Border.all(color: AppColor.redColor, width: 1),
                    ),
                  ),
                  Container(
                    width: twentyPixelWidth(context) * 6,
                    height: twentyPixelWidth(context) * 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: _photo == null
                        ? Image.asset("assets/images/profile.png")
                        : ClipOval(child: Image.memory(_photo!, fit: BoxFit.cover)),
                  ),
                ],
              ),
            ),
            verticalSpace(twentyPixelHeight(context) * 2),
            RequestDetailsItem(titlee: "Name", textt: _user?.name ?? _missing),
            RequestDetailsItem(titlee: "Location", textt: _location),
            RequestDetailsItem(titlee: "Gender", textt: _user?.gender?.label ?? _missing),
            RequestDetailsItem(titlee: "Blood Group", textt: _donor?.bloodGroup ?? _missing),
            RequestDetailsItem(titlee: "Mobile Number", textt: _phone),
            const Expanded(child: SizedBox()),
            CustomRedBtn(
                textt: "Edit Profile",
                textColor: Colors.white,
                fillColor: AppColor.redColor,
                borderClr: Colors.transparent,
                onTap: _openEditProfile,
                ),

                verticalSpace(twentyPixelHeight(context)*.5)
          ],
        ),
      ),
    );
  }
}
