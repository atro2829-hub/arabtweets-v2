import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoading extends StatelessWidget {
  const SkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2F3336) : Colors.grey.shade200;
    final highlightColor =
        isDark ? const Color(0xFF3E4245) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const TweetCardSkeleton(),
      ),
    );
  }
}

class TweetCardSkeleton extends StatelessWidget {
  const TweetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12, right: 12, top: 16),
            child: _SkeletonCircle(size: 44),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SkeletonRect(width: 120, height: 18),
                      SizedBox(width: 8),
                      _SkeletonCircle(size: 14),
                      SizedBox(width: 8),
                      _SkeletonRect(width: 60, height: 14),
                    ],
                  ),
                  SizedBox(height: 8),
                  _SkeletonRect(width: double.infinity, height: 16),
                  SizedBox(height: 6),
                  _SkeletonRect(width: 280, height: 16),
                  SizedBox(height: 6),
                  _SkeletonRect(width: 180, height: 16),
                  SizedBox(height: 16),
                  _SkeletonRect(width: double.infinity, height: 200),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SkeletonRect(width: 60, height: 16),
                      _SkeletonRect(width: 60, height: 16),
                      _SkeletonRect(width: 60, height: 16),
                      _SkeletonRect(width: 60, height: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SkeletonRect(width: double.infinity, height: 160),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: Offset(0, -36),
                child: _SkeletonCircle(size: 80),
              ),
              SizedBox(height: 8),
              _SkeletonRect(width: 180, height: 22),
              SizedBox(height: 4),
              _SkeletonRect(width: 120, height: 16),
              SizedBox(height: 12),
              _SkeletonRect(width: double.infinity, height: 16),
              SizedBox(height: 6),
              _SkeletonRect(width: 240, height: 16),
              SizedBox(height: 16),
              Row(
                children: [
                  _SkeletonRect(width: 80, height: 14),
                  SizedBox(width: 16),
                  _SkeletonRect(width: 80, height: 14),
                  SizedBox(width: 16),
                  _SkeletonRect(width: 80, height: 14),
                ],
              ),
              SizedBox(height: 16),
              _SkeletonRect(width: double.infinity, height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _SkeletonCircle(size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonRect(width: double.infinity, height: 16),
                SizedBox(height: 6),
                _SkeletonRect(width: 200, height: 14),
              ],
            ),
          ),
          _SkeletonCircle(size: 36),
        ],
      ),
    );
  }
}

class MessageSkeleton extends StatelessWidget {
  const MessageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _SkeletonCircle(size: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonRect(width: 120, height: 16),
                SizedBox(height: 4),
                _SkeletonRect(width: 200, height: 14),
              ],
            ),
          ),
          SizedBox(width: 8),
          _SkeletonRect(width: 40, height: 14),
        ],
      ),
    );
  }
}

class _SkeletonRect extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonRect({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}