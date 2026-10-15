import 'package:flutter/material.dart';

class MainButton extends StatelessWidget {
  const MainButton({super.key, required this.label, required this.action, required this.isLoading});

  final String label;
  final void Function() action;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return  ElevatedButton(
      onPressed: action,
      child: isLoading ? CircularProgressIndicator() : Text(label, style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),),
      style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(60),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          )
      ),
    );
  }
}
