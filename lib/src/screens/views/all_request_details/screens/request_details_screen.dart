
import 'package:flutter/material.dart';
import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/date_format.dart';
import '../../../../general/utils/phone_actions.dart';
import '../../../../general/utils/responsive.dart';
import '../../../../models/blood_request.dart';
import '../../../../services/api/api_exception.dart';
import '../../../../services/app_services.dart';
import '../../components/widgets/custom_appbar.dart';
import '../../components/widgets/request_list_status.dart';
import '../widgets/custom_call_btn.dart';
import '../widgets/request_details_item.dart';

/// Recibe el id de la solicitud como argumento de la ruta (enviado por el botón "Details").
class RequestDetailsScreen extends StatefulWidget {
  static const pageRoute = "/request-details-screen";
  const RequestDetailsScreen({super.key});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final _bloodRequestService = AppServices.instance.bloodRequests;

  int? _requestId;
  BloodRequest? _request;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestId != null) return;

    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is int) {
      _requestId = argument;
      _load();
    } else {
      _isLoading = false;
      _errorMessage = 'No request was selected.';
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final request = await _bloodRequestService.getById(_requestId!);
      if (mounted) setState(() => _request = request);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _contact(PhoneAction action, String phoneNumber) async {
    final opened = await openPhoneAction(action, phoneNumber);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone app on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: const CustomAppBar(
        titlee: "Details",
        actionTrue: true,
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: twentyPixelWidth(context),
            right: twentyPixelWidth(context),
          ),
          child: request == null
              ? RequestListStatus(
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onRetry: _load,
                )
              : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(twentyPixelHeight(context) * 1.5),
              RequestDetailsItem(
                titlee: "Blood want before",
                textt: toLongDate(request.needBefore),
              ),
              RequestDetailsItem(
                titlee: "Patient Name",
                textt: request.patientName,
              ),

              // El formulario de solicitud no pide ubicación: se muestra un guion si no existe
              RequestDetailsItem(
                titlee: "Location ",
                textt: request.location ?? '—',
              ),

              RequestDetailsItem(
                titlee: "Blood Group",
                textt: request.bloodGroup,
              ),

              RequestDetailsItem(
                titlee: "Contact Number",
                textt: request.contactNumber,
              ),

              RequestDetailsItem(
                titlee: "Cause",
                textt: request.caseDescription,
              ),

              RequestDetailsItem(
                titlee: "Number of Bags",
                textt: "${request.bags} Bags",
              ),

              RequestDetailsItem(
                titlee: "Others",
                textt: request.others ?? '—',
              ),

              verticalSpace(twentyPixelHeight(context)),
             CustomCallButton(
              textt: "Call",
              textColor: AppColor.whiteColor,
              fillColor: AppColor.redColor,
              borderClr: Colors.transparent,
              onTap: () => _contact(PhoneAction.call, request.contactNumber),
             ),
             verticalSpace(twentyPixelHeight(context)*.5),
             CustomCallButton(
              textt: "Message",
              textColor: AppColor.redColor,
              fillColor: AppColor.whiteColor,
              onTap: () => _contact(PhoneAction.message, request.contactNumber),
             )
            ],
          ),
        ),
      ),
    );
  }
}
