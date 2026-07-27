import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/database_helper.dart';
import '../service/api/models/message.dart' hide FileDiff;
import '../service/api/models/parts.dart';
import '../service/api/session_api.dart';
import '../service/api/models/session.dart';

part 'session_provider.g.dart';

final class MessageListStateReducer {
  const MessageListStateReducer._();

  static List<MessageWithParts> updateMessage(
    List<MessageWithParts> current,
    MessageWithParts message,
  ) {
    return _upsertMessage(current, message);
  }

  static List<MessageWithParts> removeMessage(
    List<MessageWithParts> current,
    String messageID,
  ) {
    return current
        .where((message) => _messageId(message) != messageID)
        .toList();
  }

  static List<MessageWithParts> updatePart(
    List<MessageWithParts> current,
    String messageID,
    Object newPart,
  ) {
    final msgIndex = current.indexWhere(
      (message) => _messageId(message) == messageID,
    );
    if (msgIndex < 0) return current;

    final message = current[msgIndex];
    final existingIndex = message.parts.indexWhere(
      (part) => partId(part) == partId(newPart),
    );

    final newParts = List<Object>.from(message.parts);
    if (existingIndex >= 0) {
      newParts[existingIndex] = newPart;
    } else {
      newParts.add(newPart);
    }

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = _messageWithNormalizedParts(message.info, newParts);
    return updated;
  }

  static List<MessageWithParts> removePart(
    List<MessageWithParts> current,
    String messageID,
    String partID,
  ) {
    final msgIndex = current.indexWhere(
      (message) => _messageId(message) == messageID,
    );
    if (msgIndex < 0) return current;

    final message = current[msgIndex];
    final newParts = message.parts
        .where((part) => partId(part) != partID)
        .toList();

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = _messageWithNormalizedParts(message.info, newParts);
    return updated;
  }

  static List<MessageWithParts> appendPartDelta(
    List<MessageWithParts> current,
    String sessionID,
    String messageID,
    String partID,
    String field,
    String delta,
  ) {
    if (field != 'text' || delta.isEmpty) return current;

    final msgIndex = current.indexWhere(
      (message) => _messageId(message) == messageID,
    );
    if (msgIndex < 0) return current;

    final message = current[msgIndex];
    final partIndex = message.parts.indexWhere(
      (part) => partId(part) == partID,
    );

    final newParts = List<Object>.from(message.parts);
    if (partIndex >= 0) {
      final part = message.parts[partIndex];
      if (part is! TextPart) return current;
      newParts[partIndex] = TextPart(
        id: part.id,
        sessionID: part.sessionID,
        messageID: part.messageID,
        type: part.type,
        text: '${part.text}$delta',
        synthetic: part.synthetic,
        ignored: part.ignored,
        time: part.time,
        metadata: part.metadata,
      );
    } else {
      newParts.add(
        TextPart(
          id: partID,
          sessionID: sessionID,
          messageID: messageID,
          type: 'text',
          text: delta,
        ),
      );
    }

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = _messageWithNormalizedParts(message.info, newParts);
    return updated;
  }
}

@riverpod
class SessionMessagesNotifier extends _$SessionMessagesNotifier {
  static const int _pageSize = 30;
  bool _hasMore = true;
  final Map<String, ValueNotifier<MessageWithParts>> _contentNotifiers = {};

  bool get hasMore => _hasMore;

  /// 获取某个消息的内容通知器，用于最小粒度刷新
  ValueNotifier<MessageWithParts> contentNotifier(String messageID) {
    return _contentNotifiers.putIfAbsent(
      messageID,
      () => ValueNotifier(_findMessage(messageID)),
    );
  }

  MessageWithParts _findMessage(String id) {
    final msgs = _currentMessages;
    final idx = msgs.indexWhere((m) => _messageId(m) == id);
    return idx >= 0 ? msgs[idx] : MessageWithParts(info: '', parts: const []);
  }

  @override
  Future<List<MessageWithParts>> build(String sessionID) async {
    ref.keepAlive();
    _hasMore = true;
    _contentNotifiers.clear();

    // 有缓存就不调 API，像微信一样
    final cached = await DatabaseHelper().loadSessionCache(sessionID);
    if (cached != null && cached.isNotEmpty) {
      final decoded = (jsonDecode(cached) as List)
          .map((e) => MessageWithParts.fromJson(e as Map<String, dynamic>))
          .toList();
      final normalized = _normalizeMessages(decoded);
      _hasMore = true;
      return normalized;
    }

    final api = await ref.watch(sessionApiProvider.future);
    final messages = await api.getSessionMessages(sessionID, limit: _pageSize);
    if (messages.length < _pageSize) _hasMore = false;
    final normalized = _normalizeMessages(messages);
    _saveCache(sessionID, normalized);
    return normalized;
  }

