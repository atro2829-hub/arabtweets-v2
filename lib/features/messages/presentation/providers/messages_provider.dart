import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

final _client = () => Supabase.instance.client;

final _currentUserIdProvider = Provider<String?>((ref) {
  return _client().auth.currentUser?.id;
});

/// Provider that fetches all conversations for the current user
final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationModel>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<ConversationModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<ConversationModel>> build() async {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return [];

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return _fetchConversations(userId);
  }

  Future<List<ConversationModel>> _fetchConversations(String userId) async {
    final response = await _client()
        .rpc('get_user_conversations', params: {'user_id': userId});

    final List<ConversationModel> conversations = [];
    for (final item in response as List) {
      conversations.add(ConversationModel.fromJson(item as Map<String, dynamic>));
    }
    return conversations;
  }

  Future<void> refresh() async {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return;
    state = const AsyncLoading();
    state = AsyncData(await _fetchConversations(userId));
  }

  /// Listen for new messages in real-time to update conversation list
  void listenForNewMessages() {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return;

    _channel?.unsubscribe();

    _channel = _client()
        .channel('user_conversations_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMessage = payload.new as Map<String, dynamic>?;
            if (newMessage == null) return;

            final senderId = newMessage['sender_id'] as String?;
            if (senderId == userId) return;

            final current = state.valueOrNull ?? [];
            final updated = List<ConversationModel>.from(current);

            for (int i = 0; i < updated.length; i++) {
              if (updated[i].id == newMessage['conversation_id']) {
                updated[i] = ConversationModel(
                  id: updated[i].id,
                  name: updated[i].name,
                  avatarUrl: updated[i].avatarUrl,
                  updatedAt: DateTime.now(),
                  lastMessage: newMessage['content'] as String? ?? '',
                  lastMessageTime: DateTime.now(),
                  otherUserId: updated[i].otherUserId,
                  otherUsername: updated[i].otherUsername,
                  otherAvatarUrl: updated[i].otherAvatarUrl,
                  otherDisplayName: updated[i].otherDisplayName,
                  otherIsVerified: updated[i].otherIsVerified,
                  unreadCount: updated[i].unreadCount + 1,
                );

                final item = updated.removeAt(i);
                updated.insert(0, item);
                state = AsyncData(updated);
                return;
              }
            }
          },
        )
        .subscribe();
  }

  /// Remove a conversation from the list optimistically
  void updateConversationLastMessage(String conversationId, String lastMessage) {
    final current = state.valueOrNull ?? [];
    final updated = List<ConversationModel>.from(current);

    for (int i = 0; i < updated.length; i++) {
      if (updated[i].id == conversationId) {
        updated[i] = ConversationModel(
          id: updated[i].id,
          name: updated[i].name,
          avatarUrl: updated[i].avatarUrl,
          updatedAt: DateTime.now(),
          lastMessage: lastMessage,
          lastMessageTime: DateTime.now(),
          otherUserId: updated[i].otherUserId,
          otherUsername: updated[i].otherUsername,
          otherAvatarUrl: updated[i].otherAvatarUrl,
          otherDisplayName: updated[i].otherDisplayName,
          otherIsVerified: updated[i].otherIsVerified,
          unreadCount: updated[i].unreadCount,
        );
        final item = updated.removeAt(i);
        updated.insert(0, item);
        state = AsyncData(updated);
        return;
      }
    }
  }
}

/// Provider for messages in a specific conversation, keyed by conversationId
final messagesProvider = AsyncNotifierProvider.family<
    MessagesNotifier, List<MessageModel>, String>(MessagesNotifier.new);

