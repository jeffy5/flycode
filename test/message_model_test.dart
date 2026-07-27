import 'package:flycode/service/api/models/message.dart' as msg;
import 'package:flycode/service/api/models/session.dart' as session;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses user message summary diffs with nullable opencode fields', () {
    final message = msg.MessageWithParts.fromJson({
      'info': {
        'id': 'message-1',
        'sessionID': 'session-1',
        'role': 'user',
        'time': {'created': 1},
        'summary': {
          'title': 'Apply patch',
          'diffs': [
            {
              'relativePath': 'lib/foo.dart',
              'before': null,
              'after': null,
              'additions': null,
              'deletions': null,
              'status': 'modified',
            },
          ],
        },
        'agent': 'codex',
        'model': {'providerID': 'openai', 'modelID': 'gpt-5.4'},
      },
      'parts': const [],
    });

    final info = message.info as msg.UserMessage;
    final diff = info.summary!.diffs.single;

    expect(diff.file, 'lib/foo.dart');
    expect(diff.before, isEmpty);
    expect(diff.after, isEmpty);
    expect(diff.additions, 0);
    expect(diff.deletions, 0);
    expect(diff.status, 'modified');
  });

  test('parses session diff payload with filePath fallback', () {
    final diff = session.FileDiff.fromJson({
      'filePath': '/tmp/project/lib/bar.dart',
      'before': null,
      'after': 'new content',
      'additions': 1,
      'deletions': null,
    });

    expect(diff.file, '/tmp/project/lib/bar.dart');
    expect(diff.before, isEmpty);
    expect(diff.after, 'new content');
    expect(diff.additions, 1);
    expect(diff.deletions, 0);
  });
}
