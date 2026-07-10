import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:adentweet/features/messages/data/models/message_model.dart';
import 'package:adentweet/features/messages/presentation/providers/messages_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUsername;
  final String otherDisplayName;
  final String otherAvatarUrl;
  final bool otherIsVerified;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherUserId = '',
    this.otherUsername = '',
    this.otherDisplayName = '',
    this.otherAvatarUrl = '',
    this.otherIsVerified = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  MessageModel? _replyingTo;
  bool _isSending = false;
  bool _isAtBottom = true;
  bool _showScrollDown = false;
  final Map<String, VideoPlayerController> _videoControllers = {};

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final threshold = 50.0;

      final atBottom = currentScroll >= maxScroll - threshold;
      if (atBottom != _isAtBottom) {
        setState(() {
          _isAtBottom = atBottom;
          _showScrollDown = !atBottom;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _replyingTo == null) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    final replyToId = _replyingTo?.id;

    try {
      await ref.read(messagesProvider(widget.conversationId).notifier).sendMessage(
            conversationId: widget.conversationId,
            senderId: _currentUserId,
            content: content,
            replyToId: replyToId,
          );

      _messageController.clear();
      setState(() {
        _replyingTo = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إرسال الرسالة')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendMedia(ImageSource source, String mediaType) async {
    try {
      final XFile? file = mediaType == 'video'
          ? await _imagePicker.pickVideo(source: source)
          : await _imagePicker.pickImage(
              source: source,
              imageQuality: 80,
            );

      if (file == null) return;

      setState(() {
        _isSending = true;
      });

      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendMediaMessage(
            conversationId: widget.conversationId,
            senderId: _currentUserId,
            file: File(file.path),
            mediaType: mediaType,
            replyToId: _replyingTo?.id,
          );

      setState(() {
        _replyingTo = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الوسائط: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('معرض الصور'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(ImageSource.gallery, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(ImageSource.camera, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('فيديو'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendMedia(ImageSource.gallery, 'video');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setReply(MessageModel message) {
    setState(() {
      _replyingTo = message;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: GestureDetector(
          onTap: () {
            context.push('/profile/${widget.otherUserId}');
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: widget.otherAvatarUrl.isNotEmpty
                    ? NetworkImage(widget.otherAvatarUrl)
                    : null,
                child: widget.otherAvatarUrl.isEmpty
                    ? Text(
                        widget.otherDisplayName.isNotEmpty
                            ? widget.otherDisplayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.otherDisplayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.otherIsVerified)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '@${widget.otherUsername}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    Text(
                      'حدث خطأ أثناء تحميل الرسائل',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                          messagesProvider(widget.conversationId)),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState(theme, colorScheme);
                }

                final reversedMessages = messages.reversed.toList();

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: reversedMessages.length,
                      itemBuilder: (context, index) {
                        final message = reversedMessages[index];
                        final isMine = message.senderId == _currentUserId;

                        if (index == reversedMessages.length - 3) {
                          ref
                              .read(
                                  messagesProvider(widget.conversationId).notifier)
                              .loadMore();
                        }

                        return _MessageBubble(
                          message: message,
                          isMine: isMine,
                          formatTime: _formatMessageTime,
                          onReply: () => _setReply(message),
                          videoController: _getVideoController(message),
                          colorScheme: colorScheme,
                          theme: theme,
                        );
                      },
                    ),
                    if (_showScrollDown)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: FloatingActionButton.small(
                          onPressed: _scrollToBottom,
                          child: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          if (_replyingTo != null) _buildReplyPreview(theme, colorScheme),

          _buildInputBar(theme, colorScheme),
        ],
      ),
    );
  }

  VideoPlayerController? _getVideoController(MessageModel message) {
    if (message.isVideo && message.mediaUrl != null) {
      _videoControllers.putIfAbsent(
        message.id,
        () => VideoPlayerController.networkUrl(Uri.parse(message.mediaUrl!))
          ..initialize(),
      );
      return _videoControllers[message.id];
    }
    return null;
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: widget.otherAvatarUrl.isNotEmpty
                  ? NetworkImage(widget.otherAvatarUrl)
                  : null,
              child: widget.otherAvatarUrl.isEmpty
                  ? Text(
                      widget.otherDisplayName.isNotEmpty
                          ? widget.otherDisplayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.otherDisplayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.otherIsVerified)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'حساب موثّق',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'ابدأ محادثة مع @${widget.otherUsername}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرد على',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                Text(
                  _replyingTo!.content.isNotEmpty
                      ? _replyingTo!.content
                      : '📎 وسائط',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _isSending ? null : () => _showMediaOptions(context),
            icon: const Icon(Icons.image_outlined),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'رسالة جديدة',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _messageController.text.trim().isNotEmpty
                  ? colorScheme.primary
                  : theme.dividerColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _messageController.text.trim().isNotEmpty && !_isSending
                  ? _sendMessage
                  : null,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final String Function(DateTime) formatTime;
  final VoidCallback onReply;
  final VideoPlayerController? videoController;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.formatTime,
    required this.onReply,
    this.videoController,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = message.content.isNotEmpty;
    final hasMedia = message.hasMedia;

    if (hasMedia) {
      return _buildMediaMessage(context);
    }

    return _buildTextMessage(context);
  }

  Widget _buildTextMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: onReply,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMine ? colorScheme.primary : colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMine
                        ? const Radius.circular(20)
                        : const Radius.circular(4),
                    bottomRight: isMine
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMine
                            ? colorScheme.onPrimary
                            : colorScheme.onSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatTime(message.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: (isMine
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSecondary)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all
                                : Icons.check,
                            size: 14,
                            color: colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: onReply,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMine ? colorScheme.primary : colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isMine
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isMine
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.replyToId != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isMine
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSecondary)
                              .withValues(alpha: 0.1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 14,
                              color: (isMine
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSecondary)
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'الرد على رسالة سابقة',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: (isMine
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSecondary)
                                      .withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildMediaContent(),
                    if (message.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                        child: Text(
                          message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMine
                                ? colorScheme.onPrimary
                                : colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatTime(message.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: (isMine
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSecondary)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead
                                  ? Icons.done_all
                                  : Icons.check,
                              size: 14,
                              color: colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (message.isImage && message.mediaUrl != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 260,
          maxHeight: 300,
        ),
        child: Image.network(
          message.mediaUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final total = loadingProgress.expectedTotalBytes ?? 1;
            final progress = loadingProgress.cumulativeBytesLoaded / total;
            return Container(
              width: 260,
              height: 200,
              color: (isMine
                      ? colorScheme.onPrimary
                      : colorScheme.onSecondary)
                  .withValues(alpha: 0.1),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress,
                  color: isMine ? colorScheme.onPrimary : colorScheme.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 260,
              height: 200,
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  size: 40,
                  color: colorScheme.outline,
                ),
              ),
            );
          },
        ),
      );
    }

    if (message.isVideo && message.mediaUrl != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 260,
          maxHeight: 300,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 200,
              color: Colors.black,
            ),
            if (videoController != null && videoController!.value.isInitialized)
              VideoPlayer(videoController!),
            const Icon(
              Icons.play_circle_fill,
              size: 56,
              color: Colors.white70,
            ),
          ],
        ),
      );
    }

    if (message.isAudio && message.mediaUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack,
              size: 32,
              color: isMine ? colorScheme.onPrimary : colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'ملف صوتي',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMine
                    ? colorScheme.onPrimary
                    : colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}