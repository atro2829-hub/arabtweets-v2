import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:adentweet/features/tweets/presentation/widgets/compose_tweet_sheet.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  final String? replyToId;
  final String? replyToUserId;
  final String? replyToUsername;
  final String? quoteTweetId;

  const ComposeScreen({
    super.key,
    this.replyToId,
    this.replyToUserId,
    this.replyToUsername,
    this.quoteTweetId,
  });

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('تغريدة جديدة'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('مسودة'),
          ),
        ],
      ),
      body: ComposeTweetSheet(
        replyToId: widget.replyToId,
        replyToUserId: widget.replyToUserId,
        replyToUsername: widget.replyToUsername,
        onTweetPosted: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
    );
  }
}