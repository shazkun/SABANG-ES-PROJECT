class CustomMessage {
  String checkInMessage;
  String checkOutMessage;

  CustomMessage({required this.checkInMessage, required this.checkOutMessage});

  Map<String, String> toMap() {
    return {
      'checkInMessage': checkInMessage,
      'checkOutMessage': checkOutMessage,
    };
  }

  factory CustomMessage.fromMap(Map<String, String> map) {
    return CustomMessage(
      checkInMessage: map['checkInMessage'] ?? '',
      checkOutMessage: map['checkOutMessage'] ?? '',
    );
  }
}
