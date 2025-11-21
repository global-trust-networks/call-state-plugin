import 'dart:async';

import 'package:flutter/material.dart';
import 'package:call_state_plugin/call_state_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call State Plugin Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const CallStateExamplePage(),
    );
  }
}

class CallStateExamplePage extends StatefulWidget {
  const CallStateExamplePage({super.key});

  @override
  State<CallStateExamplePage> createState() => _CallStateExamplePageState();
}

class _CallStateExamplePageState extends State<CallStateExamplePage>
    with TickerProviderStateMixin {
  final _callStatePlugin = CallStatePlugin();
  String _currentState = 'Idle';
  final List<StateHistoryEntry> _stateHistory = [];
  bool _testModeEnabled = false;
  bool _permissionGranted = false;
  bool _isCheckingPermission = false;
  final TextEditingController _testModeController = TextEditingController(
    text: '5.0',
  );
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  Timer? _testModeTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _checkPermissionStatus();
    _setupCallStateHandlers();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isCheckingPermission = true;
    });
    try {
      final hasPermission = await _callStatePlugin.checkPermission();
      setState(() {
        _permissionGranted = hasPermission;
        _isCheckingPermission = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });
    try {
      final granted = await _callStatePlugin.requestPermission();
      setState(() {
        _permissionGranted = granted;
        _isCheckingPermission = false;
      });
      if (granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission granted! Call monitoring is now active.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission denied. Please grant permission in app settings.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCheckingPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupCallStateHandlers() {
    _callStatePlugin.setIncomingHandler(() {
      _updateState('Incoming Call');
    });

    _callStatePlugin.setDialingHandler(() {
      _updateState('Dialing');
    });

    _callStatePlugin.setConnectedHandler(() {
      _updateState('Connected');
    });

    _callStatePlugin.setDisconnectedHandler(() {
      _updateState('Disconnected');
    });

    _callStatePlugin.setErrorHandler((String message) {
      _updateState('Error: $message');
    });
  }

  void _updateState(String state) {
    if (!mounted) return;
    setState(() {
      _currentState = state;
      _stateHistory.insert(
        0,
        StateHistoryEntry(state: state, timestamp: DateTime.now()),
      );
      if (_stateHistory.length > 50) {
        _stateHistory.removeLast();
      }
      _fadeController.reset();
      _fadeController.forward();
    });
  }

  Future<void> _enableTestMode() async {
    if (!_permissionGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant permission first to enable test mode.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final seconds = double.tryParse(_testModeController.text) ?? 5.0;
      if (seconds <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid duration (greater than 0).'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _callStatePlugin.setTestMode(seconds);
      setState(() {
        _testModeEnabled = true;
      });

      _testModeTimer?.cancel();
      _testModeTimer = Timer(Duration(seconds: seconds.toInt() + 1), () {
        if (mounted) {
          setState(() {
            _testModeEnabled = false;
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test mode enabled for ${seconds.toStringAsFixed(1)} seconds',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: seconds.toInt()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling test mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _disableTestMode() {
    _testModeTimer?.cancel();
    setState(() {
      _testModeEnabled = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test mode disabled'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _clearHistory() {
    setState(() {
      _stateHistory.clear();
      _currentState = 'Idle';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('History cleared'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Color _getStateColor() {
    switch (_currentState) {
      case 'Incoming Call':
        return Colors.orange;
      case 'Dialing':
        return Colors.blue;
      case 'Connected':
        return Colors.green;
      case 'Disconnected':
        return Colors.red;
      case 'Idle':
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon() {
    switch (_currentState) {
      case 'Incoming Call':
        return Icons.phone_in_talk;
      case 'Dialing':
        return Icons.phone;
      case 'Connected':
        return Icons.phone_callback;
      case 'Disconnected':
        return Icons.phone_disabled;
      case 'Idle':
      default:
        return Icons.phone_paused;
    }
  }

  Color _getStateColorForHistory(String state) {
    if (state.contains('Incoming')) return Colors.orange;
    if (state.contains('Dialing')) return Colors.blue;
    if (state.contains('Connected')) return Colors.green;
    if (state.contains('Disconnected')) return Colors.red;
    if (state.contains('Error')) return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    _testModeController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _testModeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call State Monitor'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'This app monitors phone call states including incoming calls, '
                    'dialing, connected, and disconnected states.\n\n'
                    'Grant permission to start monitoring real call events, or use '
                    'test mode to simulate call states.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkPermissionStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Permission Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _permissionGranted
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: _permissionGranted
                                ? Colors.green
                                : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Permission Status',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _permissionGranted
                                      ? 'Granted - Monitoring active'
                                      : 'Not granted - Monitoring inactive',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _permissionGranted
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isCheckingPermission)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _permissionGranted
                                ? _checkPermissionStatus
                                : _requestPermission,
                            icon: Icon(
                              _permissionGranted
                                  ? Icons.refresh
                                  : Icons.lock_open,
                            ),
                            label: Text(
                              _permissionGranted
                                  ? 'Refresh Status'
                                  : 'Grant Permission',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Current State Card
              FadeTransition(
                opacity: _fadeController,
                child: Card(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          _getStateColor().withOpacity(0.1),
                          _getStateColor().withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _currentState != 'Idle'
                                  ? 1.0 + (_pulseController.value * 0.1)
                                  : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _getStateColor().withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStateIcon(),
                                  size: 64,
                                  color: _getStateColor(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Current State',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentState,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: _getStateColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Test Mode Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.science, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Test Mode',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_testModeEnabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Active',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Simulate call state changes for testing',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _testModeController,
                              decoration: InputDecoration(
                                labelText: 'Duration (seconds)',
                                hintText: '5.0',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.timer),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_testModeEnabled)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _disableTestMode,
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _enableTestMode,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // State History Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'State History',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_stateHistory.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_stateHistory.length}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_stateHistory.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_all),
                              onPressed: _clearHistory,
                              tooltip: 'Clear history',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_stateHistory.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No state changes yet',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Grant permission and make a call\nor enable test mode',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _stateHistory.length,
                            itemBuilder: (context, index) {
                              final entry = _stateHistory[index];
                              final isFirst = index == 0;
                              return Container(
                                decoration: BoxDecoration(
                                  border: index < _stateHistory.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: colorScheme.outline
                                                .withOpacity(0.1),
                                          ),
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getStateColorForHistory(
                                        entry.state,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: _getStateColorForHistory(
                                        entry.state,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    entry.state,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isFirst
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: Text(
                                    _formatTime(entry.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
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
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Card(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Tips',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        context,
                        Icons.shield,
                        'Grant permission to monitor real call events',
                      ),
                      _buildTipItem(
                        context,
                        Icons.science,
                        'Use test mode to simulate call states',
                      ),
                      _buildTipItem(
                        context,
                        Icons.history,
                        'View state history to track all call events',
                      ),
                      _buildTipItem(
                        context,
                        Icons.refresh,
                        'Pull down to refresh permission status',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

class StateHistoryEntry {
  final String state;
  final DateTime timestamp;

  StateHistoryEntry({required this.state, required this.timestamp});
}
