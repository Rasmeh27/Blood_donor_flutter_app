
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';


class CustomBloodGroupBox extends StatefulWidget { 
  // Grupo preseleccionado (p. ej. datos guardados del donante); por defecto el primero, como en el diseño
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  const CustomBloodGroupBox({super.key, this.initialValue, this.onChanged});

  @override
  State<CustomBloodGroupBox> createState() => _CustomBloodGroupBoxState();
}

class _CustomBloodGroupBoxState extends State<CustomBloodGroupBox> {
  int selectedIndex = 0;
  var bloodList = [
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
    final initialIndex = bloodList.indexOf(widget.initialValue ?? '');
    if (initialIndex >= 0) selectedIndex = initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: twentyPixelWidth(context) * 1.25,
              mainAxisSpacing: twentyPixelHeight(context) * 1),
          itemCount: 8,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                widget.onChanged?.call(bloodList[index]);
              },
              child: Container(
                  width: twentyPixelWidth(context) * 2.5,
                  height: twentyPixelWidth(context) * 2.5,
                  decoration: ShapeDecoration(
                    color: selectedIndex == index
                        ? AppColor.redColor
                        : AppColor.whiteColor,
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
                      bloodList[index],
                      style: TextStyle(
                        color: selectedIndex == index
                            ? AppColor.whiteColor
                            : AppColor.redColor,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                      textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                    ),
                  )),
            );
          }),
    );
  }
}
