class LeaveAttachment {
  const LeaveAttachment({
    this.id,
    this.name,
    this.description,
    this.link,
    this.isLocal = false,
    this.bytes,
    this.fileType,
    this.isPhoto = false,
  });

  final int? id;
  final String? name;
  final String? description;
  final String? link;
  final bool isLocal;
  final List<int>? bytes;
  final String? fileType;
  final bool isPhoto;

  LeaveAttachment copyWith({
    int? id,
    String? name,
    String? description,
    String? link,
    bool? isLocal,
    List<int>? bytes,
    String? fileType,
    bool? isPhoto,
  }) {
    return LeaveAttachment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      link: link ?? this.link,
      isLocal: isLocal ?? this.isLocal,
      bytes: bytes ?? this.bytes,
      fileType: fileType ?? this.fileType,
      isPhoto: isPhoto ?? this.isPhoto,
    );
  }
}
