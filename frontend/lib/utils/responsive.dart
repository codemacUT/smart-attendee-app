import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 && 
           MediaQuery.of(context).size.width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }

  static bool isLargeMobile(BuildContext context) {
    return MediaQuery.of(context).size.width >= 400 && 
           MediaQuery.of(context).size.width < 768;
  }

  // Responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(8);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  // Responsive margin
  static EdgeInsets getMargin(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(4);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(6);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(8);
    } else {
      return const EdgeInsets.all(12);
    }
  }

  // Responsive spacing
  static double getSpacing(BuildContext context) {
    if (isSmallMobile(context)) {
      return 4;
    } else if (isMobile(context)) {
      return 8;
    } else if (isTablet(context)) {
      return 12;
    } else {
      return 16;
    }
  }

  // Responsive font size
  static double getFontSize(BuildContext context, double baseSize) {
    if (isSmallMobile(context)) {
      return baseSize * 0.85;
    } else if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    if (isSmallMobile(context)) {
      return baseSize * 0.8;
    } else if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  // Responsive button height
  static double getButtonHeight(BuildContext context) {
    if (isSmallMobile(context)) {
      return 48;
    } else if (isMobile(context)) {
      return 52;
    } else if (isTablet(context)) {
      return 56;
    } else {
      return 60;
    }
  }

  // Responsive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(8);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  // Responsive grid columns
  static int getGridColumns(BuildContext context) {
    if (isSmallMobile(context)) {
      return 1;
    } else if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  // Responsive width percentage
  static double getWidthPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  // Responsive height percentage
  static double getHeightPercentage(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  // Safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Available height (excluding safe areas)
  static double getAvailableHeight(BuildContext context) {
    return MediaQuery.of(context).size.height - 
           MediaQuery.of(context).padding.top - 
           MediaQuery.of(context).padding.bottom;
  }

  // Available width (excluding safe areas)
  static double getAvailableWidth(BuildContext context) {
    return MediaQuery.of(context).size.width - 
           MediaQuery.of(context).padding.left - 
           MediaQuery.of(context).padding.right;
  }
}
