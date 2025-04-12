import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/constants/app_fonts_family.dart';
import 'package:task/utils/constants/app_sizes.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key, 
    required this.label, 
    required this.hint, 
    required this.controller, 
    required this.validator, 
    required this.inputType, 
    required this.isHidden, 
    this.onChanged, 
    this.hintColor
  });

  final String label, hint;
  final Color? hintColor;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType inputType;
  final bool isHidden;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontNormal,
              fontFamily: AppFontsStyles.openSans,
              fontWeight: FontWeight.normal,
              color: hintColor
            )
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TextFormField(
            obscureText: isHidden,

            onChanged: onChanged,

            controller: controller,

            validator: validator,

            keyboardType: inputType,
            
            style: const TextStyle(
              fontSize: AppSizes.fontNormal,
              fontWeight: FontWeight.w500,
              fontFamily: AppFontsStyles.openSans
            ),

            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: AppSizes.fontNormal,
                fontFamily: AppFontsStyles.openSans,
                fontWeight: FontWeight.w400,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: const BorderSide(
                  width: 1.0,
                  color: AppColors.tertiaryColor
                )
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: const BorderSide(
                  width: 1.0,
                  color: AppColors.black
                )
              )
            ),
          ),
        )
      ],
    );
  }
}