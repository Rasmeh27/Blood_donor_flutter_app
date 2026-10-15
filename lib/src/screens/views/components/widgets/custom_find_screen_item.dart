
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';


class CustomFormText extends StatelessWidget {
  final String textt;
  final bool isRequired;
  const CustomFormText({super.key, required this.textt, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          isRequired==true? "*required": "",
          style: const TextStyle(
            color: AppColor.redColor,
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
