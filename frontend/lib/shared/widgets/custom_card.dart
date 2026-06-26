import 'package:flutter/material.dart';
import 'package:smart_attendee/utils/theme.dart';
import 'package:smart_attendee/utils/responsive.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? elevation;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? Responsive.getCardPadding(context);
    final responsiveMargin = margin ?? Responsive.getMargin(context);
    final responsiveBorderRadius = borderRadius ?? BorderRadius.circular(Responsive.getSpacing(context) * 2);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: responsiveMargin,
      child: Material(
        color: backgroundColor ?? Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        elevation: elevation ?? 8,
        shadowColor: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.1),
        borderRadius: responsiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: responsiveBorderRadius,
          child: Container(
            padding: responsivePadding,
            decoration: BoxDecoration(
              borderRadius: responsiveBorderRadius,
              gradient: isDarkMode ? null : AppTheme.cardGradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.getIconSize(context, 24);
    final arrowSize = Responsive.getIconSize(context, 16);
    final spacing = Responsive.getSpacing(context);
    
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: iconColor ?? AppTheme.primaryBlack,
                size: iconSize,
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.darkGray,
                  size: arrowSize,
                ),
            ],
          ),
          SizedBox(height: spacing),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: Responsive.getFontSize(context, 24),
            ),
          ),
          SizedBox(height: spacing / 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkGray,
              fontSize: Responsive.getFontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }
}
