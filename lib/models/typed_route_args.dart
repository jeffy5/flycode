class SessionDiffRouteArgs {
  const SessionDiffRouteArgs({required this.directory});

  final String directory;
}

class FileContentRouteArgs {
  const FileContentRouteArgs({required this.filePath});

  final String filePath;
}

class SubSessionRouteArgs {
  const SubSessionRouteArgs({required this.sessionID});

  final String sessionID;
}

class SessionContextRouteArgs {
  const SessionContextRouteArgs({required this.sessionID});

  final String sessionID;
}
