import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  final String mediaType;
  final bool isGif;
  final int maxImages;

  const MediaGrid({
    super.key,
    required this.mediaUrls,
    required this.mediaType,
    this.isGif = false,
    this.maxImages = 4,
  });

  @override
  Widget build(BuildContext context) {
    final urls = mediaUrls.take(maxImages).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    if (mediaType == 'video') {
      return _buildVideoThumbnail(context, urls.first);
    }

    if (isGif) {
      return _buildGifImage(context, urls.first);
    }

    switch (urls.length) {
      case 1:
        return _buildSingleImage(context, urls[0]);
      case 2:
        return _buildTwoImages(context, urls);
      case 3:
        return _buildThreeImages(context, urls);
      default:
        return _buildFourImages(context, urls);
    }
  }

  Widget _buildSingleImage(BuildContext context, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () => _openGallery(context, mediaUrls),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          placeholder: (context, _) => Container(
            width: double.infinity,
            height: 260,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, _, __) => Container(
            width: double.infinity,
            height: 260,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(BuildContext context, List<String> urls) {
    return Row(
      children: [
        Expanded(
          child: _buildGridImage(context, urls[0], 0, urls),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildGridImage(context, urls[1], 1, urls),
        ),
      ],
    );
  }

  Widget _buildThreeImages(BuildContext context, List<String> urls) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: _buildGridImage(context, urls[0], 0, urls),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildGridImage(context, urls[1], 1, urls),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildGridImage(context, urls[2], 2, urls),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourImages(BuildContext context, List<String> urls) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildGridImage(context, urls[0], 0, urls),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildGridImage(context, urls[1], 1, urls),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildGridImage(context, urls[2], 2, urls),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildGridImage(context, urls[3], 3, urls),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridImage(
    BuildContext context,
    String url,
    int index,
    List<String> allUrls,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () => _openGallery(context, allUrls, initialIndex: index),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, _, __) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context, String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
            placeholder: (context, _) => Container(
              width: double.infinity,
              height: 260,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, _, __) => Container(
              width: double.infinity,
              height: 260,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              'assets/icons/svg/play.svg',
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifImage(BuildContext context, String url) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, _) => Container(
              width: double.infinity,
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (context, _, __) => Container(
              width: double.infinity,
              height: 200,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'GIF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openGallery(
    BuildContext context,
    List<String> urls, {
    int initialIndex = 0,
  }) {
    final fullUrls = urls
        .where((url) => url.isNotEmpty)
        .toList();

    if (fullUrls.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return PhotoViewGallery(
            pageOptions: fullUrls.map((url) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              );
            }).toList(),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: PageController(initialPage: initialIndex),
            loadingBuilder: (context, event) {
              return Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ?? 1),
                  color: Colors.white,
                ),
              );
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}