import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/asset_data_provider.dart';
import '../../../../core/domain/message.dart';

final assetDataProviderProvider = Provider<AssetDataProvider>((ref) => const AssetDataProvider());

class MessageRepository {
  const MessageRepository(this._assetDataProvider);

  final AssetDataProvider _assetDataProvider;

  Future<List<Conversation>> getConversations() async {
    try {
      final data = await _assetDataProvider.loadList('assets/data/conversations.json');
      return data.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final data = await _assetDataProvider.loadList('assets/data/messages.json');
      final messages = data.map((json) => Message.fromJson(json)).toList();
      return messages.where((m) => m.conversationId == conversationId).toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<Conversation?> getConversationById(String id) async {
    try {
      final conversations = await getConversations();
      return conversations.where((c) => c.id == id).firstOrNull;
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }

  Future<List<Conversation>> searchConversations(String query) async {
    try {
      final conversations = await getConversations();
      return conversations.where((c) => 
        c.title.toLowerCase().contains(query.toLowerCase()) ||
        c.lastMessage?.toLowerCase().contains(query.toLowerCase()) == true ||
        c.participantNames.values.any((name) => 
          name.toLowerCase().contains(query.toLowerCase())
        )
      ).toList();
    } catch (e) {
      throw Exception('Failed to search conversations: $e');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    // TODO: Implement mark as read functionality
    // This would typically update the backend
  }

  Future<void> sendMessage(String conversationId, String content, {MessageType type = MessageType.text}) async {
    // TODO: Implement send message functionality
    // This would typically send to backend and update local state
  }
}

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final assetDataProvider = ref.watch(assetDataProviderProvider);
  return MessageRepository(assetDataProvider);
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getConversations();
});

final messagesProvider = FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getMessages(conversationId);
});

final conversationByIdProvider = FutureProvider.family<Conversation?, String>((ref, id) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.getConversationById(id);
});

final conversationSearchProvider = FutureProvider.family<List<Conversation>, String>((ref, query) async {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.searchConversations(query);
});