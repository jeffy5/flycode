import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clipboard/clipboard.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../l10n/l10n.dart';
import '../../service/api/session_api.dart';
import '../../service/api/command_api.dart';
import '../../service/api/file_api.dart';
import '../../service/api/models/prompt_input.dart';
import '../../service/api/models/command_input.dart';
import '../../service/api/models/command.dart';
import '../../providers/agent_provider.dart';
import '../../providers/chat_view_state_provider.dart';
import '../../providers/chat_config_provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/current_directory_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/session_status_provider.dart';
import '../../providers/session_unread_provider.dart';
import '../../providers/model_variant_provider.dart';
import '../../service/api/models/agent.dart';
import '../../service/api/models/provider.dart';
import '../../service/api/models/permission.dart';
import '../../service/api/models/session.dart';
import '../../service/api/models/session_status.dart';
import '../../theme/app_tokens.dart';
import 'at_mention_controller.dart';
import 'chat_command_popup.dart';
import 'model_selection_sheet.dart';

class _ImageAttachment {
  final String path;
  final String filename;

  const _ImageAttachment({required this.path, required this.filename});
}

enum _InputMode { chat, shell }

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key, this.commandPanelController});

  final CommandPanelController? commandPanelController;

  @override
  ConsumerState<ChatInput> createState() => ChatInputState();
}

class ChatInputState extends ConsumerState<ChatInput> {
  final AtMentionController _controller = AtMentionController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isHandlingPaste = false;

  /// True while an abort request has been sent and we are waiting for the
  /// backend to confirm the session is idle (via SSE session.status event).
  bool _isAborting = false;

  _InputMode _inputMode = _InputMode.chat;
  final List<_ImageAttachment> _attachments = [];

