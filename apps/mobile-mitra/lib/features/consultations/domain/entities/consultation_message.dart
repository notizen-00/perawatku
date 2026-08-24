import 'package:equatable/equatable.dart';

class ConsultationChatMessage extends Equatable {
  const ConsultationChatMessage({
    required this.id,
    required this.senderUserId,
    required this.senderName,
    required this.senderRole,
    required this.messageType,
    required this.message,
    required this.attachmentPath,
    required this.createdAt,
  });

  /// Shared parser for both the REST response shape (`GET .../messages`,
  /// `POST .../messages`) and the Reverb broadcast payload of
  /// `ChatMessageCreated` -- both use the same field names.
  factory ConsultationChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final senderMap = sender is Map<String, dynamic> ? sender : null;

    int asInt(Object? value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ConsultationChatMessage(
      id: asInt(json['id']),
      senderUserId: asInt(json['sender_user_id'] ?? senderMap?['id']),
      senderName: senderMap?['name']?.toString() ?? 'Pengguna',
      senderRole: senderMap?['role']?.toString() ?? '-',
      messageType: json['message_type']?.toString() ?? 'text',
      message: json['message']?.toString(),
      attachmentPath: json['attachment_path']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  final int id;
  final int senderUserId;
  final String senderName;
  final String senderRole;
  final String messageType;
  final String? message;
  final String? attachmentPath;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    senderUserId,
    senderName,
    senderRole,
    messageType,
    message,
    attachmentPath,
    createdAt,
  ];
}
