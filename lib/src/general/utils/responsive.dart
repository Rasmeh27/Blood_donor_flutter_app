import 'dart:math';

import 'package:flutter/material.dart';

responsiveHeight(BuildContext context, double value) {
  return MediaQuery.sizeOf(context).height * value;
}

responsiveWidth(BuildContext context, double value) {
  return MediaQuery.sizeOf(context).width * value;
}

double twentyTwoPixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.05867);
}

double twentyPixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.053335);
}

double sixteenPixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.0425);
}

double fifteenPixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.04);
}

double fourteenPixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.03735);
}

double thirteenPixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.03466675);
}

double twelvePixelWidth(BuildContext context) {
  return responsiveWidth(context, 0.032);
}

double sixteenPixelHeight(BuildContext context) {
  return responsiveHeight(context, 0.01975);
}

double twentyPixelHeight(BuildContext context) {
  return responsiveHeight(context, 0.02465);
}


class ScaleSize {
  static double textScaleFactor(BuildContext context,
      {double maxTextScaleFactor = 2}) {
    final width = MediaQuery.of(context).size.width;
    double val = (width / 1400) * maxTextScaleFactor;
    return max(1, min(val, maxTextScaleFactor));
  }
}