  /// 手动刷新（下拉/按钮触发）
  Future<void> refresh() async {
    final api = await ref.watch(sessionApiProvider.future);
    final messages = await api.getSessionMessages(sessionID, limit: _pageSize);
    if (messages.length < _pageSize) _hasMore = false;
    final normalized = _normalizeMessages(messages);
    _saveCache(sessionID, normalized);
    _setState(normalized);
  }

  Future<void> loadMore() async {
    final api = await ref.watch(sessionApiProvider.future);
    final current = _currentMessages;
    final newLimit = current.length + _pageSize;
    final messages = await api.getSessionMessages(sessionID, limit: newLimit);
    if (messages.length < newLimit) _hasMore = false;
    final normalized = _normalizeMessages(messages);
    _saveCache(sessionID, normalized);
    _setState(normalized);
  }

  void _saveCache(String sid, List<MessageWithParts> msgs) {
    try {
      final jsonStr = jsonEncode(msgs.map((m) => m.toJson()).toList());
      unawaited(DatabaseHelper().saveSessionCache(sid, jsonStr));
    } catch (_) {}
  }

  /// SSE: message.updated — 新增或更新一条消息（保留已有 parts）
  void updateMessage(String sessionID, MessageWithParts message) {
    if (this.sessionID != sessionID) return;
    _setState(MessageListStateReducer.updateMessage(_currentMessages, message));
  }

  /// SSE: message.removed — 删除一条消息
  void removeMessage(String sessionID, String messageID) {
    if (this.sessionID != sessionID) return;
    _contentNotifiers.remove(messageID);
    _setState(
      MessageListStateReducer.removeMessage(_currentMessages, messageID),
    );
  }

  /// SSE: message.part.updated — 新增或更新某条消息的一个 part
  void updatePart(String sessionID, String messageID, Object newPart) {
    if (this.sessionID != sessionID) return;
    final result = MessageListStateReducer.updatePart(
      _currentMessages,
      messageID,
      newPart,
    );
    _setState(result);
  }

  /// SSE: message.part.removed — 删除某条消息的一个 part
  void removePart(String sessionID, String messageID, String partID) {
    if (this.sessionID != sessionID) return;
    _setState(
      MessageListStateReducer.removePart(_currentMessages, messageID, partID),
    );
  }

  /// SSE: message.part.delta — 只刷新单个消息，不触发全列表重建
  void appendPartDelta(
    String sessionID,
    String messageID,
    String partID,
    String field,
    String delta,
  ) {
    if (this.sessionID != sessionID) return;
    if (field != 'text' || delta.isEmpty) return;

    // 在内部列表中更新消息内容
    final current = _currentMessages;
    final msgIdx = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIdx < 0) return;

    final message = current[msgIdx];
    final partIdx = message.parts.indexWhere((p) => partId(p) == partID);
    final newParts = List<Object>.from(message.parts);

    if (partIdx >= 0) {
      final part = message.parts[partIdx];
      if (part is! TextPart) return;
      newParts[partIdx] = TextPart(
        id: part.id,
        sessionID: part.sessionID,
        messageID: part.messageID,
        type: part.type,
        text: '${part.text}$delta',
        synthetic: part.synthetic,
        ignored: part.ignored,
        time: part.time,
        metadata: part.metadata,
      );
    } else {
      newParts.add(
        TextPart(
          id: partID,
          sessionID: sessionID,
          messageID: messageID,
          type: 'text',
          text: delta,
        ),
      );
    }

    // 只替换内部列表，不触发 provider 通知
    final updatedMsg = _messageWithNormalizedParts(message.info, newParts);
    final newList = List<MessageWithParts>.from(current);
    newList[msgIdx] = updatedMsg;
    state = AsyncData(newList);

    // 只通知这个消息的监听器
    final notifier = _contentNotifiers[messageID];
    if (notifier != null) {
      notifier.value = updatedMsg;
    }
  }

  List<MessageWithParts> get _currentMessages => state.asData?.value ?? [];

  void _setState(List<MessageWithParts> messages) {
    state = AsyncData(messages);
    for (final m in messages) {
      final mid = _messageId(m);
      final notifier = _contentNotifiers[mid];
      if (notifier != null) notifier.value = m;
    }
  }
}

String _messageId(MessageWithParts m) {
  final info = m.info;
  if (info is UserMessage) return info.id;
  if (info is AssistantMessage) return info.id;
  return '';
}

@riverpod
Future<List<FileDiff>> sessionDiff(Ref ref, String sessionID) async {
  final api = await ref.watch(sessionApiProvider.future);
  return api.getSessionDiff(sessionID);
}

