class Message {
  final String id;
  final String text;
  final bool me;
  final bool isVoice;
  final DateTime timestamp;
  final bool viewOnce;
  final bool viewed;
  final bool isFeedLink;
  final bool disappearing;

  Message({
    required this.id,
    required this.text,
    required this.me,
    this.isVoice = false,
    required this.timestamp,
    this.viewOnce = false,
    this.viewed = false,
    this.isFeedLink = false,
    this.disappearing = false,
  });

  Message copyWith({
    String? id,
    String? text,
    bool? me,
    bool? isVoice,
    DateTime? timestamp,
    bool? viewOnce,
    bool? viewed,
    bool? isFeedLink,
    bool? disappearing,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      me: me ?? this.me,
      isVoice: isVoice ?? this.isVoice,
      timestamp: timestamp ?? this.timestamp,
      viewOnce: viewOnce ?? this.viewOnce,
      viewed: viewed ?? this.viewed,
      isFeedLink: isFeedLink ?? this.isFeedLink,
      disappearing: disappearing ?? this.disappearing,
    );
  }
}
