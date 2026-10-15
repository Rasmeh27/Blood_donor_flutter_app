
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';

// ignore: must_be_immutable
class CustomFormTextfield extends StatelessWidget {
  String hintTextt;
  IconData? prefixxIcon;
  bool? prefixFalse;
  TextEditingController? controller;
  TextInputType? keyboardType;

  CustomFormTextfield({
    super.key,
    required this.hintTextt,
     this.prefixxIcon,
     this.prefixFalse,

    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: twentyPixelHeight(context) * 2.3,
      decoration: ShapeDecoration(
        color: AppColor.blackColor.withAlpha(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
              prefixIcon:prefixFalse ==false?null: Icon(
                prefixxIcon,
                color: AppColor.blackColor.withAlpha(30),
              ),
              hintText: hintTextt,
              hintStyle: TextStyle(color: AppColor.blackColor.withAlpha(30)),
              border: const OutlineInputBorder(borderSide: BorderSide.none)),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class CustomAuthText extends StatelessWidget {
  String textt;

  CustomAuthText({super.key, required this.textt});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          textt,
          style: const TextStyle(
            color: AppColor.blackColor,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
        ),
        Text(
          '*required',
          style: const TextStyle(
            color: Color(0xFFA30000),
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
        ),
      ],
    );
  }
}
