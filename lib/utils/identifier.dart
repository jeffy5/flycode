import 'dart:math';

/// A utility class for generating and parsing unique identifiers.
/// Ported from TypeScript logic to ensure consistency across services.
class Identifier {
  static const Map<String, String> _prefixes = {
    'session': 'ses',
    'message': 'msg',
    'permission': 'per',
    'question': 'que',
    'user': 'usr',
    'part': 'prt',
    'pty': 'pty',
    'tool': 'tool',
    'workspace': 'wrk',
  };

  static const int _length = 26;

  // State for monotonic ID generation
  static int _lastTimestamp = 0;
  static int _counter = 0;

  /// Generates an ascending ID for the given prefix.
  /// If [given] is provided, it validates the prefix and returns it.
  static String ascending(String prefix, [String? given]) {
    return _generateID(prefix, false, given);
  }

  /// Generates a descending ID for the given prefix.
  /// If [given] is provided, it validates the prefix and returns it.
  static String descending(String prefix, [String? given]) {
    return _generateID(prefix, true, given);
  }

  static String _generateID(String prefix, bool isDescending, [String? given]) {
    final prefixStr = _prefixes[prefix];
    if (prefixStr == null) {
      throw ArgumentError('Invalid prefix: $prefix');
    }

    if (given != null) {
      if (!given.startsWith(prefixStr)) {
        throw ArgumentError('ID $given does not start with $prefixStr');
      }
      return given;
    }

    return create(prefix, descending: isDescending);
  }

  static String _randomBase62(int length) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(62))),
    );
  }

  /// Low-level method to create a new ID.
  static String create(
    String prefix, {
    bool descending = false,
    int? timestamp,
  }) {
    final prefixStr = _prefixes[prefix];
    if (prefixStr == null) {
      throw ArgumentError('Invalid prefix: $prefix');
    }

    final currentTimestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    if (currentTimestamp != _lastTimestamp) {
      _lastTimestamp = currentTimestamp;
      _counter = 0;
    }
    _counter++;

    // Calculate monotonic value: (timestamp << 12) + counter
    BigInt nowVal =
        BigInt.from(currentTimestamp) * BigInt.from(0x1000) +
        BigInt.from(_counter);

    if (descending) {
      // Bitwise NOT for descending order
      nowVal = ~nowVal;
    }

    // Mask to 48 bits (6 bytes) as in the reference implementation
    final mask48Bits = (BigInt.from(1) << 48) - BigInt.one;
    final maskedNow = nowVal & mask48Bits;

    // Convert to 12 hex characters
    final hexPart = maskedNow.toRadixString(16).padLeft(12, '0');

    // randomBase62(LENGTH - 12) = 14 random chars
    return '${prefixStr}_$hexPart${_randomBase62(_length - 12)}';
  }

  /// Extracts the timestamp from an ascending ID.
  /// Does not work with descending IDs.
  static int extractTimestamp(String id) {
    final parts = id.split('_');
    if (parts.length < 2) {
      throw ArgumentError('Invalid ID format');
    }
    final prefix = parts[0];
    // Hex part starts after prefix and underscore
    final hexStart = prefix.length + 1;
    final hexEnd = hexStart + 12;
    if (id.length < hexEnd) {
      throw ArgumentError('ID is too short to extract timestamp');
    }
    final hex = id.substring(hexStart, hexEnd);
    final encoded = BigInt.parse(hex, radix: 16);
    return (encoded ~/ BigInt.from(0x1000)).toInt();
  }

  /// Validates if the given ID starts with the correct prefix for the specified type.
  static bool isValid(String id, String prefix) {
    final prefixStr = _prefixes[prefix];
    if (prefixStr == null) return false;
    return id.startsWith(prefixStr);
  }
}
