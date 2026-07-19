import 'package:flutter/material.dart';
import 'package:smart_attendee/shared/widgets/custom_button.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';

Future<bool?> showLogoutDialog(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: Responsive.getPadding(context).left),
        backgroundColor: isDark ? Theme.of(context).cardTheme.color : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.getSpacing(context) * 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.getSpacing(context) * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: Responsive.getSpacing(context) * 1.5),
              Text(
                'Log Out?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.getSpacing(context)),
              Text(
                'Are you sure you want to log out of your account?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7) : AppTheme.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Responsive.getSpacing(context) * 2),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      type: ButtonType.secondary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: Responsive.getSpacing(context)),
                  Expanded(
                    child: CustomButton(
                      text: 'Yes',
                      type: ButtonType.gradient,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
