

import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';
import '../../profile/screens/profile_screen.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titlee;
  final Widget? leadingBtn;
  final bool actionTrue;
  final bool? profileFalse; 
  const CustomAppBar({super.key, required this.titlee, this.leadingBtn, required this.actionTrue, this.profileFalse});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: AppColor.redColor,
        centerTitle: true,
        leading: leadingBtn?? InkWell(
          onTap: (){
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: AppColor.whiteColor,
          ),
        ),
        actions: [
          actionTrue == true?
          InkWell(
            onTap: (){
              profileFalse != true? Navigator.pushNamed(context, ProfileScreen.pageRoute):null;
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.whiteColor),
                borderRadius: BorderRadius.circular(200),
              ),
              child: Center(
                child: Image.asset("assets/images/profile.png"),
              ),
            ),
          ) : const SizedBox(),
          Padding(
              padding: EdgeInsets.only(left: twentyPixelWidth(context) * .5)),
        ],
        title: Text(
          titlee,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColor.whiteColor,
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
        ),
      );
  }
  
  @override
  
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

