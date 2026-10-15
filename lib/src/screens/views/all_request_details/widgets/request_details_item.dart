
import 'package:flutter/material.dart';

import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';


class RequestDetailsItem extends StatelessWidget {
  final String titlee;
  final String textt;
  const RequestDetailsItem({super.key, required this.titlee, required this.textt});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titlee,
          style: const TextStyle(
            color: Color(0xFF7A7A7A),
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w300,
          ),
          textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
        ),
        Text(
          textt,
          style: const TextStyle(
            color: Color(0xFF222222),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
        ),
        verticalSpace(twentyPixelHeight(context)*.5),
      ],
    );
  }
}
