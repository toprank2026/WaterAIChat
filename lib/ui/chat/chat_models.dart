import 'package:ma_water/ui/genui_blocks/block_spec.dart';

/// Identifies who authored a [ChatMessage].
enum MessageRole { user, assistant }

/// A single message in the chat transcript.
///
/// A message can carry plain [text], a generative-UI [block], or be a
/// transient loading placeholder ([isLoading]).
class ChatMessage {
  final String id;
  final MessageRole role;
  final String? text;
  final BlockSpec? block;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.role,
    this.text,
    this.block,
    required this.createdAt,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? text,
    BlockSpec? block,
    DateTime? createdAt,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      block: block ?? this.block,
      createdAt: createdAt ?? this.createdAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
