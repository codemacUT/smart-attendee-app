import 'package:flutter/material.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonType type;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.getIconSize(context, 20);
    final fontSize = Responsive.getFontSize(context, 16);
    final spacing = Responsive.getSpacing(context);
    
    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: Colors.white),
            SizedBox(width: spacing),
          ],
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ],
    );

    switch (type) {
      case ButtonType.primary:
        return SizedBox(
          width: width,
          height: height ?? Responsive.getButtonHeight(context),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.getSpacing(context)),
              ),
            ),
            child: buttonChild,
          ),
        );
      case ButtonType.secondary:
        return SizedBox(
          width: width,
          height: height ?? Responsive.getButtonHeight(context),
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlack,
              side: const BorderSide(color: AppTheme.primaryBlack, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.getSpacing(context)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: iconSize, color: AppTheme.primaryBlack),
                    SizedBox(width: spacing),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case ButtonType.text:
        return SizedBox(
          width: width,
          height: height ?? Responsive.getButtonHeight(context),
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.getSpacing(context)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlack),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: iconSize, color: AppTheme.primaryBlack),
                    SizedBox(width: spacing),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: AppTheme.primaryBlack,
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case ButtonType.gradient:
        return Container(
          width: width,
          height: height ?? Responsive.getButtonHeight(context),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlack, AppTheme.secondaryBlack],
            ),
            borderRadius: BorderRadius.circular(Responsive.getSpacing(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(Responsive.getSpacing(context)),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else ...[
                      if (icon != null) ...[
                        Icon(icon, size: iconSize, color: Colors.white),
                        SizedBox(width: spacing),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
  gradient,
}

class FloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: foregroundColor ?? Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
