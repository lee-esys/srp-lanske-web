class EventCapabilities {
  const EventCapabilities({
    required this.isOwner,
  });

  final bool isOwner;

  bool get canEditDisplay => isOwner;
  bool get canEditCourtSettings => isOwner;
  bool get canManageOwnership => isOwner;
}

EventCapabilities resolveEventCapabilities({
  required String? ownerUid,
  required String? currentUid,
}) {
  final normalizedOwnerUid = ownerUid?.trim();
  final normalizedCurrentUid = currentUid?.trim();

  final isOwner = normalizedOwnerUid != null &&
      normalizedOwnerUid.isNotEmpty &&
      normalizedCurrentUid != null &&
      normalizedCurrentUid.isNotEmpty &&
      normalizedOwnerUid == normalizedCurrentUid;

  return EventCapabilities(isOwner: isOwner);
}