class MessagesNotifier
    extends FamilyAsyncNotifier<List<MessageModel>, String> {
  RealtimeChannel? _channel;
  bool _hasMore = true;

  @override
  Future<List<MessageModel>> build(String arg) async {
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return [];

    _hasMore = true;
    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    final messages = await _fetchMessages(arg, userId);
    _setupRealtime(arg, userId);
    return messages;
  }

  Future<List<MessageModel>> _fetchMessages(
      String conversationId, String userId,
      {int offset = 0}) async {
    final response = await _client().rpc('get_conversation_messages', params: {
      'conversation_id': conversationId,
      'user_id': userId,
      'limit': ApiConstants.messagesPageSize,
      'offset': offset,
    });

    final List<MessageModel> messages = [];
    for (final item in response as List) {
      messages.add(MessageModel.fromJson(item as Map<String, dynamic>));
    }

    if (messages.length < ApiConstants.messagesPageSize) {
      _hasMore = false;
    }

    return messages;
  }

  void _setupRealtime(String conversationId, String userId) {
    _channel?.unsubscribe();

    _channel = _client()
        .channel('conversation_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final newMessageData = payload.new as Map<String, dynamic>?;
            if (newMessageData == null) return;

            final senderId = newMessageData['sender_id'] as String?;
            final newMessage = MessageModel(
              id: newMessageData['id'] as String,
              conversationId: newMessageData['conversation_id'] as String,
              senderId: senderId ?? '',
              content: newMessageData['content'] as String? ?? '',
              mediaUrl: newMessageData['media_url'] as String?,
              mediaType: newMessageData['media_type'] as String? ?? 'none',
              replyToId: newMessageData['reply_to_id'] as String?,
              isRead: false,
              createdAt: newMessageData['created_at'] != null
                  ? DateTime.parse(newMessageData['created_at'] as String)
                  : DateTime.now(),
              senderUsername: null,
              senderAvatarUrl: null,
            );

            final current = state.valueOrNull ?? [];

            final alreadyExists = current.any((m) => m.id == newMessage.id);
            if (!alreadyExists) {
              final updated = [...current, newMessage];
              state = AsyncData(updated);

              // Update conversation list
              final conversationsNotifier =
                  ref.read(conversationsProvider.notifier);
              conversationsNotifier.updateConversationLastMessage(
                conversationId,
                newMessage.content.isNotEmpty
                    ? newMessage.content
                    : '📎 média',
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final current = state.valueOrNull ?? [];
    final userId = _currentUserIdProvider.read(ref);
    if (userId == null) return;

    final olderMessages =
        await _fetchMessages(arg, userId, offset: current.length);
    if (olderMessages.isEmpty) {
      _hasMore = false;
      return;
    }

    final merged = [...olderMessages, ...current];
    state = AsyncData(merged);
  }

  /// Send a text message
  Future<MessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String? mediaUrl,
    String mediaType = 'none',
    String? replyToId,
  }) async {
    final result = await _client().rpc('send_message', params: {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reply_to_id': replyToId,
    });

    final messageId = result as String?;

    if (messageId != null) {
      final newMessage = MessageModel(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        replyToId: replyToId,
        isRead: true,
        createdAt: DateTime.now(),
        senderUsername: _client().auth.currentUser?.userMetadata?['username'],
        senderAvatarUrl: _client().auth.currentUser?.userMetadata?['avatar_url'],
      );

      final current = state.valueOrNull ?? [];
      final alreadyExists = current.any((m) => m.id == messageId);
      if (!alreadyExists) {
        state = AsyncData([...current, newMessage]);
      }

      return newMessage;
    }
    return null;
  }

  /// Upload media and send message
  Future<MessageModel?> sendMediaMessage({
    required String conversationId,
    required String senderId,
    required File file,
    String mediaType = 'image',
    String? replyToId,
  }) async {
    final ext = mediaType == 'video'
        ? 'mp4'
        : mediaType == 'audio'
            ? 'mp3'
            : 'jpg';

    final userId = _currentUserIdProvider.read(ref) ?? senderId;
    final storagePath =
        'messages/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client().storage.from('media').upload(storagePath, file);

    final publicUrl =
        _client().storage.from('media').getPublicUrl(storagePath);

    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: '',
      mediaUrl: publicUrl,
      mediaType: mediaType,
      replyToId: replyToId,
    );
  }
}

/// Provider to get or create a conversation with another user
final createConversationProvider = FutureProvider.autoDispose
    .family<String, String>((ref, otherUserId) async {
  final userId = _currentUserIdProvider.read(ref);
  if (userId == null) throw Exception('Not authenticated');

  final conversationId = await _client()
      .rpc('get_or_create_conversation', params: {
    'user1': userId,
    'user2': otherUserId,
  });

  return conversationId as String;
});

/// Provider for total unread message count across all conversations
final unreadMessagesProvider =
    StreamProvider.autoDispose<int>((ref) {
  final userId = _currentUserIdProvider.read(ref);
  if (userId == null) return Stream.value(0);

  final controller = StreamController<int>.broadcast();

  void fetchCount() {
    _client().rpc('get_user_conversations', params: {'user_id': userId}).then((response) {
      int total = 0;
      for (final item in response as List) {
        final count = (item as Map<String, dynamic>)['unread_count'] as int? ?? 0;
        total += count;
      }
      controller.add(total);
    }).catchError((_) {
      controller.add(0);
    });
  }

  fetchCount();

  // Refresh every 15 seconds
  final timer = Timer.periodic(const Duration(seconds: 15), (_) {
    fetchCount();
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});