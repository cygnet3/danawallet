import 'package:danawallet/constants.dart';
import 'package:danawallet/repositories/name_server_repository.dart';
import 'package:danawallet/repositories/settings_repository.dart';
import 'package:danawallet/states/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

/// Dialog for creating a BIP353 address (ie an alias)
class AliasCreationDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const AliasCreationDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<AliasCreationDialog> createState() => _AliasCreationDialogState();
}

class _AliasCreationDialogState extends State<AliasCreationDialog> {
  final TextEditingController _usernameController = TextEditingController();
  String? _error;
  bool _isCreating = false;
  String? _createdAlias;
  String? _domain;

  @override
  void initState() {
    super.initState();
    _loadExistingAlias();
    _loadDomain();
  }

  Future<void> _loadExistingAlias() async {
    final existingAlias = await SettingsRepository.instance.getUserAlias();
    if (existingAlias != null && mounted) {
      setState(() {
        _createdAlias = existingAlias;
      });
    }
  }

  void _loadDomain() {
    final nameServer = Provider.of<NameServerRepository>(context, listen: false);
    _domain = nameServer.domain;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool _isValidUsername(String username) {
    final regex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return regex.hasMatch(username);
  }

  Future<void> _createAlias() async {
    final username = _usernameController.text.trim();
    
    if (!_isValidUsername(username)) {
      setState(() {
        _error = 'Username must be 3-20 characters, letters, numbers, and underscores only';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _error = null;
    });

    final nameServer = Provider.of<NameServerRepository>(context, listen: false);

    try {
      final tryAlias = '$username@${nameServer.domain}';
      final isAvailable = await nameServer.isUserAliasAvailable(
        alias: tryAlias,
      );

      if (!mounted) return;

      if (!isAvailable) {
        setState(() {
          _isCreating = false;
          _error = 'Alias $tryAlias already exists';
        });
        return;
      }

      final walletState = Provider.of<WalletState>(context, listen: false);
      final spAddress = walletState.address;
      final aliasCreationResult = await nameServer.createAlias(username: username, spAddress: spAddress);

      Logger().d(aliasCreationResult.toString());

      if (aliasCreationResult.success) {
        // Store the alias in permanent storage
        await SettingsRepository.instance.setUserAlias(aliasCreationResult.alias);
        
        setState(() {
          _createdAlias = aliasCreationResult.alias;
          _isCreating = false;
        });

        Logger().d('Alias created and stored: ${aliasCreationResult.alias}');
      } else {
        setState(() {
          _isCreating = false;
          _error = aliasCreationResult.error ?? 'Failed to create alias';
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isCreating = false;
        _error = 'Failed to verify username: ${e.toString()}';
      });
    }
  }

  void _complete() {
    Navigator.of(context).pop();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_createdAlias != null) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF34C759)),
            SizedBox(width: 12),
            Text('Alias Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your new alias is ready to use:',
              style: TextStyle(fontSize: 14, color: Color(0xFF6D6D70)),
            ),
            const SizedBox(height: 12),
            Text(
              _createdAlias!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF34C759),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This alias has been saved, start sharing it with your friends!',
              style: TextStyle(fontSize: 12, color: Color(0xFF6D6D70)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _complete,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Done'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.email_outlined, color: Color(0xFF007AFF)),
          SizedBox(width: 12),
          Text('Create Your Bitcoin Alias'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a username to create your email-like alias',
            style: TextStyle(fontSize: 14, color: Color(0xFF6D6D70)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'yourusername',
              suffixText: _domain != null ? '@$_domain' : '@$defaultAliasDomain',
              border: const OutlineInputBorder(),
              errorBorder: _error != null ? const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF3B30)),
              ) : null,
              focusedErrorBorder: _error != null ? const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF3B30), width: 1.5),
              ) : null,
            ),
            enabled: !_isCreating,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF3B30),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isCreating ? null : _createAlias,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

