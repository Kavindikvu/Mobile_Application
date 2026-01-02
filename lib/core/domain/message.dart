enum MessageType {
  text,
  image,
  file,
  system,
}

enum MessageStatus {
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToMessageId;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.replyToMessageId,
    this.attachments = const [],
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      replyToMessageId: json['replyToMessageId'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'replyToMessageId': replyToMessageId,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToMessageId,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFromCurrentUser => senderId == 'current_user'; // This would be determined by auth state
  bool get isSystemMessage => type == MessageType.system;
  String get timeText => _formatTime(timestamp);
  String get statusIcon {
    switch (status) {
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '⚠';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

class Conversation {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSender;
  final int unreadCount;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String>? participantAvatars;
  final String? conversationAvatar;
  final bool isGroup;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    this.unreadCount = 0,
    this.participantIds = const [],
    this.participantNames = const {},
    this.participantAvatars,
    this.conversationAvatar,
    this.isGroup = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime'] as String) 
          : null,
      lastMessageSender: json['lastMessageSender'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      participantNames: (json['participantNames'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)) ?? {},
      participantAvatars: (json['participantAvatars'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
      conversationAvatar: json['conversationAvatar'] as String?,
      isGroup: json['isGroup'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'conversationAvatar': conversationAvatar,
      'isGroup': isGroup,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSender,
    int? unreadCount,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String>? participantAvatars,
    String? conversationAvatar,
    bool? isGroup,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantAvatars: participantAvatars ?? this.participantAvatars,
      conversationAvatar: conversationAvatar ?? this.conversationAvatar,
      isGroup: isGroup ?? this.isGroup,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;
  String get displayTitle => isGroup ? title : participantNames.values.first;
  String get lastMessageText => lastMessage ?? 'No messages yet';
  String get lastMessageTimeText {
    if (lastMessageTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastMessageTime!.month}/${lastMessageTime!.day}';
    }
  }
}
