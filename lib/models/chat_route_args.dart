class ChatRouteArgs {
  final String directory;
  final String? initialSessionId;
  final bool startNew;

  const ChatRouteArgs({
    required this.directory,
    this.initialSessionId,
    this.startNew = false,
  });
}
