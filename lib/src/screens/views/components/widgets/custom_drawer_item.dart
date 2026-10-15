
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/responsive.dart';

class CustomDrawerItem extends StatelessWidget {
  final String textt;
  final IconData suffixIcon;
  final String onTapp;
  // Acción propia (por ejemplo, Logout). Si no se indica, se navega a la ruta onTapp.
  final VoidCallback? onTap;
  const CustomDrawerItem({super.key, required this.textt, required this.suffixIcon, required this.onTapp, this.onTap});

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (onTapp.isEmpty) return;
    // Se cierra el menú antes de abrir la pantalla para que no quede abierto al volver
    Navigator.pop(context);
    Navigator.pushNamed(context, onTapp);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
              padding: EdgeInsets.only(
                bottom: twentyPixelHeight(context)*1
              ),
              child: InkWell(
                onTap: () => _handleTap(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(suffixIcon,color: AppColor.whiteColor,),
                    horizontalSpace(twentyPixelWidth(context)*.5),
                    Text(
                      textt,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          fontFamily: "Poppins"),
                    ),
                  ],
                ),
              ),
            );
  }
}
