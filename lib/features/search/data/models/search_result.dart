import 'package:adentweet/features/auth/data/models/user_model.dart';
import 'package:adentweet/features/tweets/data/models/tweet_model.dart';

class SearchResult {
  final List<UserModel> users;
  final List<TweetModel> tweets;

  const SearchResult({
    this.users = const [],
    this.tweets = const [],
  });

  bool get isEmpty => users.isEmpty && tweets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  SearchResult copyWith({
    List<UserModel>? users,
    List<TweetModel>? tweets,
  }) {
    return SearchResult(
      users: users ?? this.users,
      tweets: tweets ?? this.tweets,
    );
  }
}

class TrendingHashtag {
  final String tag;
  final int count;

  const TrendingHashtag({
    required this.tag,
    required this.count,
  });

  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      tag: json['tag'] as String,
      count: (json['count'] as int?) ?? 0,
    );
  }
}