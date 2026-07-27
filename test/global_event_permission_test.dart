import 'package:flutter_test/flutter_test.dart';
import 'package:flycode/service/api/models/global_event.dart';

void main() {
  test('parseEvent parses permission.asked', () {
    final event = parseEvent({
      'type': 'permission.asked',
      'properties': {
        'id': 'perm-1',
        'sessionID': 'sess-1',
        'permission': 'bash',
        'patterns': ['npm run test'],
        'always': ['npm run *'],
        'metadata': {'command': 'npm run test'},
        'tool': {'messageID': 'msg-1', 'callID': 'call-1'},
      },
    });

    expect(event, isA<EventPermissionAsked>());
    final asked = event as EventPermissionAsked;
    expect(asked.request.id, 'perm-1');
    expect(asked.request.sessionID, 'sess-1');
    expect(asked.request.permission, 'bash');
    expect(asked.request.patterns, ['npm run test']);
    expect(asked.request.always, ['npm run *']);
    expect(asked.request.tool?.messageID, 'msg-1');
    expect(asked.request.tool?.callID, 'call-1');
  });

  test('parseEvent parses permission.replied', () {
    final event = parseEvent({
      'type': 'permission.replied',
      'properties': {'sessionID': 'sess-2', 'requestID': 'perm-2'},
    });

    expect(event, isA<EventPermissionReplied>());
    final replied = event as EventPermissionReplied;
    expect(replied.sessionID, 'sess-2');
    expect(replied.requestID, 'perm-2');
  });

  test('parseEvent keeps unknown event as sentinel', () {
    final event = parseEvent({
      'type': 'permission.future',
      'properties': {'foo': 'bar'},
    });
    expect(event, isA<EventUnknown>());
  });

  test('parseEvent parses session.status payload', () {
    final event = parseEvent({
      'type': 'session.status',
      'properties': {
        'sessionID': 'sess-9',
        'status': {'type': 'busy'},
      },
    });

    expect(event, isA<EventSessionStatus>());
    final statusEvent = event as EventSessionStatus;
    expect(statusEvent.sessionID, 'sess-9');
    expect(statusEvent.status.isWorking, isTrue);
  });

  test('parseEvent parses session.idle payload', () {
    final event = parseEvent({
      'type': 'session.idle',
      'properties': {'sessionID': 'sess-idle-1'},
    });

    expect(event, isA<EventSessionIdle>());
    final idleEvent = event as EventSessionIdle;
    expect(idleEvent.sessionID, 'sess-idle-1');
  });

  test('parseEvent parses message.part.delta payload', () {
    final event = parseEvent({
      'type': 'message.part.delta',
      'properties': {
        'sessionID': 'sess-1',
        'messageID': 'msg-1',
        'partID': 'part-1',
        'field': 'text',
        'delta': 'x',
      },
    });

    expect(event, isA<EventMessagePartDelta>());
    final deltaEvent = event as EventMessagePartDelta;
    expect(deltaEvent.sessionID, 'sess-1');
    expect(deltaEvent.messageID, 'msg-1');
    expect(deltaEvent.partID, 'part-1');
    expect(deltaEvent.field, 'text');
    expect(deltaEvent.delta, 'x');
  });
}
