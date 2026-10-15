import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/responsive.dart';

/// Estados de una lista de solicitudes cuando no hay tarjetas que mostrar:
/// cargando, vacía o con error (con opción de reintentar).
class RequestListStatus extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final String emptyMessage;

  const RequestListStatus({
    super.key,
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
    this.emptyMessage = 'There are no blood requests yet.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: twentyPixelHeight(context) * 2),
      child: Center(child: _content()),
    );
  }

  Widget _content() {
    if (isLoading) {
      return const CircularProgressIndicator(color: AppColor.redColor);
    }

    final message = errorMessage ?? emptyMessage;
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColor.textAss,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
        if (errorMessage != null)
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColor.redColor, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
