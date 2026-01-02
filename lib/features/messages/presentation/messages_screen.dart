import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/domain/message.dart';
import '../../../../core/theme/tokens.dart';
import '../data/message_repository.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(_showArchived ? Icons.inbox : Icons.archive_outlined),
            tooltip: _showArchived ? 'Show inbox' : 'Show archived',
            onPressed: () {
              setState(() { _showArchived = !_showArchived; });
            },
          ),
        ),
        _SearchBar(
          controller: _searchController,
          onChanged: (query) {
            setState(() { _searchQuery = query; });
          },
        ),
        Expanded(
          child: conversationsAsync.when(
            loading: () => const _LoadingState(),
            error: (error, stackTrace) => _ErrorState(error: error.toString()),
            data: (conversations) {
              final filteredConversations = _filterConversations(conversations);
              if (filteredConversations.isEmpty) {
                return _EmptyState(
                  hasSearch: _searchQuery.isNotEmpty,
                  onClearSearch: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                );
              }
              return _ConversationList(conversations: filteredConversations);
            },
          ),
        ),
      ],
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    var filtered = conversations.where((c) => c.isArchived == _showArchived).toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) => 
        c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.lastMessage?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
        c.participantNames.values.any((name) => 
          name.toLowerCase().contains(_searchQuery.toLowerCase())
        )
      ).toList();
    }
    
    // Sort by last message time (most recent first)
    filtered.sort((a, b) {
      if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });
    
    return filtered;
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;

  const _ConversationList({required this.conversations});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationCard(conversation: conversation);
      },
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final Conversation conversation;

  const _ConversationCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: InkWell(
        onTap: () => _openConversation(context, conversation),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _ConversationAvatar(conversation: conversation),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: conversation.hasUnreadMessages 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (conversation.hasUnreadMessages)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      conversation.lastMessageText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: conversation.hasUnreadMessages 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (conversation.lastMessageSender != null)
                          Text(
                            '${conversation.lastMessageSender}: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            conversation.lastMessageTimeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (conversation.isGroup)
                          Icon(
                            Icons.group,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openConversation(BuildContext context, Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatScreen(conversation: conversation),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  final Conversation conversation;

  const _ConversationAvatar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    if (conversation.isGroup) {
      return Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.group,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  conversation.participantIds.length.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final otherIds = conversation.participantIds
          .where((id) => id != 'current_user')
          .toList();
      final String? participantId = otherIds.isNotEmpty ? otherIds.first : null;
      String? avatar;
      if (participantId != null) {
        final avatars = conversation.participantAvatars;
        avatar = avatars != null ? avatars[participantId] : null;
      } else {
        avatar = null;
      }
      
      return CircleAvatar(
        radius: 24,
        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
        backgroundColor: avatar == null 
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: avatar == null
            ? Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              )
            : null,
      );
    }
  }
}

class _ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const _ChatScreen({required this.conversation});

  @override
  ConsumerState<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<_ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.displayTitle),
            if (widget.conversation.isGroup)
              Text(
                '${widget.conversation.participantIds.length} members',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showConversationInfo(context, widget.conversation),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Error loading messages',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => ref.refresh(messagesProvider(widget.conversation.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return _EmptyChatState(conversation: widget.conversation);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(messagesProvider(widget.conversation.id));
                  },
                  child: _MessageList(messages: messages),
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    
    // TODO: Implement send message functionality
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sending not yet implemented')),
    );
  }

  void _showConversationInfo(BuildContext context, Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ConversationInfoSheet(conversation: conversation),
    );
  }
}

class _MessageList extends StatefulWidget {
  final List<Message> messages;

  const _MessageList({required this.messages});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final isLastMessage = index == widget.messages.length - 1;
        final isFirstMessage = index == 0;
        final previousMessage = isFirstMessage ? null : widget.messages[index - 1];
        final showAvatar = isLastMessage || 
            previousMessage?.senderId != message.senderId;
        final showDateSeparator = isFirstMessage || 
            (previousMessage != null && !_isSameDay(previousMessage!.timestamp, message.timestamp));
        
        return Column(
          children: [
            if (showDateSeparator)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      _formatDate(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            _MessageBubble(
              message: message,
              showAvatar: showAvatar,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isFromCurrentUser = message.isFromCurrentUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar != null 
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              backgroundColor: message.senderAvatar == null 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: message.senderAvatar == null
                  ? Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
          if (!isFromCurrentUser && showAvatar)
            const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromCurrentUser && showAvatar)
                    Text(
                      message.senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isFromCurrentUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isFromCurrentUser && showAvatar)
                    const SizedBox(height: AppSpacing.xs),
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isFromCurrentUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isFromCurrentUser
                              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          message.statusIcon,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isFromCurrentUser
                                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser && showAvatar)
            const SizedBox(width: AppSpacing.sm),
          if (isFromCurrentUser && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement file attachment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File attachment not yet implemented')),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              widget.onSend(widget.controller.text);
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final Conversation conversation;

  const _EmptyChatState({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Start a conversation with ${conversation.displayTitle}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationInfoSheet extends StatelessWidget {
  final Conversation conversation;

  const _ConversationInfoSheet({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversation Info',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: _ConversationAvatar(conversation: conversation),
            title: Text(conversation.displayTitle),
            subtitle: Text(conversation.isGroup ? 'Group chat' : 'Direct message'),
          ),
          if (conversation.isGroup) ...[
            const Divider(),
            Text(
              'Members (${conversation.participantIds.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...conversation.participantNames.entries.map((entry) => ListTile(
              leading: CircleAvatar(
                backgroundImage: conversation.participantAvatars?[entry.key] != null
                    ? NetworkImage(conversation.participantAvatars![entry.key]!)
                    : null,
                child: conversation.participantAvatars?[entry.key] == null
                    ? Icon(Icons.person)
                    : null,
              ),
              title: Text(entry.value),
              subtitle: Text(entry.key == 'current_user' ? 'You' : 'Member'),
            )),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archive Conversation'),
            onTap: () {
              // TODO: Implement archive functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Archive functionality not yet implemented')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Loading conversations...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onClearSearch;

  const _EmptyState({
    required this.hasSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasSearch ? 'No conversations found' : 'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasSearch
                  ? 'Try adjusting your search terms'
                  : 'Start a conversation with your instructors or classmates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearch) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: onClearSearch,
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
