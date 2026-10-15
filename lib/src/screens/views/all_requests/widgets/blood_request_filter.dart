
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';


class BloodGroupFilterIcon extends StatelessWidget {
  const BloodGroupFilterIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
        width: twentyPixelWidth(context) * 2,
        height: twentyPixelWidth(context) * 2,
        decoration: ShapeDecoration(
          color: AppColor.redColor,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColor.redColor),
            borderRadius: BorderRadius.circular(10),
          ),
          shadows: const [
             BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: 0,
            )
          ],
        ),
        child: Center(
          child: Text(
            'A+',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
            textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
          ),
        ));
  }
}
