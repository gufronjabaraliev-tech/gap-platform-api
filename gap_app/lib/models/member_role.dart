enum MemberRole {
  responsible,
  member;

  bool get isResponsible => this == MemberRole.responsible;
  bool get canEdit => isResponsible;

  static MemberRole fromString(String? v) =>
      v == 'responsible' ? MemberRole.responsible : MemberRole.member;
}
