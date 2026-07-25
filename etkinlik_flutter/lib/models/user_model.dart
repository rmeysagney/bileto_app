class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'participant' veya 'organizer'
  final String? phone;
  final String? profilePicture;
  final String? bio;
  final bool isOrganizer;
  final bool isParticipant;
  final bool isSuperuser;
  final int joinedEventsCount;
  final int organizedEventsCount;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.profilePicture,
    this.bio,
    required this.isOrganizer,
    required this.isParticipant,
    required this.isSuperuser,
    required this.joinedEventsCount,
    required this.organizedEventsCount,
  });

  bool get isAdmin => isSuperuser || username == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'participant',
      phone: json['phone'],
      profilePicture: json['profile_picture'],
      bio: json['bio'],
      isOrganizer: json['is_organizer'] ?? false,
      isParticipant: json['is_participant'] ?? true,
      isSuperuser: json['is_superuser'] ?? (json['username'] == 'admin'),
      joinedEventsCount: json['joined_events_count'] ?? 0,
      organizedEventsCount: json['organized_events_count'] ?? 0,
    );
  }

  String get fullName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return username;
  }
}
