import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n.dart';
import '../providers/onboarding_provider.dart';
import '../providers/server_config_provider.dart';
import '../providers/provider_list_provider.dart';
import '../service/api/project_api.dart';
import '../service/api/session_api.dart';
import '../service/api/api_client.dart';
import '../models/server_config.dart';
import '../theme/app_tokens.dart';

class ServerConfigPage extends ConsumerStatefulWidget {
  final ServerConfig? initialConfig;
  final bool onboardingMode;

  const ServerConfigPage({
    super.key,
    this.initialConfig,
    this.onboardingMode = false,
  });

  @override
  ConsumerState<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends ConsumerState<ServerConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isTesting = false;
  bool _obscurePassword = true;
  bool _testPassed = false;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _baseUrlController = TextEditingController(
      text: config?.baseUrl ?? ServerConfig.defaultValue().baseUrl,
    );
    _usernameController = TextEditingController(text: config?.username ?? '');
    _passwordController = TextEditingController(text: config?.password ?? '');
    _baseUrlController.addListener(_onConfigChanged);
    _usernameController.addListener(_onConfigChanged);
    _passwordController.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (!_testPassed) return;
    setState(() => _testPassed = false);
  }

  @override
  void dispose() {
    _baseUrlController.removeListener(_onConfigChanged);
    _usernameController.removeListener(_onConfigChanged);
    _passwordController.removeListener(_onConfigChanged);
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _humanizedConnectionError(BuildContext context, Object error) {
    final l10n = context.l10n;
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return l10n.serverConfigErrorAuthFailed;
      }
      if (error.kind == ApiExceptionKind.timeout) {
        return l10n.serverConfigErrorNetworkRequestFailed;
      }
      if (error.kind == ApiExceptionKind.network) {
        return l10n.serverConfigErrorCannotConnect;
      }
      if (error.statusCode >= 500) {
        return l10n.serverConfigErrorServer(error.statusCode);
      }
      return l10n.serverConfigErrorRequestFailed(
        error.statusCode,
        error.message,
      );
    }
    if (error is FormatException) {
      return l10n.serverConfigErrorFormat;
    }
    return l10n.serverConfigErrorConnectionFailed;
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final client = ApiClient(
        baseUrl: _baseUrlController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
      );
      await client.get('/global/health');

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        setState(() => _testPassed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.serverConfigConnectionSuccess),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final tokens = context.tokens;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_humanizedConnectionError(context, e)),
            backgroundColor: tokens.errorSoftForeground,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.onboardingMode && !_testPassed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverConfigPleaseTestBeforeSave)),
      );
      return;
    }

    final config = ServerConfig(
      baseUrl: _baseUrlController.text.trim(),
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
    );

    await ref.read(serverConfigProvider.notifier).save(config);
    await ref.read(onboardingControllerProvider).markServerSetupCompleted();

    ref.invalidate(serverConfigProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(sessionsProvider);
    ref.invalidate(providerListProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverConfigSaveSuccess)),
      );
      if (widget.onboardingMode) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.onboardingMode
              ? l10n.serverConfigConnectServer
              : l10n.serverConfigTitle,
        ),
        centerTitle: true,
        automaticallyImplyLeading: !widget.onboardingMode,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.onboardingMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.infoForeground.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: tokens.infoForeground,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.serverConfigOnboardingHint,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: l10n.serverConfigServerAddress,
                hintText: l10n.serverConfigServerAddressHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.dns_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.serverConfigValidationServerRequired;
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return l10n.serverConfigValidationServerInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: l10n.serverConfigUsernameOptional,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: l10n.serverConfigPasswordOptional,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find_outlined),
                    label: Text(
                      _isTesting
                          ? l10n.serverConfigTesting
                          : l10n.serverConfigTestConnection,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      widget.onboardingMode
                          ? l10n.serverConfigSaveAndEnter
                          : l10n.serverConfigSave,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
