import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../core/engines/static_engine.dart';
import '../../core/models/project.dart';
import '../../core/services/port_manager.dart';
import '../../core/services/project_manager.dart';
import '../editor/editor_panel.dart';
import '../editor/syntax_highlighting_controller.dart';
import '../preview/preview_panel.dart';

enum _MenuAction { open, saveAs, reset, logs, settings }

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  static const List<String> _files = ['index.html', 'styles.css', 'script.js'];

  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36';

  final ProjectManager _projectManager = ProjectManager();
  final PortManager _portManager = const PortManager();
  final StaticEngine _engine = StaticEngine();
  final Map<String, SyntaxHighlightingController> _controllers = {};
  final List<String> _logs = [];

  StreamSubscription<String>? _logSubscription;
  Timer? _saveDebounce;
  WebViewController? _webController;
  Project? _project;
  Orientation? _orientation;
  String _selectedFile = 'index.html';
  String? _error;
  int _progress = 0;
  bool _loading = true;
  bool _busy = false;
  bool _fullscreen = false;
  double _fontSize = 14;
  int _indentSize = 2;
  bool _wrap = true;

  TextEditingController get _activeController => _controllers[_selectedFile]!;

  SyntaxLanguage _languageFor(String file) {
    if (file.endsWith('.css')) return SyntaxLanguage.css;
    if (file.endsWith('.js')) return SyntaxLanguage.javascript;
    return SyntaxLanguage.html;
  }

  @override
  void initState() {
    super.initState();
    _logSubscription = _engine.logs.listen((line) {
      if (!mounted) return;
      setState(() {
        _logs.add(line);
        if (_logs.length > 200) _logs.removeAt(0);
      });
    });
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    if (orientation == _orientation) return;

    final hadOrientation = _orientation != null;
    _orientation = orientation;
    if (hadOrientation) {
      unawaited(_handleOrientationChange(orientation));
    }
  }

  Future<void> _handleOrientationChange(Orientation orientation) async {
    await _applyDesktopMode(orientation == Orientation.landscape);
    if (!mounted) return;
    await _webController?.reload();
  }

  Future<void> _applyDesktopMode(
    bool desktop, {
    WebViewController? controller,
  }) async {
    final target = controller ?? _webController;
    if (target == null) return;

    final platform = target.platform;
    if (platform is AndroidWebViewController) {
      await platform.setUseWideViewPort(desktop);
    }
    await target.setUserAgent(desktop ? _desktopUserAgent : null);
  }

  Future<void> _initialize() async {
    try {
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();

      final project = await _projectManager.openWorkspace();
      for (final file in _files) {
        _controllers[file] = SyntaxHighlightingController(
          language: _languageFor(file),
          text: await _projectManager.readFile(file),
        );
      }

      await _startServer(project);
      final url = _engine.url!;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFFFFFFF))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _progress = progress);
            },
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() => _error = null);
            },
            onWebResourceError: (webError) {
              if (!mounted) return;
              setState(() => _error = webError.description);
            },
          ),
        );
      await _applyDesktopMode(
        _orientation == Orientation.landscape,
        controller: controller,
      );
      await controller.loadRequest(Uri.parse(url));

      if (!mounted) return;
      setState(() {
        _project = project;
        _webController = controller;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _handleEditorChanged(String value) {
    final file = _selectedFile;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 450), () async {
      await _projectManager.writeFile(file, value);
      if (!mounted) return;
      _webController?.reload();
    });
  }

  Future<void> _selectFile(String file) async {
    if (file == _selectedFile) return;
    _saveDebounce?.cancel();
    await _projectManager.writeFile(_selectedFile, _activeController.text);
    if (!mounted) return;
    setState(() => _selectedFile = file);
  }

  Future<void> _startServer(Project project) async {
    final port = await _portManager.findAvailable(start: 8080);
    await _engine.start(project: project, port: port);
  }

  Future<void> _toggleServer() async {
    final project = _project;
    if (project == null || _busy) return;

    setState(() => _busy = true);
    try {
      if (_engine.isRunning) {
        await _engine.stop();
      } else {
        await _startServer(project);
        await _webController?.loadRequest(Uri.parse(_engine.url!));
      }
    } catch (error) {
      _showMessage('Server error: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
  }

  Future<void> _openFile() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Open file',
      type: FileType.custom,
      allowedExtensions: const ['html', 'htm', 'css', 'js'],
    );
    if (picked == null) return;

    final contents = utf8.decode(
      await picked.readAsBytes(),
      allowMalformed: true,
    );
    final target = switch (picked.extension?.toLowerCase()) {
      'css' => 'styles.css',
      'js' => 'script.js',
      _ => 'index.html',
    };

    await _projectManager.writeFile(target, contents);
    if (!mounted) return;
    setState(() {
      _controllers[target]!.text = contents;
      _selectedFile = target;
    });
    _webController?.reload();
  }

  Future<void> _saveAs() async {
    final contents = _activeController.text;
    await _projectManager.writeFile(_selectedFile, contents);
    final mimeType = switch (_selectedFile) {
      'styles.css' => 'text/css',
      'script.js' => 'text/javascript',
      _ => 'text/html',
    };
    await FilePicker.saveFile(
      dialogTitle: 'Save $_selectedFile',
      fileName: _selectedFile,
      mimeType: mimeType,
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );
  }

  Future<void> _resetTemplates() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset project?'),
        content: const Text(
          'This replaces index.html, styles.css and script.js with the '
          'default template.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _projectManager.resetTemplates();
    for (final file in _files) {
      _controllers[file]!.text = await _projectManager.readFile(file);
    }
    _webController?.reload();
  }

  void _showLogs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 320,
          child: _logs.isEmpty
              ? const Center(child: Text('No server logs yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _showSettings() async {
    var settings = _EditorSettings(
      fontSize: _fontSize,
      indentSize: _indentSize,
      wrap: _wrap,
    );
    final result = await showDialog<_EditorSettings>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editor settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Font size: ${settings.fontSize.round()}'),
                Slider(
                  value: settings.fontSize,
                  min: 11,
                  max: 32,
                  divisions: 21,
                  onChanged: (value) => setDialogState(
                    () => settings = settings.copyWith(fontSize: value),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Indent size'),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2 spaces')),
                    ButtonSegment(value: 4, label: Text('4 spaces')),
                  ],
                  selected: {settings.indentSize},
                  onSelectionChanged: (selection) => setDialogState(
                    () => settings = settings.copyWith(
                      indentSize: selection.first,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Text wrap'),
                  subtitle: const Text('Wrap long lines in the editor'),
                  value: settings.wrap,
                  onChanged: (value) => setDialogState(
                    () => settings = settings.copyWith(wrap: value),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, settings),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _fontSize = result.fontSize;
        _indentSize = result.indentSize;
        _wrap = result.wrap;
      });
    }
  }

  Future<void> _handleMenu(_MenuAction action) async {
    try {
      switch (action) {
        case _MenuAction.open:
          await _openFile();
        case _MenuAction.saveAs:
          await _saveAs();
        case _MenuAction.reset:
          await _resetTemplates();
        case _MenuAction.logs:
          _showLogs();
        case _MenuAction.settings:
          await _showSettings();
      }
    } catch (error) {
      _showMessage('Action failed: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _logSubscription?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = _project;

    return Scaffold(
      appBar: _fullscreen
          ? null
          : AppBar(
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project?.name ?? 'Kimmy Dev Server',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    _engine.url ?? 'Starting local server...',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Tooltip(
                    message: _engine.isRunning
                        ? 'Server running'
                        : 'Server stopped',
                    child: Icon(
                      _engine.isRunning ? Icons.circle : Icons.circle_outlined,
                      size: 12,
                      color: _engine.isRunning
                          ? Colors.greenAccent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _engine.isRunning ? 'Stop server' : 'Start server',
                  onPressed: _busy ? null : _toggleServer,
                  icon: Icon(
                    _engine.isRunning
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                  ),
                ),
                IconButton(
                  tooltip: 'Reload preview',
                  onPressed: () => _webController?.reload(),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Full screen preview',
                  onPressed: _toggleFullscreen,
                  icon: const Icon(Icons.fullscreen),
                ),
                PopupMenuButton<_MenuAction>(
                  onSelected: _handleMenu,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _MenuAction.open,
                      child: Text('Open file'),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.saveAs,
                      child: Text('Save as file'),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.reset,
                      child: Text('Reset to default'),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.logs,
                      child: Text('Server logs'),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.settings,
                      child: Text('Editor settings'),
                    ),
                  ],
                ),
              ],
            ),
      body: _fullscreen ? _buildFullscreenPreview() : _buildBody(),
    );
  }

  Widget _buildFullscreenPreview() {
    final controller = _webController;
    if (controller == null) {
      return _buildBody();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PreviewPanel(
            controller: controller,
            loadingProgress: _progress,
            error: _error,
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Reload preview',
                    onPressed: () => controller.reload(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Exit full screen',
                    onPressed: _toggleFullscreen,
                    icon: const Icon(Icons.fullscreen_exit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_webController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Could not start the local server.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _initialize();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final editor = EditorPanel(
          files: _files,
          selectedFile: _selectedFile,
          controller: _activeController,
          onFileSelected: _selectFile,
          onChanged: _handleEditorChanged,
          fontSize: _fontSize,
          indentSize: _indentSize,
          wrap: _wrap,
        );
        final preview = PreviewPanel(
          controller: _webController,
          loadingProgress: _progress,
          error: _error,
        );

        if (orientation == Orientation.portrait) {
          return Column(
            children: [
              Expanded(flex: 3, child: preview),
              const Divider(height: 1),
              Expanded(flex: 2, child: editor),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: editor),
            const VerticalDivider(width: 1),
            Expanded(flex: 3, child: preview),
          ],
        );
      },
    );
  }
}

class _EditorSettings {
  const _EditorSettings({
    required this.fontSize,
    required this.indentSize,
    required this.wrap,
  });

  final double fontSize;
  final int indentSize;
  final bool wrap;

  _EditorSettings copyWith({double? fontSize, int? indentSize, bool? wrap}) {
    return _EditorSettings(
      fontSize: fontSize ?? this.fontSize,
      indentSize: indentSize ?? this.indentSize,
      wrap: wrap ?? this.wrap,
    );
  }
}
