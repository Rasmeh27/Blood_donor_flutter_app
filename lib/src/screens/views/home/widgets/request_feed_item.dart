import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../general/utils/date_format.dart';
import '../../../../models/blood_request.dart';
import '../../all_request_details/screens/request_details_screen.dart';

class CustomRequestFeedItem extends StatelessWidget {
  final BloodRequest request;

  const CustomRequestFeedItem({super.key, required this.request});

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
          // FILA SUPERIOR: Avatar/Grupo sanguíneo, Nombre y Tiempo
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
                    request.bloodGroup,
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
                      request.patientName,
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
                      '${request.bags} Bag | ${request.caseDescription}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              horizontalSpace(twentyPixelWidth(context) * .3),
              Padding(
                padding: EdgeInsets.only(
                  top: twentyPixelHeight(context) * .5,
                  right: twentyPixelWidth(context) * .5,
                ),
                child: Text(
                  timeAgo(request.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColor.textAss,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                ),
              ),
            ],
          ),

          verticalSpace(twentyPixelHeight(context) * .5),

          // FILA INFERIOR: Dirección, Fecha y Botón de Detalles
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: twentyPixelWidth(context) * .5,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila de Ubicación
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/request_location.png",
                            width: twentyPixelWidth(context),
                            height: twentyPixelHeight(context),
                          ),
                          horizontalSpace(twentyPixelWidth(context) * .4),
                          Expanded(
                            child: Text(
                              request.location ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColor.blackColor,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                              textScaler: TextScaler.linear(
                                ScaleSize.textScaleFactor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      verticalSpace(4),
                      // Fila de Fecha (Línea 166)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/icons/request_date.png",
                            width: twentyPixelWidth(context),
                            height: twentyPixelHeight(context),
                          ),
                          horizontalSpace(twentyPixelWidth(context) * .4),
                          Expanded(
                            child: Text(
                              toLongDate(request.needBefore),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColor.blackColor,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                              textScaler: TextScaler.linear(
                                ScaleSize.textScaleFactor(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                horizontalSpace(8),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RequestDetailsScreen.pageRoute,
                      arguments: request.id,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFA30000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Details',
                        style: const TextStyle(
                          color: AppColor.whiteColor,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.linear(
                          ScaleSize.textScaleFactor(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          verticalSpace(twentyPixelHeight(context) * .5),
        ],
      ),
    );
  }
}