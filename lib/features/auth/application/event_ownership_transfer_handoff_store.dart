import '../domain/event_ownership_transfer.dart';

abstract interface class EventOwnershipTransferHandoffStore {
  EventOwnershipTransferHandoff? load();

  void save(EventOwnershipTransferHandoff handoff);

  void clear();
}
