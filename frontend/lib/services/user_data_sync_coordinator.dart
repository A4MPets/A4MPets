class UserDataSyncCoordinator {
  const UserDataSyncCoordinator();

  Future<void> scheduleSync() async {
    // Reserved for future backend synchronization. Local DB remains source of truth
    // for reads while remote sync will reconcile pending user data changes.
  }
}
