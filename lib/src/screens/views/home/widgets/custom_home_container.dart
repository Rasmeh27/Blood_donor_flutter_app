
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';


// ignore: must_be_immutable
class CustomHomeContainer extends StatelessWidget {
  Color containerBgColor;
  String containerTextt;
  String imageUrl;
  Color textColorr;

  CustomHomeContainer({
    super.key, 
    required this.containerBgColor,
    required this.containerTextt,
    required this.imageUrl,
    required this.textColorr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: twentyPixelWidth(context) * 6,
      height: twentyPixelHeight(context) * 6,
      decoration: ShapeDecoration(
        color: containerBgColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 2, color: AppColor.redColor),
          borderRadius: BorderRadius.circular(5),
        ),
        shadows:const [
           BoxShadow(
            color: AppColor.textMedium,
            blurRadius: 10,
            offset: Offset(5, 5),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            imageUrl,
            width: twentyPixelWidth(context) * 2.5,
            height: twentyPixelHeight(context) * 2.5,
          ),
          verticalSpace(twentyPixelWidth(context) * .25),
          Text(
            containerTextt,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColorr,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
            textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
          )
        ],
      ),
    );
  }
}
