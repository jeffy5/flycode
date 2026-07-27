import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'models/typed_route_args.dart';

const String sessionDiffRoutePath = '/diff';
const String fileContentRoutePath = '/file';
const String subSessionRoutePath = '/sub-session';
const String sessionContextRoutePath = '/session-context';

extension AppRouteNavigation on BuildContext {
  Future<T?> pushSessionDiff<T>(SessionDiffRouteArgs args) {
    return push<T>(sessionDiffRoutePath, extra: args);
  }

  Future<T?> pushSessionDiffById<T>(String sessionID) {
    return pushSessionDiff<T>(SessionDiffRouteArgs(sessionID: sessionID));
  }

  Future<T?> pushFileContent<T>(FileContentRouteArgs args) {
    return push<T>(fileContentRoutePath, extra: args);
  }

  Future<T?> pushFileContentByPath<T>(String filePath) {
    return pushFileContent<T>(FileContentRouteArgs(filePath: filePath));
  }

  Future<T?> pushSubSession<T>(SubSessionRouteArgs args) {
    return push<T>(subSessionRoutePath, extra: args);
  }

  Future<T?> pushSubSessionById<T>(String sessionID) {
    return pushSubSession<T>(SubSessionRouteArgs(sessionID: sessionID));
  }

  Future<T?> pushSessionContext<T>(SessionContextRouteArgs args) {
    return push<T>(sessionContextRoutePath, extra: args);
  }

  Future<T?> pushSessionContextById<T>(String sessionID) {
    return pushSessionContext<T>(SessionContextRouteArgs(sessionID: sessionID));
  }
}
