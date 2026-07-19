import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_attendee/utils/theme.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Row(
              children: [
                const ShimmerLoader(height: 56, width: 56, borderRadius: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoader(height: 16, width: 120, borderRadius: 8),
                      SizedBox(height: 8),
                      ShimmerLoader(height: 24, width: 200, borderRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const ShimmerLoader(height: 46, width: 46, borderRadius: 12),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Action Card Skeleton
                const ShimmerLoader(height: 140, width: double.infinity, borderRadius: 24),
                const SizedBox(height: 32),
                
                // List Title Skeleton
                const ShimmerLoader(height: 24, width: 150, borderRadius: 12),
                const SizedBox(height: 16),
                
                // List Items Skeleton
                const ShimmerLoader(height: 80, width: double.infinity, borderRadius: 16, margin: EdgeInsets.only(bottom: 12)),
                const ShimmerLoader(height: 80, width: double.infinity, borderRadius: 16, margin: EdgeInsets.only(bottom: 12)),
                const ShimmerLoader(height: 80, width: double.infinity, borderRadius: 16, margin: EdgeInsets.only(bottom: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
