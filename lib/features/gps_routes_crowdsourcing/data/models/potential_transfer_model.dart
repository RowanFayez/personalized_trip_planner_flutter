import 'package:equatable/equatable.dart';

class PotentialTransferModel extends Equatable {
  final String detectedAt;
  final String? boardedAt;
  final String? userResponse;
  final String notificationSentAt;
  final bool resultedInSegmentSplit;

  const PotentialTransferModel({
    required this.detectedAt,
    required this.notificationSentAt,
    this.boardedAt,
    this.userResponse,
    this.resultedInSegmentSplit = false,
  });

  factory PotentialTransferModel.fromMap(Map<dynamic, dynamic> map) {
    return PotentialTransferModel(
      detectedAt:
          _readString(map['detected_at']) ?? DateTime.now().toIso8601String(),
      boardedAt: _readString(map['boarded_at']),
      userResponse: _readString(map['user_response']),
      notificationSentAt:
          _readString(map['notification_sent_at']) ??
          DateTime.now().toIso8601String(),
      resultedInSegmentSplit: map['resulted_in_segment_split'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'detected_at': detectedAt,
      'boarded_at': boardedAt,
      'user_response': userResponse,
      'notification_sent_at': notificationSentAt,
      'resulted_in_segment_split': resultedInSegmentSplit,
    };
  }

  PotentialTransferModel copyWith({
    String? detectedAt,
    String? boardedAt,
    bool clearBoardedAt = false,
    String? userResponse,
    bool clearUserResponse = false,
    String? notificationSentAt,
    bool? resultedInSegmentSplit,
  }) {
    return PotentialTransferModel(
      detectedAt: detectedAt ?? this.detectedAt,
      boardedAt: clearBoardedAt ? null : boardedAt ?? this.boardedAt,
      userResponse: clearUserResponse
          ? null
          : userResponse ?? this.userResponse,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      resultedInSegmentSplit:
          resultedInSegmentSplit ?? this.resultedInSegmentSplit,
    );
  }

  static String? _readString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  List<Object?> get props => <Object?>[
    detectedAt,
    boardedAt,
    userResponse,
    notificationSentAt,
    resultedInSegmentSplit,
  ];
}
