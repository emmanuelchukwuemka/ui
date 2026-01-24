import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/chat_item.dart';
import '../services/hapztext_api_service.dart';

class ChatApiService {
  final HapzTextApiService _apiService;
  WebSocketChannel? _channel;
  Stream<Message>? _messageStream;
  Stream<Map<String, dynamic>>? _typingStream;
  Stream<Map<String, dynamic>>? _readReceiptStream;
  Timer? _pingTimer;

  ChatApiService(this._apiService);

  // Expose the streams
  Stream<Message>? get messageStream => _messageStream;
  Stream<Map<String, dynamic>>? get typingStream => _typingStream;
  Stream<Map<String, dynamic>>? get readReceiptStream => _readReceiptStream;

  // Connect to the WebSocket
  void connectToWebSocket(String conversationId) {
    disconnectWebSocket(); // Close any existing connection

    final token = _apiService.token; // Access token from HapzApiService (need to add getter there)
    if (token == null) {
      print('No token available for WebSocket connection');
      return;
    }

    // Using ws:// for now, should be wss:// in production as per guide notes
    // Guide says: ws://localhost:8000/ws/chat/{conversation_id}/?token=<auth_token>
    // Real URL base from HapzTextApiService is https://hapztext-v2.onrender.com
    // So WS URL should be wss://hapztext-v2.onrender.com/ws/chat/...
    
    // Extract domain from base URL for WS
    final baseUrl = HapzTextApiService.baseUrl;
    final wsBaseUrl = baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    
    final wsUrl = '$wsBaseUrl/ws/chat/$conversationId/?token=$token';
    
    print('Connecting to WS: $wsUrl');
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      final broadcastStream = _channel!.stream.asBroadcastStream();

      _messageStream = broadcastStream.map((event) {
        try {
          final data = json.decode(event);
          if (data['type'] == 'chat_message') {
            return _convertWsMessageToMessage(data);
          }
          return null; 
        } catch (e) {
          print('Error parsing WS message: $e');
          return null;
        }
      }).where((msg) => msg != null).cast<Message>();

      _typingStream = broadcastStream.map((event) {
        try {
          final data = json.decode(event);
          if (data['type'] == 'typing_indicator') {
            return data as Map<String, dynamic>;
          }
          return null;
        } catch (e) {
          return null;
        }
      }).where((data) => data != null).cast<Map<String, dynamic>>();

      _readReceiptStream = broadcastStream.map((event) {
        try {
          final data = json.decode(event);
          if (data['type'] == 'read_receipt') {
            return data as Map<String, dynamic>;
          }
          return null;
        } catch (e) {
          return null;
        }
      }).where((data) => data != null).cast<Map<String, dynamic>>();

      // Start ping heartbeat
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_channel != null) {
          _channel!.sink.add(json.encode({"type": "ping"}));
        }
      });
      
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  // Send Typing Indicator
  void sendTyping(bool isTyping) {
    if (_channel != null) {
      try {
        _channel!.sink.add(json.encode({
          "type": "typing",
          "is_typing": isTyping
        }));
      } catch (e) {
        print('Error sending typing: $e');
      }
    }
  }

  // Mark messages as read via API
  Future<bool> markMessagesAsRead(String conversationId, List<String> messageIds) async {
    try {
       // Also send via WS if connected for immediate update to other user?
       // Docs say: HTTP Endpoint triggers the update.
       return await _apiService.markMessagesRead(conversationId, messageIds);
    } catch (e) {
      print('Error marking read: $e');
      return false;
    }
  }

  void disconnectWebSocket() {
    _pingTimer?.cancel();
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
  }

  // Send Read Receipt via WS
  void sendReadReceipts(List<String> messageIds) {
    if (_channel != null) {
      try {
        _channel!.sink.add(json.encode({
          "type": "read",
          "message_ids": messageIds
        }));
      } catch (e) {
        print('Error sending read receipt: $e');
      }
    }
  }

  Message _convertWsMessageToMessage(Map<String, dynamic> data) {
    final currentUserId = _apiService.currentUserId?.toString();
    final senderId = data['sender_id']?.toString();
    final bool me = currentUserId != null && senderId == currentUserId;

    return Message(
      id: data['id']?.toString() ?? DateTime.now().toString(),
      text: data['text_content'] ?? '',
      me: me,
      timestamp: DateTime.tryParse(data['created_at']) ?? DateTime.now(),
      viewed: data['status'] == 'read',
      isVoice: data['message_type'] == 'audio',
      audioPath: data['message_type'] == 'audio' ? data['media_url'] : null,
      isImage: data['message_type'] == 'image',
      imageUrl: data['message_type'] == 'image' ? data['media_url'] : null,
      isVideo: data['message_type'] == 'video',
      videoUrl: data['message_type'] == 'video' ? data['media_url'] : null,
      isReply: data['is_reply'] == true,
      previousMessageId: data['previous_message_id']?.toString(),
      previousMessageContent: data['previous_message_content'],
      previousMessageSenderId: data['previous_message_sender_id']?.toString(),
    );
  }

  // Convert API message data to Message objects
  List<Message> convertApiMessagesToMessages(dynamic messagesData) {
    List<Message> messages = [];
    final currentUserId = _apiService.currentUserId;
    
    if (messagesData != null && messagesData['data'] != null) {
      final msgs = messagesData['data']['messages'] ?? messagesData['data'];
      
      if (msgs is List) {
        for (int i = 0; i < msgs.length; i++) {
          final msg = msgs[i];
          final senderId = msg['sender_id'];
          final bool me = currentUserId != null && senderId == currentUserId;

          messages.add(Message(
            id: msg['id']?.toString() ?? DateTime.now().toString(),
            text: msg['text_content'] ?? '',
            me: me,
            timestamp: DateTime.tryParse(msg['created_at']) ?? DateTime.now(),
            viewed: msg['status'] == 'read',
            isVoice: msg['message_type'] == 'audio',
            audioPath: msg['message_type'] == 'audio' ? msg['media_url'] : null,
            isImage: msg['message_type'] == 'image',
            imageUrl: msg['message_type'] == 'image' ? msg['media_url'] : null,
            isVideo: msg['message_type'] == 'video',
            videoUrl: msg['message_type'] == 'video' ? msg['media_url'] : null,
            isReply: msg['is_reply'] == true,
            previousMessageId: msg['previous_message_id']?.toString(),
            previousMessageContent: msg['previous_message_content'],
            previousMessageSenderId: msg['previous_message_sender_id']?.toString(),
          ));
        }
      }
    }
    
    return messages;
  }

  // Send a message (Text or Media)
  Future<bool> sendMessage(String conversationId, String text, {File? file, String messageType = 'text'}) async {
    try {
      String? mediaUrl;
      
      // 1. Upload media if present
      if (file != null) {
        final uploadResult = await _apiService.uploadMedia(file, messageType);
        if (uploadResult != null && uploadResult['success'] == true) {
           mediaUrl = uploadResult['data']['media_url'];
        } else {
           print('Failed to upload media');
           return false;
        }
      }

      // 2. Send message with (optional) media_url
      final result = await _apiService.sendMessage(
        conversationId, 
        text, 
        type: messageType,
        mediaUrl: mediaUrl,
      );
      
      return result != null && result['success'] == true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get messages for a conversation
  Future<List<Message>> getConversationMessages(String conversationId) async {
    try {
      // Defaulting to page 1, size 50 for now
      final messagesData = await _apiService.getMessages(conversationId, 1, 50);
      return convertApiMessagesToMessages(messagesData);
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }
  
  // Get conversations list (Optional, if needed for a list screen)
  Future<List<ChatItem>> getConversations() async {
    try {
      final result = await _apiService.getConversations(1, 20);
      List<ChatItem> chats = [];
      
      if (result != null && result['data'] != null && result['data']['conversations'] is List) {
        final convs = result['data']['conversations'];
        for (var conv in convs) {
           // Mapping logic from API conversation to ChatItem
           // Note: API might not return "name" directly if it's private, might need to derive from participants
           // For now using simple mapping
           final lastMsg = conv['last_message'];
           String lastMsgText = '';
           if (lastMsg != null) {
             lastMsgText = lastMsg['text_content'] ?? '';
           }

           chats.add(ChatItem(
             id: conv['id'], 
             name: "Chat ${conv['id'].substring(0, 4)}", // Placeholder name
             lastMessage: lastMsgText,
             unread: conv['unread_count'] ?? 0,
           ));
        }
      }
      return chats;
    } catch (e) {
       print('Error getting conversations: $e');
       return [];
    }
  }

  // Deprecated/Legacy adapters to keep code compiling if needed, 
  // but we should update usage in ChatScreen.
  Future<List<Message>> getRecentPostsAsMessages() async {
     // This logic is flawed for a chat app, returning empty or trying to fetch from a default conversation if possible
     return [];
  }

  Future<bool> sendMessageAsPost(String text) async {
    return false;
  }
}
