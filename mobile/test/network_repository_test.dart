import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/repositories/network/network.dart';

void main() {
  test('network repositories use backend contract endpoints', () async {
    final requests = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    const now = '2026-05-02T00:00:00Z';
    const userId = '11111111-1111-1111-1111-111111111111';
    const taskId = '22222222-2222-2222-2222-222222222222';
    const approvalId = '33333333-3333-3333-3333-333333333333';
    const repoId = '44444444-4444-4444-4444-444444444444';
    const contextId = '55555555-5555-5555-5555-555555555555';

    Map<String, dynamic> user() => {
      'id': userId,
      'google_sub': 'local-user',
      'email': 'gaurav@example.com',
      'name': 'Gaurav Local',
      'avatar_url': null,
      'created_at': now,
      'updated_at': now,
    };

    Map<String, dynamic> task({String status = 'queued'}) => {
      'id': taskId,
      'user_id': userId,
      'project_context_id': null,
      'title': null,
      'prompt': 'Create a task',
      'status': status,
      'current_phase': null,
      'created_at': now,
      'updated_at': now,
      'started_at': null,
      'finished_at': null,
      'error_message': null,
      'final_summary': null,
      'cancelled_at': null,
    };

    Map<String, dynamic> approval({String status = 'pending'}) => {
      'id': approvalId,
      'task_id': taskId,
      'kind': 'command_execution',
      'title': 'Approval required',
      'description': 'Worker wants to run Codex.',
      'payload_json': {'risk_level': 'medium'},
      'status': status,
      'created_at': now,
      'resolved_at': null,
    };

    Map<String, dynamic> repo() => {
      'id': repoId,
      'user_id': userId,
      'device_id': '66666666-6666-6666-6666-666666666666',
      'name': 'phodex',
      'local_path': '/Users/gaurav/phodex',
      'git_root': '/Users/gaurav/phodex',
      'current_branch': 'main',
      'default_branch': 'main',
      'is_active': true,
      'last_scanned_at': now,
      'last_opened_at': now,
      'metadata_json': {},
      'created_at': now,
      'updated_at': now,
    };

    Map<String, dynamic> projectContext() => {
      'id': contextId,
      'user_id': userId,
      'source_type': 'local_synced',
      'synced_repository_id': repoId,
      'name': 'phodex',
      'repo_url': null,
      'branch': 'main',
      'metadata_json': {},
      'created_at': now,
      'updated_at': now,
    };

    Future<void> writeJson(HttpRequest request, Object body) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    }

    final serverDone = server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      final path = request.uri.path;
      if (path == '/auth/google') {
        await writeJson(request, {
          'access_token': 'jwt',
          'expires_at': now,
          'user': user(),
        });
      } else if (path == '/auth/me') {
        await writeJson(request, user());
      } else if (path == '/tasks' && request.method == 'POST') {
        await writeJson(request, task());
      } else if (path == '/tasks') {
        await writeJson(request, {
          'items': [task(status: 'running')],
        });
      } else if (path == '/tasks/$taskId') {
        await writeJson(request, {
          'task': task(status: 'running'),
          'messages': [],
          'events': [],
          'approvals': [approval()],
        });
      } else if (path == '/tasks/$taskId/issues') {
        await writeJson(request, {'items': []});
      } else if (path == '/tasks/$taskId/reply') {
        await writeJson(request, {
          'id': '77777777-7777-7777-7777-777777777777',
          'task_id': taskId,
          'role': 'user',
          'content': 'reply',
          'created_at': now,
        });
      } else if (path == '/tasks/$taskId/cancel') {
        await writeJson(request, task(status: 'cancelled'));
      } else if (path == '/approvals/pending') {
        await writeJson(request, {
          'items': [approval()],
        });
      } else if (path == '/approvals/$approvalId/approve') {
        await writeJson(request, approval(status: 'approved'));
      } else if (path == '/repos') {
        await writeJson(request, {
          'items': [repo()],
        });
      } else if (path == '/repos/$repoId/select') {
        await writeJson(request, {'project_context': projectContext()});
      } else if (path == '/account/me') {
        await writeJson(request, {
          'user': user(),
          'active_sessions': 1,
          'generated_at': now,
        });
      } else if (path == '/account/usage') {
        await writeJson(request, {
          'user_id': userId,
          'generated_at': now,
          'total_tasks': 1,
          'queued_tasks': 0,
          'running_tasks': 1,
          'waiting_approval_tasks': 0,
          'completed_tasks': 0,
          'failed_tasks': 0,
          'cancelled_tasks': 0,
          'pending_approvals': 1,
          'total_events': 2,
          'active_sessions': 1,
        });
      } else if (path == '/account/limits') {
        await writeJson(request, {
          'generated_at': now,
          'max_active_sessions': null,
          'active_sessions': 1,
          'remaining_active_sessions': null,
          'max_concurrent_tasks': 3,
          'current_concurrent_tasks': 1,
          'remaining_concurrent_tasks': 2,
        });
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });

    try {
      final client = PhodexApiClient(
        ApiConfig(
          useNetwork: true,
          baseUrl: 'http://${server.address.host}:${server.port}',
          googleIdToken: 'test-token|local-user|gaurav@example.com|Gaurav',
        ),
      );

      final auth = NetworkAuthRepository(client);
      final tasks = NetworkTaskRepository(client);
      final approvals = NetworkApprovalRepository(client);
      final repos = NetworkRepoRepository(client);
      final account = NetworkAccountRepository(client);

      expect((await auth.getMe()).email, 'gaurav@example.com');
      expect((await tasks.createTask(prompt: 'Create a task')).id, taskId);
      expect((await tasks.listTasks()).single.status.value, 'running');
      expect(
        (await tasks.getTaskDetail(taskId)).approvals.single.id,
        approvalId,
      );
      expect(
        (await tasks.replyToTask(taskId: taskId, content: 'reply')).content,
        'reply',
      );
      expect((await tasks.cancelTask(taskId)).status.value, 'cancelled');
      expect((await approvals.listPending()).single.title, 'Approval required');
      expect(
        (await approvals.approve(approvalId: approvalId)).status.value,
        'approved',
      );
      expect((await repos.listRepositories()).single.name, 'phodex');
      expect((await repos.selectRepository(repoId: repoId)).id, contextId);
      expect(
        (await account.getAccountSummary()).user.email,
        'gaurav@example.com',
      );
      expect((await account.getUsageSummary()).totalTasks, 1);
      expect((await account.getLimitStatus()).remainingConcurrentTasks, 2);

      expect(requests, contains('POST /auth/google'));
      expect(requests, contains('POST /tasks'));
      expect(requests, contains('GET /tasks/$taskId'));
      expect(requests, contains('GET /tasks/$taskId/issues'));
      expect(requests, contains('POST /approvals/$approvalId/approve'));
      expect(requests, contains('POST /repos/$repoId/select'));
    } finally {
      await server.close(force: true);
      await serverDone.cancel();
    }
  });
}
