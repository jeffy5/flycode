import '../../service/api/models/global_event.dart';

enum GlobalEventScope { global, project }

enum GlobalEventRouteTarget {
  session,
  message,
  question,
  permission,
  todo,
  unread,
  notification,
  status,
}

bool shouldDispatchGlobalEventForDirectory(
  GlobalEvent event, {
  required String? currentDirectory,
}) {
  final scope = scopeForGlobalEventPayload(event.payload);
  if (currentDirectory == null || currentDirectory.isEmpty) {
    return scope == GlobalEventScope.global;
  }

  if (scope == GlobalEventScope.global) {
    return true;
  }

  return event.directory == currentDirectory;
}

GlobalEventScope scopeForGlobalEventPayload(Object payload) {
  if (payload is EventSessionCreated ||
      payload is EventSessionUpdated ||
      payload is EventSessionDeleted ||
      payload is EventMessageUpdated ||
      payload is EventMessageRemoved ||
      payload is EventMessagePartUpdated ||
      payload is EventMessagePartDelta ||
      payload is EventMessagePartRemoved ||
      payload is EventQuestionAsked ||
      payload is EventQuestionReplied ||
      payload is EventQuestionRejected ||
      payload is EventPermissionAsked ||
      payload is EventPermissionReplied ||
      payload is EventTodoUpdated ||
      payload is EventSessionStatus ||
      payload is EventSessionIdle ||
      payload is EventSessionError) {
    return GlobalEventScope.project;
  }

  return GlobalEventScope.global;
}

List<GlobalEventRouteTarget> routeGlobalEventPayload(Object payload) {
  if (payload is EventSessionCreated ||
      payload is EventSessionUpdated ||
      payload is EventSessionDeleted) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.session];
  }

  if (payload is EventMessageUpdated ||
      payload is EventMessageRemoved ||
      payload is EventMessagePartUpdated ||
      payload is EventMessagePartDelta ||
      payload is EventMessagePartRemoved) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.message];
  }

  if (payload is EventQuestionAsked ||
      payload is EventQuestionReplied ||
      payload is EventQuestionRejected) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.question];
  }

  if (payload is EventPermissionAsked || payload is EventPermissionReplied) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.permission];
  }

  if (payload is EventTodoUpdated) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.todo];
  }

  if (payload is EventSessionStatus) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.status];
  }

  if (payload is EventSessionIdle) {
    return const <GlobalEventRouteTarget>[
      GlobalEventRouteTarget.unread,
      GlobalEventRouteTarget.notification,
    ];
  }

  if (payload is EventSessionError) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.unread];
  }

  return const <GlobalEventRouteTarget>[];
}
