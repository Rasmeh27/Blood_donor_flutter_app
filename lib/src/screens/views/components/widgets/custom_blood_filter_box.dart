
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';


class CustomBloodFilterBox extends StatefulWidget {
  // Recibe el grupo elegido, o null cuando se selecciona "All"
  final ValueChanged<String?>? onChanged;
  // Grupo preseleccionado; null deja "All", como en el diseño
  final String? initialValue;

  const CustomBloodFilterBox({super.key, this.onChanged, this.initialValue});

  @override
  State<CustomBloodFilterBox> createState() => _CustomBloodGroupBoxState();
}

class _CustomBloodGroupBoxState extends State<CustomBloodFilterBox> {
  int selectedIndex = 0;
  var bloodList = [
    "All",
    "A+",
    "B+",
    "AB+",
    "O+",
    "A-",
    "B-",
    "AB-",
    "O-",
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = bloodList.indexOf(widget.initialValue ?? 'All');
    if (initialIndex >= 0) selectedIndex = initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: twentyPixelHeight(context) * 3,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: bloodList.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onChanged?.call(index == 0 ? null : bloodList[index]);
              },
              child: Center(
                child: Container(
                    margin:
                        EdgeInsets.only(right: twentyPixelWidth(context) * .5),
                    width: twentyPixelWidth(context) * 2,
                    height: twentyPixelWidth(context) * 2,
                    decoration: ShapeDecoration(
                      color: selectedIndex == index
                          ? AppColor.redColor
                          : AppColor.whiteColor,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: AppColor.redColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadows:const [
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
                        bloodList[index],
                        style: TextStyle(
                          color: selectedIndex == index
                              ? AppColor.whiteColor
                              : AppColor.redColor,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                        textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                      ),
                    )),
              ),
            );
          }),
    );
  }
}