  // ─── @ file mention state ─────────────────────────────────────────
  OverlayEntry? _atFileOverlay;
  String _atFilter = '';
  List<String> _atSearchResults = [];
  int _atHighlightIndex = 0;
  Timer? _atDebounceTimer;
  // Position of the `@` character that triggered the current search.
  int _atTriggerStart = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.onKeyEvent = _handleKeyEvent;
  }

  // ─── 命令检测逻辑 ─────────────────────────────────────────────

  void _onTextChanged() {
    // Sync pills first — remove stale ones after any edit.
    _controller.syncPills();

    _syncInputModeByBangPrefix(_controller.text);

    if (_inputMode == _InputMode.shell) {
      _hideCommandPanel();
      _hideAtFileOverlay();
      return;
    }

    final text = _controller.text;
    final sel = _controller.selection;
    final cursorPos = sel.isCollapsed ? sel.baseOffset : -1;

    // ── @ file mention detection ──
    if (cursorPos > 0) {
      final textBefore = text.substring(0, cursorPos);
      final atMatch = RegExp(r'@(\S*)$').firstMatch(textBefore);
      if (atMatch != null) {
        final filter = atMatch.group(1)!;
        final atStart = atMatch.start;
        // Only show overlay if we are not inside a pill.
        if (_controller.pillAt(atStart) == null) {
          _atTriggerStart = atStart;
          if (filter != _atFilter) {
            _atFilter = filter;
            _atHighlightIndex = 0;
            _triggerAtSearch(filter);
          }
          if (_atFileOverlay == null && _atSearchResults.isNotEmpty) {
            _showAtFileOverlay();
          }
          // ── @ overlay is active; skip command detection ──
          _hideCommandPanel();
          return;
        }
      }
    }

    // No @ match — hide the file overlay.
    _hideAtFileOverlay();
    _atTriggerStart = -1;
    _atFilter = '';

    // ── Command autocomplete ──
    if (!text.startsWith('/') || text.contains(' ')) {
      _hideCommandPanel();
      return;
    }

    final query = text.substring(1);
    final commands = ref.read(commandsProvider).asData?.value ?? [];
    final filtered = commands.where((c) => c.name.startsWith(query)).toList();

    if (filtered.isEmpty) {
      _hideCommandPanel();
    } else {
      final panelController = widget.commandPanelController;
      if (panelController == null) {
        return;
      }
      if (!panelController.visible) {
        panelController.show(filtered, query: query);
      } else {
        panelController.update(filtered, query: query);
      }
    }
  }

  /// Debounced search via GET /find/file.
  void _triggerAtSearch(String filter) {
    _atDebounceTimer?.cancel();
    _atDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final fileApi = await ref.read(fileApiProvider.future);
        final results = await fileApi.findFile(filter, dirs: true, limit: 10);
        if (!mounted) return;
        setState(() {
          _atSearchResults = results;
          _atHighlightIndex = 0;
        });
        if (_atFileOverlay == null && results.isNotEmpty) {
          _showAtFileOverlay();
        } else {
          _atFileOverlay?.markNeedsBuild();
          // Hide overlay if no results.
          if (results.isEmpty) _hideAtFileOverlay();
        }
      } catch (_) {
        // Silently ignore search errors.
      }
    });
  }

  /// 从输入文本解析匹配的命令，返回 null 表示非命令或命令不存在。
  Command? _parseCommand(String text) {
    if (!text.startsWith('/')) return null;
    final afterSlash = text.substring(1);
    final spaceIdx = afterSlash.indexOf(' ');
    final cmdName = spaceIdx == -1
        ? afterSlash
        : afterSlash.substring(0, spaceIdx);
    if (cmdName.isEmpty) return null;
    final commands = ref.read(commandsProvider).asData?.value ?? [];
    try {
      return commands.firstWhere((c) => c.name == cmdName);
    } on StateError {
      return null;
    }
  }

  void _hideCommandPanel() {
    widget.commandPanelController?.hide();
  }

  void insertCommand(Command command) {
    _hideCommandPanel();
    _controller.value = TextEditingValue(
      text: '/${command.name} ',
      selection: TextSelection.collapsed(offset: 1 + command.name.length + 1),
    );
  }

  void focusInput() {
    _focusNode.requestFocus();
  }

  // ─── @ File Overlay ───────────────────────────────────────────────

  void _showAtFileOverlay() {
    if (_atFileOverlay != null) return;
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const horizontalPadding = 12.0;
    final overlayWidth = screenWidth - horizontalPadding * 2;
    final maxHeight = screenHeight * 0.4;

    final renderBox = context.findRenderObject() as RenderBox?;
    final boxOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final bottomY = boxOffset.dy - 4;

    _atFileOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: horizontalPadding,
        bottom: screenHeight - bottomY,
        width: overlayWidth,
        child: _AtFileSuggestionList(
          results: _atSearchResults,
          highlightIndex: _atHighlightIndex,
          maxHeight: maxHeight,
          onSelect: _onFileSelected,
        ),
      ),
    );
    overlay.insert(_atFileOverlay!);
  }

  void _hideAtFileOverlay() {
    _atFileOverlay?.remove();
    _atFileOverlay = null;
  }

  void _onFileSelected(String relativePath) {
    _hideAtFileOverlay();
    final sel = _controller.selection;
    final cursorPos = sel.isCollapsed
        ? sel.baseOffset
        : _controller.text.length;
    _controller.insertPill(relativePath, _atTriggerStart, cursorPos);
    _atTriggerStart = -1;
    _atFilter = '';
    _atSearchResults = [];
    _focusNode.requestFocus();
  }

  /// Move highlight up or down in the @ file overlay.
  void _moveAtHighlight(int delta) {
    if (_atSearchResults.isEmpty) return;
    setState(() {
      _atHighlightIndex = (_atHighlightIndex + delta).clamp(
        0,
        _atSearchResults.length - 1,
      );
    });
    _atFileOverlay?.markNeedsBuild();
  }

  /// Confirm the current highlight in the @ file overlay.
  void _confirmAtHighlight() {
    if (_atSearchResults.isEmpty) return;
    _onFileSelected(_atSearchResults[_atHighlightIndex]);
  }

  // ─── Keyboard handling ────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isPasteShortcut =
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed);
    if (isPasteShortcut) {
      unawaited(_handlePasteShortcut());
      return KeyEventResult.handled;
    }

    // @ file overlay navigation.
    if (_atFileOverlay != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveAtHighlight(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveAtHighlight(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        _confirmAtHighlight();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideAtFileOverlay();
        return KeyEventResult.handled;
      }
    }

    // Backspace: delete pill atomically.
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controller.tryDeletePillBeforeCursor()) {
        return KeyEventResult.handled;
      }
    }

    // Enter to send on desktop/web; keep mobile IME enter as newline.
    if (_shouldSendOnEnter(event)) {
      unawaited(_handleSend());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _shouldSendOnEnter(KeyEvent event) {
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter) return false;

    final platform = defaultTargetPlatform;
    final isMobilePlatform =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    if (isMobilePlatform) return false;

    if (HardwareKeyboard.instance.isShiftPressed) return false;
    return true;
  }

  Future<void> _handlePasteShortcut() async {
    if (_isHandlingPaste) return;
    _isHandlingPaste = true;
    try {
      if (_inputMode != _InputMode.shell) {
        final imageBytes = await FlutterClipboard.pasteImage();
        if (imageBytes != null && imageBytes.isNotEmpty) {
          final attachment = await _attachmentFromClipboardImage(imageBytes);
          if (!mounted) return;
          setState(() {
            _attachments.add(attachment);
          });
          return;
        }
      }

      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final pastedText = clipboardData?.text;
      if (pastedText == null || pastedText.isEmpty) return;
      _insertTextAtSelection(pastedText);
    } catch (_) {
      // Ignore paste failures to avoid interrupting typing.
    } finally {
      _isHandlingPaste = false;
    }
  }

  Future<_ImageAttachment> _attachmentFromClipboardImage(
    Uint8List imageBytes,
  ) async {
    final mimeType = lookupMimeType('clipboard-image', headerBytes: imageBytes);
    final ext = _fileExtForImageMime(mimeType);
    final filename =
        'pasted-image-${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '${Directory.systemTemp.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(imageBytes, flush: true);
    return _ImageAttachment(path: path, filename: filename);
  }

  String _fileExtForImageMime(String? mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      case 'image/heic':
        return 'heic';
      case 'image/heif':
        return 'heif';
      default:
        return 'png';
    }
  }

  void _insertTextAtSelection(String value) {
    final editingValue = _controller.value;
    final selection = editingValue.selection;
    final text = editingValue.text;

    if (!selection.isValid) {
      final nextText = '$text$value';
      _controller.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final nextText = text.replaceRange(start, end, value);
    final cursorOffset = start + value.length;

    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  void _syncInputModeByBangPrefix(String text) {
    final shouldShellMode = text.startsWith('!');
    final nextMode = shouldShellMode ? _InputMode.shell : _InputMode.chat;
    _setInputMode(nextMode);
  }

  String _normalizeShellCommand(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('!')) {
      return trimmed;
    }
    return trimmed.substring(1).trimLeft();
  }

  // ─── 图片附件 ─────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage();
      if (files.isEmpty) return;

      final nextAttachments = files
          .map((file) => _ImageAttachment(path: file.path, filename: file.name))
          .toList(growable: false);

      if (!mounted || nextAttachments.isEmpty) return;
      setState(() {
        _attachments.addAll(nextAttachments);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.chatInputPickImageFailed(e.toString())),
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _showImagePreview(BuildContext context, _ImageAttachment attachment) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.colorScheme.scrim,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  File(attachment.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 发送逻辑 ─────────────────────────────────────────────────

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final isShellMode = _inputMode == _InputMode.shell;
    final shellCommand = isShellMode ? _normalizeShellCommand(text) : text;
    if (isShellMode && shellCommand.isEmpty) return;
    if (!isShellMode && text.isEmpty && _attachments.isEmpty) return;
    if (_isLoading) return;

    final chatState = ref.read(chatViewStateProvider);
    if (chatState.sessionId == null && !chatState.isPending) return;

    setState(() => _isLoading = true);

    try {
      final api = await ref.read(sessionApiProvider.future);
      final directory = ref.read(currentDirectoryProvider);
      final chatConfig = ref.read(chatConfigProvider);
      final variant = ref.read(modelVariantProvider).current;

      final sessionId = await _ensureSession(api, directory, chatState);
      if (sessionId == null) return;

      if (isShellMode) {
        await _dispatchShell(
          api,
          sessionId,
          directory,
          chatConfig,
          shellCommand,
          variant,
        );
      } else {
        final matchedCommand = _parseCommand(text);
        if (matchedCommand != null) {
          await _dispatchCommand(
            api,
            sessionId,
            directory,
            chatConfig,
            variant,
            matchedCommand,
            text,
          );
        } else {
          await _dispatchPrompt(api, sessionId, directory, chatConfig, variant);
        }
      }

      setState(() {
        _controller.clear();
        _controller.pills.clear();
        _attachments.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.chatInputSendError(e.toString())),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Sends an abort request to the backend for the current session.
  Future<void> _handleAbort() async {
    if (_isAborting) return;
    final sessionId = ref.read(chatViewStateProvider).sessionId;
    if (sessionId == null) return;

    setState(() => _isAborting = true);

    try {
      final api = await ref.read(sessionApiProvider.future);
      final directory = ref.read(currentDirectoryProvider);
      await api.abortSession(sessionId, directory: directory);
    } catch (e) {
      if (mounted) {
        setState(() => _isAborting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.chatInputAbortFailed(e.toString())),
          ),
        );
      }
    }
  }

  Future<String?> _ensureSession(
    SessionApi api,
    String? directory,
    ChatViewState chatState,
  ) async {
    var sessionId = chatState.sessionId;
    if (sessionId == null && chatState.isPending) {
      final session = await api.createSession(directory: directory);
      sessionId = session.id;
      ref.read(chatViewStateProvider.notifier).selectSessionId(sessionId);
      ref.invalidate(sessionsProvider);
    }
    return sessionId;
  }

  Future<void> _dispatchCommand(
    SessionApi api,
    String sessionId,
    String? directory,
    ChatConfig chatConfig,
    String? variant,
    Command matchedCommand,
    String text,
  ) async {
    final afterSlash = text.substring(1);
    final spaceIdx = afterSlash.indexOf(' ');
    final arguments = spaceIdx == -1
        ? ''
        : afterSlash.substring(spaceIdx + 1).trim();

    final modelStr =
        '${chatConfig.model.providerID}/${chatConfig.model.modelID}';

    await api.sendCommand(
      sessionId,
      directory: directory,
      data: CommandInput(
        command: matchedCommand.name,
        arguments: arguments,
        model: modelStr,
        agent: chatConfig.agent,
        variant: variant,
      ),
    );
  }

  Future<void> _dispatchShell(
    SessionApi api,
    String sessionId,
    String? directory,
    ChatConfig chatConfig,
    String command,
    String? variant,
  ) async {
    await api.runShell(
      sessionId,
      directory: directory,
      data: {
        'agent': chatConfig.agent,
        'command': command,
        'model': {
          'providerID': chatConfig.model.providerID,
          'modelID': chatConfig.model.modelID,
        },
        'variant': ?variant,
      },
    );
  }

  Future<void> _dispatchPrompt(
    SessionApi api,
    String sessionId,
    String? directory,
    ChatConfig chatConfig,
    String? variant,
  ) async {
    final text = _controller.text;
    final rootDir = directory ?? '';

    // Build file parts from @ pills.
    final fileParts = _controller.pills.map((pill) {
      final rel = pill.path;
      final absPath = rootDir.isNotEmpty
          ? '$rootDir/$rel'.replaceAll('//', '/')
          : rel;
      return FilePartInput(
        mime: 'text/plain',
        url: 'file://$absPath',
        filename: rel.split('/').last,
        source: {
          'type': 'file',
          'path': absPath,
          'text': {
            'value': pill.displayText,
            'start': pill.start,
            'end': pill.end,
          },
        },
      );
    }).toList();

    final attachmentParts = await _buildAttachmentParts();

    final List<Object> parts = [
      if (text.isNotEmpty) TextPartInput(text: text),
      ...fileParts,
      ...attachmentParts,
    ];

    await api.sendPromptAsync(
      sessionId,
      directory: directory,
      data: PromptAsyncInput(
        agent: chatConfig.agent,
        model: chatConfig.model,
        variant: variant,
        parts: parts,
      ),
    );
  }

  Future<List<FilePartInput>> _buildAttachmentParts() async {
    final parts = <FilePartInput>[];
    for (final attachment in _attachments) {
      final bytes = await XFile(attachment.path).readAsBytes();
      final mimeType =
          lookupMimeType(attachment.path, headerBytes: bytes) ?? 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      parts.add(
        FilePartInput(
          mime: mimeType,
          filename: attachment.filename,
          url: dataUrl,
        ),
      );
    }
    return parts;
  }

  // ─── Agent / Model 切换 ───────────────────────────────────────

  /// Cycles through agents when there are ≤ 3, otherwise shows the selector.
  void _handleAgentTap(List<Agent> agents) {
    if (agents.isEmpty) return;
    if (agents.length <= 3) {
      _cycleAgent(agents);
    } else {
      _showAgentSelector(agents);
    }
  }

  /// Cycles to the next agent in the list (wraps around).
  void _cycleAgent(List<Agent> agents) {
    final current = ref.read(chatConfigProvider).agent;
    final idx = agents.indexWhere((a) => a.name == current);
    final nextIdx = (idx + 1) % agents.length;
    final next = agents[nextIdx];
    ref
        .read(chatConfigProvider.notifier)
        .setAgent(next.name, linkedModel: next.model);
  }

  /// Shows a bottom sheet for selecting an agent (used when > 3 agents).
  void _showAgentSelector(List<Agent> agents) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      builder: (context) => _AgentSelectionSheet(
        agents: agents,
        currentAgent: ref.read(chatConfigProvider).agent,
        onSelect: (agent) {
          ref
              .read(chatConfigProvider.notifier)
              .setAgent(agent.name, linkedModel: agent.model);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      builder: (context) => const ModelSelectionSheet(),
    );
  }

  void _showVariantSelector(ModelVariantState variantState) {
    if (variantState.available.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      builder: (context) => _VariantSelectionSheet(
        variants: variantState.available,
        current: variantState.current,
        onSelect: (variant) {
          ref
              .read(modelVariantProvider.notifier)
              .setSelectedForCurrentModel(variant);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _setInputMode(_InputMode mode) {
    if (_inputMode == mode) return;
    setState(() {
      _inputMode = mode;
      if (mode == _InputMode.shell) {
        _attachments.clear();
      }
    });
    _hideCommandPanel();
    _hideAtFileOverlay();
  }

  void _startPendingSession() {
    ref.read(chatViewStateProvider.notifier).startNew();
  }

  Future<void> _showSessionHistorySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0),
      builder: (_) => _SessionHistorySheet(
        onSelectSession: (session) {
          ref.read(chatViewStateProvider.notifier).selectSessionId(session.id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatConfig = ref.watch(chatConfigProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isShellMode = _inputMode == _InputMode.shell;
    final providerList = ref.watch(providerListProvider).asData?.value;
    final variantState = ref.watch(modelVariantProvider);
    ref.watch(commandsProvider);

    final modelLabel = _resolveModelLabel(providerList, chatConfig);

    final sessionId = ref.watch(
      chatViewStateProvider.select((s) => s.sessionId),
    );
    final sessionStatuses = ref.watch(sessionStatusProvider);
    final isWorking =
        sessionId != null && (sessionStatuses[sessionId]?.isWorking ?? false);

    // Reconcile status snapshot on session switch to recover from missed SSE.
    ref.listen<String?>(chatViewStateProvider.select((s) => s.sessionId), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      unawaited(ref.read(sessionStatusProvider.notifier).refreshFromServer());
    });

    // Clear _isAborting once the backend confirms idle via SSE.
    ref.listen<Map<String, SessionStatus>>(sessionStatusProvider, (
      _,
      statuses,
    ) {
      if (!_isAborting) return;
      final sid = sessionId;
      if (sid == null) return;
      final status = statuses[sid];
      if (status == null || status is SessionStatusIdle) {
        setState(() => _isAborting = false);
      }
    });

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: tokens.border.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConfigToolBar(
              chatConfig: chatConfig,
              modelLabel: modelLabel,
              showVariantSelector: variantState.available.isNotEmpty,
              variantLabel: _formatVariantLabel(variantState.current),
              agents: ref.watch(agentsProvider).asData?.value ?? const [],
              onAgentTap: _handleAgentTap,
              onShowModelSelector: _showModelSelector,
              onShowVariantSelector: () => _showVariantSelector(variantState),
              onCycleVariant: () {
                ref.read(modelVariantProvider.notifier).cycleForCurrentModel();
              },
              onShowSessionHistory: _showSessionHistorySheet,
              onStartNewSession: _startPendingSession,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: tokens.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isShellMode && _attachments.isNotEmpty)
                    _AttachmentList(
                      attachments: _attachments,
                      onRemove: _removeAttachment,
                      onPreview: (att) => _showImagePreview(context, att),
                    ),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    maxLines: 5,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: isShellMode ? 'monospace' : null,
                    ),
                    decoration: InputDecoration(
                      hintText: isShellMode
                          ? context.l10n.chatInputShellHint
                          : context.l10n.chatInputAskHint,
                      hintStyle: TextStyle(
                        color: tokens.mutedForeground,
                        fontSize: 14,
                        fontFamily: isShellMode ? 'monospace' : null,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                  _InputToolBar(
                    isLoading: _isLoading,
                    isWorking: isWorking,
                    isAborting: _isAborting,
                    isShellMode: isShellMode,
                    onPickImage: _pickImage,
                    onSend: _handleSend,
                    onAbort: _handleAbort,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveModelLabel(
    ProviderListResponse? providerList,
    ChatConfig chatConfig,
  ) {
    if (providerList == null) {
      return chatConfig.model.modelID;
    }
    for (final provider in providerList.all) {
      if (provider.id != chatConfig.model.providerID) {
        continue;
      }
      final model = provider.models[chatConfig.model.modelID];
      if (model != null && model.name.isNotEmpty) {
        return model.name;
      }
    }
    return chatConfig.model.modelID;
  }

  String _formatVariantLabel(String? variant) {
    if (variant == null || variant.isEmpty) return 'Default';
    return '${variant[0].toUpperCase()}${variant.substring(1)}';
  }

  @override
  void dispose() {
    _hideCommandPanel();
    _hideAtFileOverlay();
    _atDebounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

// ─── UI 子组件 ─────────────────────────────────────────────────────

class _AttachmentList extends StatelessWidget {
  final List<_ImageAttachment> attachments;
  final ValueChanged<int> onRemove;
  final ValueChanged<_ImageAttachment> onPreview;

  const _AttachmentList({
    required this.attachments,
    required this.onRemove,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.only(right: 8),
          itemCount: attachments.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, i) {
            final att = attachments[i];
            return RepaintBoundary(
              key: ValueKey(att.path),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => onPreview(att),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(att.path),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 64,
                                  height: 64,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 18,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onRemove(i),
                          borderRadius: BorderRadius.circular(9),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.scrim.withValues(
                                alpha: 0.72,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputToolBar extends StatelessWidget {
  final bool isLoading;
  final bool isWorking;
  final bool isAborting;
  final bool isShellMode;
  final VoidCallback onPickImage;
  final VoidCallback onSend;
  final VoidCallback onAbort;

  const _InputToolBar({
    required this.isLoading,
    required this.isWorking,
    required this.isAborting,
    required this.isShellMode,
    required this.onPickImage,
    required this.onSend,
    required this.onAbort,
  });

  @override
  Widget build(BuildContext context) {
    final bool showStop = isWorking || isAborting;
    final bool actionDisabled = isAborting || isLoading;
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Row(
        children: [
          Text(
            isShellMode ? r'$' : '>>',
            style: TextStyle(
              color: tokens.successForeground,
              fontWeight: FontWeight.bold,
              fontFamily: isShellMode ? 'monospace' : null,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isShellMode)
                InkWell(
                  onTap: (isLoading || isWorking) ? null : onPickImage,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: (isLoading || isWorking)
                          ? tokens.mutedForeground.withValues(alpha: 0.5)
                          : tokens.mutedForeground,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: actionDisabled ? null : (showStop ? onAbort : onSend),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: showStop
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLoading || isAborting)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        )
                      else
                        Icon(
                          showStop ? Icons.stop_rounded : Icons.arrow_upward,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigToolBar extends StatelessWidget {
  final ChatConfig chatConfig;
  final String modelLabel;
  final bool showVariantSelector;
  final String variantLabel;
  final List<Agent> agents;
  final ValueChanged<List<Agent>> onAgentTap;
  final VoidCallback onShowModelSelector;
  final VoidCallback onShowVariantSelector;
  final VoidCallback onCycleVariant;
  final VoidCallback onShowSessionHistory;
  final VoidCallback onStartNewSession;

  const _ConfigToolBar({
    required this.chatConfig,
    required this.modelLabel,
    required this.showVariantSelector,
    required this.variantLabel,
    required this.agents,
    required this.onAgentTap,
    required this.onShowModelSelector,
    required this.onShowVariantSelector,
    required this.onCycleVariant,
    required this.onShowSessionHistory,
    required this.onStartNewSession,
  });

  String get _agentLabel {
    final name = chatConfig.agent;
    if (name.isEmpty) return 'Agent';
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SelectionChip(
                  onTap: agents.isNotEmpty ? () => onAgentTap(agents) : null,
                  label: _agentLabel,
                ),
                const SizedBox(width: 8),
                _SelectionChip(onTap: onShowModelSelector, label: modelLabel),
                if (showVariantSelector) ...[
                  const SizedBox(width: 8),
                  _SelectionChip(
                    onTap: onShowVariantSelector,
                    onLongPress: onCycleVariant,
                    label: variantLabel,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onShowSessionHistory,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.history,
                  size: 19,
                  color: tokens.mutedForeground,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onStartNewSession,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 19, color: tokens.mutedForeground),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _SelectionChip({required this.label, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SessionListBadgeKind { none, working, permission, error, unread }

class _SessionHistorySheet extends ConsumerWidget {
  final ValueChanged<Session> onSelectSession;

  const _SessionHistorySheet({required this.onSelectSession});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final selectedSessionId = ref.watch(chatViewStateProvider).sessionId;
    final sessionStatuses = ref.watch(sessionStatusProvider);
    final unreadState = ref.watch(sessionUnreadProvider);
    final pendingPermissions =
        ref.watch(pendingPermissionsProvider).asData?.value ??
        const <PermissionRequest>[];
    final allSessions =
        ref.watch(allSessionsProvider).asData?.value ?? const <Session>[];
    final theme = Theme.of(context);
    final tokens = context.tokens;

    bool hasPendingPermission(String sessionID) {
      if (pendingPermissions.isEmpty) return false;
      final subtree = collectSessionTree(sessionID, allSessions);
      for (final request in pendingPermissions) {
        if (subtree.contains(request.sessionID)) {
          return true;
        }
      }
      return false;
    }

    _SessionListBadgeKind resolveBadgeKind(String sessionID) {
      final status = sessionStatuses[sessionID];
      if (status != null && status.isWorking) {
        return _SessionListBadgeKind.working;
      }
      if (hasPendingPermission(sessionID)) {
        return _SessionListBadgeKind.permission;
      }
      if (unreadState.hasError(sessionID)) {
        return _SessionListBadgeKind.error;
      }
      if (unreadState.unseenCount(sessionID) > 0) {
        return _SessionListBadgeKind.unread;
      }
      return _SessionListBadgeKind.none;
    }

    Widget buildStatusBadge(_SessionListBadgeKind kind) {
      switch (kind) {
        case _SessionListBadgeKind.working:
          return SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: tokens.successForeground,
            ),
          );
        case _SessionListBadgeKind.permission:
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tokens.warningForeground,
              shape: BoxShape.circle,
            ),
          );
        case _SessionListBadgeKind.error:
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          );
        case _SessionListBadgeKind.unread:
          return Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          );
        case _SessionListBadgeKind.none:
          return const SizedBox.shrink();
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.73,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle row
            Container(
              height: 24,
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                ),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.pageHorizontalPadding,
                2,
                tokens.pageHorizontalPadding,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.chatInputSessionHistory,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Divider
            Divider(height: 1, thickness: 1, color: tokens.border),

            // List
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.mutedForeground),
                    ),
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.chatInputNoSessions,
                        style: TextStyle(color: tokens.mutedForeground),
                      ),
                    );
                  }

                  final grouped = _groupSessionsByDateForHistory(sessions);
                  final dates = grouped.keys.toList();

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      tokens.pageHorizontalPadding,
                      12,
                      tokens.pageHorizontalPadding,
                      20,
                    ),
                    itemCount: dates.length,
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      final sessionsForDate = grouped[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 0 : 16,
                              bottom: 8,
                            ),
                            child: Text(
                              _formatDateHeaderForHistory(context, date),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.mutedForeground,
                              ),
                            ),
                          ),
                          ...sessionsForDate.map((session) {
                            final isSelected = selectedSessionId == session.id;
                            final badgeKind = resolveBadgeKind(session.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Material(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () => onSelectSession(session),
                                  borderRadius: BorderRadius.circular(14),
                                  hoverColor: tokens.accent,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                session.title ?? session.id,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .primary
                                                      : theme
                                                            .colorScheme
                                                            .onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatUpdatedTimeForHistory(
                                                  context,
                                                  session.updatedAt,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: tokens.mutedForeground,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (badgeKind !=
                                            _SessionListBadgeKind.none) ...[
                                          const SizedBox(width: 8),
                                          buildStatusBadge(badgeKind),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<Session>> _groupSessionsByDateForHistory(
  List<Session> sessions,
) {
  final grouped = <String, List<Session>>{};
  final sortedSessions = List<Session>.from(sessions)
    ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

  for (final session in sortedSessions) {
    final dateKey = _getDateKeyForHistory(session.updatedAt);
    grouped.putIfAbsent(dateKey, () => []).add(session);
  }

  return grouped;
}

String _getDateKeyForHistory(int? timestamp) {
  if (timestamp == null || timestamp == 0) {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDateHeaderForHistory(BuildContext context, String dateKey) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  DateTime parseDate(String key) {
    final parts = key.split('-');
    if (parts.length < 3) return today;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final date = parseDate(dateKey);
  if (date == today) return context.l10n.chatInputToday;
  if (date == yesterday) return context.l10n.chatInputYesterday;

  final parts = dateKey.split('-');
  if (parts.length < 3) return dateKey;

  final month = int.tryParse(parts[1]) ?? 1;
  final day = int.tryParse(parts[2]) ?? 1;
  return context.l10n.chatInputMonthDay(month, day);
}

String _formatUpdatedTimeForHistory(BuildContext context, int? timestampMs) {
  if (timestampMs == null || timestampMs == 0) {
    return context.l10n.chatInputJustNow;
  }

  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return context.l10n.chatInputJustNow;
  if (diff.inMinutes < 60) {
    return context.l10n.chatInputMinutesAgo(diff.inMinutes);
  }
  if (diff.inHours < 24) return context.l10n.chatInputHoursAgo(diff.inHours);
  if (diff.inDays < 7) return context.l10n.chatInputDaysAgo(diff.inDays);

  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  if (dt.year == now.year) return '$m-$d';
  return '$y-$m-$d';
}

class _VariantSelectionSheet extends StatelessWidget {
  final List<String> variants;
  final String? current;
  final ValueChanged<String?> onSelect;

  const _VariantSelectionSheet({
    required this.variants,
    required this.current,
    required this.onSelect,
  });

  String _labelFor(String? value) {
    if (value == null || value.isEmpty) return 'Default';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final options = <String?>[null, ...variants];
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusM + 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.pageHorizontalPadding,
                6,
                10,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.chatInputSelectVariant,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.5)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                itemCount: options.length,
                itemBuilder: (ctx, i) {
                  final value = options[i];
                  final selected = current == value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(tokens.radiusM),
                      child: InkWell(
                        onTap: () => onSelect(value),
                        borderRadius: BorderRadius.circular(tokens.radiusM),
                        splashColor: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        highlightColor: theme.colorScheme.primary.withValues(
                          alpha: 0.05,
                        ),
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _labelFor(value),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Agent 选择底部弹窗（> 3 个 agent 时使用）────────────────────

class _AgentSelectionSheet extends StatelessWidget {
  final List<Agent> agents;
  final String currentAgent;
  final ValueChanged<Agent> onSelect;

  const _AgentSelectionSheet({
    required this.agents,
    required this.currentAgent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示条
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                context.l10n.chatInputSelectAgent,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: agents.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: tokens.border.withValues(alpha: 0.4),
              ),
              itemBuilder: (ctx, i) {
                final agent = agents[i];
                final isSelected = agent.name == currentAgent;
                final label = agent.name.isNotEmpty
                    ? '${agent.name[0].toUpperCase()}${agent.name.substring(1)}'
                    : agent.name;
                return InkWell(
                  onTap: () => onSelect(agent),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // 颜色圆点（如果有 color 字段）
                        if (agent.color != null) ...[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (agent.description != null &&
                                  agent.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    agent.description!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.mutedForeground,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── @ 文件建议列表 Widget ────────────────────────────────────────

class _AtFileSuggestionList extends StatelessWidget {
  final List<String> results;
  final int highlightIndex;
  final double maxHeight;
  final ValueChanged<String> onSelect;

  const _AtFileSuggestionList({
    required this.results,
    required this.highlightIndex,
    required this.maxHeight,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: tokens.border.withValues(alpha: 0.4)),
          itemBuilder: (ctx, i) {
            final path = results[i];
            final isHighlighted = i == highlightIndex;
            final filename = path.split('/').last;
            final dir = path.contains('/')
                ? path.substring(0, path.lastIndexOf('/'))
                : null;

            return GestureDetector(
              // Use onTapDown + onTap to avoid defocusing the text field.
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(path),
              child: Container(
                color: isHighlighted
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surface.withValues(alpha: 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 16,
                      color: isHighlighted
                          ? theme.colorScheme.primary
                          : tokens.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: filename,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isHighlighted
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            if (dir != null)
                              TextSpan(
                                text: '  $dir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
