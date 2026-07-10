import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../data/models/tweet_model.dart';
import '../providers/tweets_provider.dart';
import 'media_grid.dart';

class ComposeTweetSheet extends ConsumerStatefulWidget {
  final String? replyToId;
  final String? replyToUserId;
  final String? replyToUsername;
  final TweetModel? quoteTweet;
  final String? tweetId;
  final VoidCallback? onTweetPosted;

  const ComposeTweetSheet({
    super.key,
    this.replyToId,
    this.replyToUserId,
    this.replyToUsername,
    this.quoteTweet,
    this.tweetId,
    this.onTweetPosted,
  });

  static Future<TweetModel?> show(
    BuildContext context, {
    String? replyToId,
    String? replyToUserId,
    String? replyToUsername,
    TweetModel? quoteTweet,
    String? tweetId,
  }) {
    return showModalBottomSheet<TweetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComposeTweetSheet(
        replyToId: replyToId,
        replyToUserId: replyToUserId,
        replyToUsername: replyToUsername,
        quoteTweet: quoteTweet,
        tweetId: tweetId,
      ),
    );
  }

  @override
  ConsumerState<ComposeTweetSheet> createState() => _ComposeTweetSheetState();
}

class _ComposeTweetSheetState extends ConsumerState<ComposeTweetSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _mediaFiles = [];

  bool _isLoading = false;
  String _mediaType = 'none';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _charCount => _textController.text.length;
  bool get _canSend => _textController.text.trim().isNotEmpty && !_isLoading;
  bool get _isReply => widget.replyToId != null;

  double get _charProgress => _charCount / ApiConstants.maxTweetLength;

  Color _getCharCounterColor(BuildContext context) {
    if (_charProgress > 1.0) {
      return Colors.red;
    } else if (_charProgress > 0.9) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.outline;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_mediaFiles.length >= ApiConstants.maxMediaCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'يمكنك إضافة ${ApiConstants.maxMediaCount} صور كحد أقصى'),
        ),
      );
      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remaining = ApiConstants.maxMediaCount - _mediaFiles.length;
        final toAdd = images.take(remaining).toList();

        setState(() {
          _mediaFiles.addAll(toAdd);
          _mediaType = 'image';
        });
      }
    } catch (e) {
      // Handle permission denied or other errors
    }
  }

  Future<void> _pickCamera() async {
    if (_mediaFiles.length >= ApiConstants.maxMediaCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'يمكنك إضافة ${ApiConstants.maxMediaCount} صور كحد أقصى'),
        ),
      );
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _mediaFiles.add(image);
          _mediaType = 'image';
        });
      }
    } catch (e) {
      // Handle permission denied
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
      if (_mediaFiles.isEmpty) {
        _mediaType = 'none';
      }
    });
  }

  Future<void> _sendTweet() async {
    if (!_canSend) return;

    final content = _textController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    final notifier = ref.read(createTweetProvider.notifier);
    final tweet = await notifier.createTweet(
      content: content,
      mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
      mediaType: _mediaType,
      quoteTweetId: widget.quoteTweet?.id,
      replyToId: widget.replyToId,
      replyToUserId: widget.replyToUserId,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (tweet != null) {
        Navigator.of(context).pop(tweet);
      } else {
        final error = ref.read(createTweetProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'حدث خطأ أثناء نشر التغريدة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickCamera();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final avatarUrl = currentUser?.userMetadata?['avatar_url'] as String?;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/svg/close.svg',
                        width: 18,
                        height: 18,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Character counter
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: _charProgress.clamp(0.0, 1.0),
                          strokeWidth: 2,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: _getCharCounterColor(context),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$_charCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getCharCounterColor(context),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reply indicator
          if (_isReply)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'الرد على ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  Text(
                    '@${widget.replyToUsername ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(ApiConstants.getAvatarUrl(avatarUrl))
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                color: colorScheme.outline,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLength: ApiConstants.maxTweetLength,
                          maxLines: null,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'ما الذي يحدث؟',
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.only(top: 8),
                          ),
                          onChanged: (value) {
                            setState(() => _draftContent = value);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Media preview grid
                  if (_mediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _MediaPreviewGrid(
                      mediaFiles: _mediaFiles,
                      onRemove: _removeMedia,
                    ),
                  ],

                  // Quote tweet preview
                  if (widget.quoteTweet != null) ...[
                    const SizedBox(height: 8),
                    _QuoteTweetPreview(tweet: widget.quoteTweet!),
                  ],
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                // Media picker
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/icons/svg/gallery.svg',
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // GIF button
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/icons/svg/gifs.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
                const Spacer(),
                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _canSend
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _isLoading ? null : _sendTweet,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : SvgPicture.asset(
                                'assets/icons/svg/plus.svg',
                                width: 18,
                                height: 18,
                                colorFilter: ColorFilter.mode(
                                  _canSend
                                      ? colorScheme.onPrimary
                                      : colorScheme.outline,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Media Preview Grid ──────────────────────────────────────────────────────

class _MediaPreviewGrid extends StatelessWidget {
  final List<XFile> mediaFiles;
  final void Function(int index) onRemove;

  const _MediaPreviewGrid({
    required this.mediaFiles,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaFiles.length == 1) {
      return _buildSinglePreview(context, 0);
    } else if (mediaFiles.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildSinglePreview(context, 0)),
          const SizedBox(width: 4),
          Expanded(child: _buildSinglePreview(context, 1)),
        ],
      );
    } else if (mediaFiles.length == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildSinglePreview(context, 0),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildSinglePreview(context, 1)),
                const SizedBox(height: 4),
                Expanded(child: _buildSinglePreview(context, 2)),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSinglePreview(context, 0)),
              const SizedBox(width: 4),
              Expanded(child: _buildSinglePreview(context, 1)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildSinglePreview(context, 2)),
              const SizedBox(width: 4),
              Expanded(child: _buildSinglePreview(context, 3)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSinglePreview(BuildContext context, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(mediaFiles[index].path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: SvgPicture.asset(
                'assets/icons/svg/close.svg',
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quote Tweet Preview ─────────────────────────────────────────────────────

class _QuoteTweetPreview extends StatelessWidget {
  final TweetModel tweet;

  const _QuoteTweetPreview({required this.tweet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: tweet.authorFullAvatarUrl.isNotEmpty
                    ? NetworkImage(tweet.authorFullAvatarUrl)
                    : null,
                child: tweet.authorFullAvatarUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        color: colorScheme.outline,
                        size: 12,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tweet.authorDisplayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tweet.authorIsVerified) ...[
                const SizedBox(width: 4),
                SvgPicture.asset(
                  'assets/icons/svg/verified.svg',
                  width: 14,
                  height: 14,
                ),
              ],
              const SizedBox(width: 4),
              Text(
                '@${tweet.authorUsername}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Content
          Text(
            tweet.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
          ),
          // Media
          if (tweet.hasMedia && tweet.fullMediaUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaGrid(
                  mediaUrls: tweet.fullMediaUrls,
                  mediaType: tweet.mediaType,
                  isGif: tweet.isGif,
                ),
              ),
            ),
        ],
      ),
    );
  }
}