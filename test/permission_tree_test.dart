import 'package:flutter_test/flutter_test.dart';
import 'package:flycode/providers/permission_provider.dart';
import 'package:flycode/service/api/models/session.dart';

Session _session(String id, {String? parentID}) {
  return Session(
    id: id,
    slug: id,
    projectID: 'project-1',
    directory: '/tmp/project',
    parentID: parentID,
    version: '1',
    time: SessionTime(created: 1, updated: 1),
  );
}

void main() {
  test('collectSessionTree includes current session and descendants', () {
    final sessions = <Session>[
      _session('root'),
      _session('child-a', parentID: 'root'),
      _session('child-b', parentID: 'root'),
      _session('grandchild', parentID: 'child-a'),
      _session('other-root'),
      _session('other-child', parentID: 'other-root'),
    ];

    final ids = collectSessionTree('root', sessions);

    expect(ids.contains('root'), isTrue);
    expect(ids.contains('child-a'), isTrue);
    expect(ids.contains('child-b'), isTrue);
    expect(ids.contains('grandchild'), isTrue);
    expect(ids.contains('other-root'), isFalse);
    expect(ids.contains('other-child'), isFalse);
  });
}
