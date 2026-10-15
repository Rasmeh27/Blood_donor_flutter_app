
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';


class CustomGenderBtn extends StatelessWidget {
  const CustomGenderBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: twentyPixelWidth(context) * 4,
          height: twentyPixelWidth(context) * 4,
          decoration: BoxDecoration(
            color: AppColor.redColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow:const [
               BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 10,
                offset: Offset(5, 5),
                spreadRadius: 0,
              )
            ],
          ),
          child: Center(
            child: Image.asset(
              "assets/images/male_w.png",
              width: twentyPixelWidth(context) * 2.5,
              height: twentyPixelWidth(context) * 2.5,
            ),
          ),
        ),
        Text(
          'Male',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColor.blackColor,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
          textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
        )
      ],
    );
  }
}
