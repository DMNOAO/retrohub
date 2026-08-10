class RetroHubUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  const RetroHubUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  factory RetroHubUser.fromGoogleJson(Map<String, dynamic> json) {
    final email = (json['email'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim();

    return RetroHubUser(
      id: (json['id'] as String?) ?? (json['sub'] as String?) ?? email,
      email: email,
      displayName: name == null || name.isEmpty ? email : name,
      photoUrl: json['picture'] as String?,
    );
  }
}