/// 子 Session 消息列表（只读，支持 SSE 实时更新）
@riverpod
class SubSessionMessagesNotifier extends _$SubSessionMessagesNotifier {
  static const int _pageSize = 30;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<MessageWithParts>> build(String sessionID) async {
    ref.keepAlive();
    _hasMore = true;

    final cached = await DatabaseHelper().loadSessionCache(sessionID);
    if (cached != null && cached.isNotEmpty) {
      final decoded = (jsonDecode(cached) as List)
          .map((e) => MessageWithParts.fromJson(e as Map<String, dynamic>))
          .toList();
      final normalized = _normalizeMessages(decoded);
      _hasMore = true;
      return normalized;
    }

    final api = await ref.watch(sessionApiProvider.future);
    final messages = await api.getSessionMessages(sessionID, limit: _pageSize);
    if (messages.length < _pageSize) _hasMore = false;
    final normalized = _normalizeMessages(messages);
    _saveCache(sessionID, normalized);
    return normalized;
  }

  Future<void> refresh() async {
    final api = await ref.watch(sessionApiProvider.future);
    final messages = await api.getSessionMessages(sessionID, limit: _pageSize);
    if (messages.length < _pageSize) _hasMore = false;
    final normalized = _normalizeMessages(messages);
    _saveCache(sessionID, normalized);
    _setState(normalized);
  }

  Future<void> loadMore() async {
    final api = await ref.watch(sessionApiProvider.future);
    final current = _currentMessages;
    final newLimit = current.length + _pageSize;
    final messages = await api.getSessionMessages(sessionID, limit: newLimit);
    if (messages.length < newLimit) _hasMore = false;
    final normalized = _normalizeMessages(messages);
    _saveCache(sessionID, normalized);
    _setState(normalized);
  }

  void _saveCache(String sid, List<MessageWithParts> msgs) {
    try {
      final jsonStr = jsonEncode(msgs.map((m) => m.toJson()).toList());
      unawaited(DatabaseHelper().saveSessionCache(sid, jsonStr));
    } catch (_) {}
  }

  void updateMessage(String msgSessionID, MessageWithParts message) {
    if (msgSessionID != sessionID) return;
    _setState(MessageListStateReducer.updateMessage(_currentMessages, message));
  }

  void removeMessage(String msgSessionID, String messageID) {
    if (msgSessionID != sessionID) return;
    _setState(
      MessageListStateReducer.removeMessage(_currentMessages, messageID),
    );
  }

  void updatePart(String msgSessionID, String messageID, Object newPart) {
    if (msgSessionID != sessionID) return;
    _setState(
      MessageListStateReducer.updatePart(_currentMessages, messageID, newPart),
    );
  }

  void removePart(String msgSessionID, String messageID, String partID) {
    if (msgSessionID != sessionID) return;
    _setState(
      MessageListStateReducer.removePart(_currentMessages, messageID, partID),
    );
  }

  void appendPartDelta(
    String msgSessionID,
    String messageID,
    String partID,
    String field,
    String delta,
  ) {
    if (msgSessionID != sessionID) return;
    _setState(
      MessageListStateReducer.appendPartDelta(
        _currentMessages,
        msgSessionID,
        messageID,
        partID,
        field,
        delta,
      ),
    );
  }

  List<MessageWithParts> get _currentMessages => state.asData?.value ?? [];

  void _setState(List<MessageWithParts> messages) {
    state = AsyncData(messages);
  }
}

List<MessageWithParts> _upsertMessage(
  List<MessageWithParts> current,
  MessageWithParts incoming,
) {
  final index = current.indexWhere(
    (m) => _messageId(m) == _messageId(incoming),
  );
  final updated = List<MessageWithParts>.from(current);
  if (index >= 0) {
    updated[index] = _mergeMessagePreservingParts(updated[index], incoming);
  } else {
    updated.add(_messageWithNormalizedParts(incoming.info, incoming.parts));
  }
  return updated;
}

MessageWithParts _mergeMessagePreservingParts(
  MessageWithParts current,
  MessageWithParts incoming,
) {
  if (incoming.parts.isNotEmpty) {
    return _messageWithNormalizedParts(incoming.info, incoming.parts);
  }
  return _messageWithNormalizedParts(incoming.info, current.parts);
}

List<MessageWithParts> _normalizeMessages(List<MessageWithParts> messages) {
  return messages
      .map(
        (message) => _messageWithNormalizedParts(message.info, message.parts),
      )
      .toList();
}

MessageWithParts _messageWithNormalizedParts(Object info, List<Object> parts) {
  return MessageWithParts(info: info, parts: _normalizeParts(parts));
}

List<Object> _normalizeParts(List<Object> parts) {
  final normalized = List<Object>.from(parts);
  final seenByPartId = <String, int>{};

  for (var i = 0; i < normalized.length; i++) {
    final normalizedPartId = partId(normalized[i]);
    if (normalizedPartId == null) continue;

    final existingIndex = seenByPartId[normalizedPartId];
    if (existingIndex == null) {
      seenByPartId[normalizedPartId] = i;
      continue;
    }

    normalized[existingIndex] = normalized[i];
    normalized.removeAt(i);
    i -= 1;
  }

  return normalized;
}
