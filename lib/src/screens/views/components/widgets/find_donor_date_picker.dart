
import 'package:flutter/material.dart';

import '../../../../general/config/colors.dart';
import '../../../../general/utils/blank_space.dart';
import '../../../../general/utils/date_format.dart';
import '../../../../general/utils/responsive.dart';


class FindDonorDatePicker extends StatefulWidget {
  final ValueChanged<DateTime>? onChanged;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const FindDonorDatePicker({
    super.key,
    this.onChanged,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<FindDonorDatePicker> createState() => _FindDonorDatePickerState();
}

class _FindDonorDatePickerState extends State<FindDonorDatePicker> {
  String? date;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) date = toPickerDate(_selectedDate!);
  }

  Future<void> _pickDate(BuildContext context) async {
    final firstDate = widget.firstDate ?? DateTime(2000);
    final lastDate = widget.lastDate ?? DateTime(2050);
    final now = DateTime.now();
    final suggested = _selectedDate ?? (now.isAfter(lastDate) ? lastDate : now);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: suggested.isBefore(firstDate) ? firstDate : suggested,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    // Si el usuario cancela, showDatePicker devuelve null y se conserva la fecha anterior
    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
      date = toPickerDate(pickedDate);
    });
    widget.onChanged?.call(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            height: twentyPixelHeight(context) * 2,
            decoration: BoxDecoration(
                color: AppColor.textLight,
                borderRadius: BorderRadius.circular(5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                horizontalSpace(twentyPixelWidth(context) * .5),
                Text(
                  date ?? "Choose Date",
                  style: const TextStyle(
                    color: AppColor.textAss,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                  textScaler: TextScaler.linear(ScaleSize.textScaleFactor(context)),
                ),
              ],
            ),
          ),
        ),
        horizontalSpace(twentyPixelWidth(context)),
        InkWell(
          onTap: () {
            _pickDate(context);
          },
          child: Container(
            height: twentyPixelHeight(context) * 2,
            width: twentyPixelWidth(context) * 3,
            decoration: BoxDecoration(
                color: AppColor.redColor,
                borderRadius: BorderRadius.circular(5)),
            child: const Icon(
              Icons.calendar_month,
              color: AppColor.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
