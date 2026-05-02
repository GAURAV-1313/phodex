import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/data/dto/dto.dart';
import 'package:mobile/core/data/mappers/mappers.dart';
import 'package:mobile/core/domain/models/models.dart';

Map<String, dynamic> _loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  test('parses task detail fixture into domain model', () {
    final dto = TaskDetailResponseDto.fromJson(
      _loadFixture('task_detail.json'),
    );
    final detail = dto.toDomainWithIssues(const <TaskIssue>[]);

    expect(detail.task.id, 'task_123');
    expect(detail.task.status, TaskStatus.running);
    expect(detail.messages.length, 2);
    expect(detail.events.length, 2);
    expect(detail.approvals.first.status, ApprovalStatus.pending);
  });

  test('parses usage summary fixture', () {
    final usage = UsageSummaryResponseDto.fromJson(
      _loadFixture('usage_summary.json'),
    ).toDomain();

    expect(usage.totalTasks, 10);
    expect(usage.runningTasks, 2);
    expect(usage.pendingApprovals, 1);
  });

  test('parses repo list fixture', () {
    final repoList = RepoListResponseDto.fromJson(
      _loadFixture('repo_list.json'),
    );

    expect(repoList.items.length, 1);
    expect(repoList.items.first.name, 'phodex');
    expect(repoList.items.first.currentBranch, 'main');
  });
}
