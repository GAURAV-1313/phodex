import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/domain/models/models.dart';
import 'package:mobile/core/repositories/mock/mock_backend_store.dart';
import 'package:mobile/features/repos/presentation/repos_screen.dart';
import 'package:mobile/shared/widgets/stitch_ui.dart';

import 'test_helpers.dart';

/// PhodexMascot animates continuously by design, so pumpAndSettle() never
/// settles here — pump a bounded, fixed amount instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Finder textAnywhere(String text) => find.text(text, skipOffstage: false);

const desktopCopy =
    'Repo sync is metadata-only — no shell, file, or search access from your phone.';
const cloudCopy = 'Cloud workspaces are cloned on Phodex Cloud and run there.';

void main() {
  testWidgets('Lists synced repositories with the desktop overview', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const ReposScreen(), store: store));
    await settle(tester);

    expect(find.text('Repositories'), findsOneWidget);
    expect(textAnywhere("Gaurav's Mac"), findsWidgets);
    expect(textAnywhere('Metadata sync'), findsOneWidget);
    expect(textAnywhere(desktopCopy), findsOneWidget);
    expect(textAnywhere(cloudCopy), findsNothing);
    expect(textAnywhere('Add GitHub repository'), findsNothing);

    expect(textAnywhere('AFTR-backend'), findsOneWidget);
    expect(textAnywhere('phodex'), findsOneWidget);
    expect(textAnywhere('legacy-tools'), findsOneWidget);
    expect(textAnywhere('/Users/gaurav/phodex'), findsOneWidget);
    // The seeded context points at repo_002 (phodex), so it is the active
    // one and the other two offer "Use".
    expect(textAnywhere('Active'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Use', skipOffstage: false),
      findsNWidgets(2),
    );
    expect(textAnywhere('Needs sync'), findsOneWidget);
  });

  testWidgets('"Use" switches the active repository', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(wrapWithTestApp(const ReposScreen(), store: store));
    await settle(tester);

    final use = find.widgetWithText(FilledButton, 'Use', skipOffstage: false);
    await tester.ensureVisible(use.first);
    await settle(tester);
    await tester.tap(use.first);
    await settle(tester);

    expect(textAnywhere('Now working in AFTR-backend'), findsOneWidget);
    expect(store.getSelectedProjectContext()?.syncedRepositoryId, 'repo_001');
  });

  testWidgets('Empty desktop store offers to connect the desktop', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false)
      ..clearRepositories();

    await tester.pumpWidget(wrapWithTestApp(const ReposScreen(), store: store));
    await settle(tester);

    expect(textAnywhere('No repos synced yet'), findsOneWidget);
    expect(
      textAnywhere(
        'Run the Phodex device agent on your desktop to sync your projects.',
      ),
      findsOneWidget,
    );
    expect(textAnywhere('Connect desktop'), findsOneWidget);
    expect(textAnywhere(desktopCopy), findsOneWidget);
  });

  testWidgets('Cloud runtime can connect a GitHub repository', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false)
      ..runtimeMode = RuntimeMode.cloud;

    await tester.pumpWidget(wrapWithTestApp(const ReposScreen(), store: store));
    await settle(tester);

    expect(textAnywhere('Phodex Cloud'), findsWidgets);
    expect(textAnywhere(cloudCopy), findsOneWidget);
    expect(textAnywhere(desktopCopy), findsNothing);

    final addButton = textAnywhere('Add GitHub repository');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await settle(tester);

    expect(find.text('Repository URL'), findsOneWidget);
    expect(
      find.textContaining('Fine-grained personal access token'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('github-url-field')),
      'https://github.com/acme/widgets.git',
    );
    await tester.enterText(
      find.byKey(const Key('github-branch-field')),
      'develop',
    );
    await tester.tap(find.widgetWithText(StitchPrimaryButton, 'Connect'));
    await settle(tester);
    await settle(tester);

    // Sheet closed, repo listed, confirmation shown, and it is now active.
    expect(find.text('Repository URL'), findsNothing);
    expect(textAnywhere('widgets'), findsOneWidget);
    expect(textAnywhere('Connected widgets'), findsOneWidget);
    expect(textAnywhere('Cloud'), findsWidgets);
    expect(textAnywhere('develop'), findsOneWidget);
    expect(store.listRepositories().first.name, 'widgets');
    expect(
      store.getSelectedProjectContext()?.sourceType,
      ProjectContextSourceType.github,
    );
  });

  testWidgets('Cloud empty state opens the GitHub sheet', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false)
      ..runtimeMode = RuntimeMode.cloud
      ..clearRepositories();

    await tester.pumpWidget(wrapWithTestApp(const ReposScreen(), store: store));
    await settle(tester);

    expect(textAnywhere('No repos synced yet'), findsOneWidget);
    // One in the overview area, one as the empty-state action.
    expect(textAnywhere('Add GitHub repository'), findsNWidgets(2));
    expect(textAnywhere('Connect desktop'), findsNothing);

    final emptyAction = find.widgetWithText(
      FilledButton,
      'Add GitHub repository',
      skipOffstage: false,
    );
    await tester.ensureVisible(emptyAction);
    await settle(tester);
    await tester.tap(emptyAction);
    await settle(tester);
    expect(find.text('Repository URL'), findsOneWidget);
  });

  testWidgets('Connecting without a URL shows an inline error', (tester) async {
    final store = MockBackendStore(enableDynamicSimulation: false)
      ..runtimeMode = RuntimeMode.cloud;

    await tester.pumpWidget(wrapWithTestApp(const ReposScreen(), store: store));
    await settle(tester);
    await tester.tap(textAnywhere('Add GitHub repository'));
    await settle(tester);

    await tester.tap(find.widgetWithText(StitchPrimaryButton, 'Connect'));
    await settle(tester);

    expect(
      find.text('Enter the GitHub repository URL to connect.'),
      findsOneWidget,
    );
    expect(find.text('Repository URL'), findsOneWidget);
  });

  testWidgets('Detail screen for an unknown id shows not-found with back', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(
        const RepositoryDetailScreen(repoId: 'repo_missing'),
        store: store,
      ),
    );
    await settle(tester);

    expect(find.text('Repository not found'), findsOneWidget);
    expect(
      find.text('It may have been removed or synced from another device.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('stitch-back-button')), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Detail screen shows repository facts and sets the default', (
    tester,
  ) async {
    final store = MockBackendStore(enableDynamicSimulation: false);

    await tester.pumpWidget(
      wrapWithTestApp(
        const RepositoryDetailScreen(repoId: 'repo_001'),
        store: store,
      ),
    );
    await settle(tester);

    expect(find.text('AFTR-backend'), findsOneWidget);
    expect(
      textAnywhere('/Users/gaurav/Documents/aftr/AFTR-backend'),
      findsOneWidget,
    );
    expect(textAnywhere('Current branch'), findsOneWidget);
    expect(textAnywhere('Last synced'), findsOneWidget);
    expect(find.byKey(const Key('stitch-back-button')), findsOneWidget);

    final setDefault = textAnywhere('Set as default');
    await tester.ensureVisible(setDefault);
    await settle(tester);
    await tester.tap(setDefault);
    await settle(tester);

    expect(textAnywhere('Now working in AFTR-backend'), findsOneWidget);
    expect(store.getSelectedProjectContext()?.syncedRepositoryId, 'repo_001');
  });
}
