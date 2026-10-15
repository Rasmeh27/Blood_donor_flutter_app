import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/date_format.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/donor.dart';

/// Tarjeta de un donante encontrado. Componente añadido: reutiliza exactamente el estilo de
/// CustomRequestFeedItem (contenedor, sombra, insignia del grupo, iconos y tipografía Poppins).
class DonorResultItem extends StatelessWidget {
  final DonorSearchResult donor;

  const DonorResultItem({super.key, required this.donor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColor.whiteColor,
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: twentyPixelWidth(context) * 1.9,
                height: twentyPixelWidth(context) * 1.9,
                decoration: const ShapeDecoration(
                  color: AppColor.redColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    donor.bloodGroup,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                    textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                  ),
                ),
              ),
              horizontalSpace(twentyPixelWidth(context) * .5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    verticalSpace(twentyPixelHeight(context) * .1),
                    Text(
                      donor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColor.blackColor,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                      textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                    ),
                    Text(
                      'Blood donor',
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColor.textAss,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                      textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          verticalSpace(twentyPixelHeight(context) * .5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: twentyPixelWidth(context) * .5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(context, "assets/icons/request_location.png", donor.location),
                verticalSpace(4),
                _infoRow(context, "assets/icons/request_date.png",
                    'Last donation: ${toLongDate(donor.lastDonationDate)}'),
              ],
            ),
          ),
          verticalSpace(twentyPixelHeight(context) * .5),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(icon, width: twentyPixelWidth(context), height: twentyPixelHeight(context)),
        horizontalSpace(twentyPixelWidth(context) * .4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColor.blackColor,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
            textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
          ),
        ),
      ],
    );
  }
}
