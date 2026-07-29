import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/vcs_api.dart';

class _FakeHttpClient extends http.BaseClient {
  final List<http.BaseRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          '[{"file":"lib/main.dart","before":"old","after":"new",'
          '"patch":"@@ -1 +1 @@\\n-old\\n+new","additions":1,'
          '"deletions":1,"status":"modified"}]',
        ),
      ),
      200,
      request: request,
    );
  }
}

void main() {
  test(
    'getDiff requests git and branch modes with encoded directory',
    () async {
      final rawClient = _FakeHttpClient();
      final api = VcsApi(
        ApiClient(baseUrl: 'http://localhost:4096', client: rawClient),
      );

      final gitDiffs = await api.getDiff(
        mode: VcsDiffMode.git,
        directory: '/tmp/project with spaces',
      );
      await api.getDiff(
        mode: VcsDiffMode.branch,
        directory: '/tmp/project with spaces',
      );

      expect(rawClient.requests, hasLength(2));
      expect(rawClient.requests[0].url.path, '/vcs/diff');
      expect(rawClient.requests[0].url.queryParameters, {
        'mode': 'git',
        'directory': '/tmp/project with spaces',
      });
      expect(rawClient.requests[1].url.queryParameters, {
        'mode': 'branch',
        'directory': '/tmp/project with spaces',
      });
      expect(gitDiffs, hasLength(1));
      expect(gitDiffs.single.file, 'lib/main.dart');
      expect(gitDiffs.single.before, 'old');
      expect(gitDiffs.single.after, 'new');
      expect(gitDiffs.single.additions, 1);
      expect(gitDiffs.single.deletions, 1);
      expect(gitDiffs.single.status, 'modified');
    },
  );
}
