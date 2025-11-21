# Call State Plugin

A Flutter plugin for monitoring phone call states (incoming, dialing, connected, disconnected) on Android and iOS platforms. Perfect for integrating call state monitoring with real-time communication services like Stream.
<img width="216" height="480" alt="Screenshot_1763704664" src="https://github.com/user-attachments/assets/4f21b021-a396-4332-ac07-e8f8f2e53fe5" />


## Features

- 📱 **Cross-platform support** - Works on both Android and iOS
- 🔔 **Real-time call state monitoring** - Track incoming, dialing, connected, and disconnected states
- 🔐 **Permission management** - Built-in permission request and status checking
- 🧪 **Test mode** - Simulate call states for testing without real calls
- 🎨 **Modern Material 3 design** - Beautiful, modern UI in the example app
- ⚡ **Non-deprecated APIs** - Uses modern Android TelephonyCallback API (API 31+)
- 🔄 **Backward compatible** - Falls back to PhoneStateListener for older Android versions

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  call_state_plugin: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Android Setup

Add the following permission to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
```

### iOS Setup

No additional setup required! The plugin uses `CallKit`'s `CXCallObserver` API, which doesn't require any Info.plist permissions. The plugin works out of the box on iOS 10.0+.

## Usage

### Basic Usage

```dart
import 'package:call_state_plugin/call_state_plugin.dart';

final callStatePlugin = CallStatePlugin();

// Check permission status
bool hasPermission = await callStatePlugin.checkPermission();

// Request permission if not granted
if (!hasPermission) {
  bool granted = await callStatePlugin.requestPermission();
  if (!granted) {
    // Handle permission denial
    return;
  }
}

// Set up call state handlers
callStatePlugin.setIncomingHandler(() {
  print('Incoming call detected!');
});

callStatePlugin.setDialingHandler(() {
  print('Call is dialing...');
});

callStatePlugin.setConnectedHandler(() {
  print('Call connected!');
});

callStatePlugin.setDisconnectedHandler(() {
  print('Call disconnected!');
});

callStatePlugin.setErrorHandler((String message) {
  print('Error: $message');
});
```

### Test Mode

Test the plugin without making real calls:

```dart
// Enable test mode for 5 seconds
await callStatePlugin.setTestMode(5.0);
```

## Integration with StreamBuilder

This plugin works seamlessly with Flutter's `StreamBuilder` widget to create reactive UI that updates automatically when call states change. Here's how to integrate call state monitoring with StreamBuilder:

### 1. Create a Call State Stream Controller

First, create a stream controller to manage call state updates:

```dart
import 'dart:async';
import 'package:call_state_plugin/call_state_plugin.dart';

class CallStateService {
  final CallStatePlugin _plugin = CallStatePlugin();
  final _callStateController = StreamController<String>.broadcast();

  Stream<String> get callStateStream => _callStateController.stream;

  String _currentState = 'Idle';
  String get currentState => _currentState;

  Future<void> initialize() async {
    // Check and request permission
    bool hasPermission = await _plugin.checkPermission();
    if (!hasPermission) {
      hasPermission = await _plugin.requestPermission();
      if (!hasPermission) {
        _callStateController.add('Permission Denied');
        return;
      }
    }

    // Set up call state handlers
    _plugin.setIncomingHandler(() {
      _updateState('Incoming Call');
    });

    _plugin.setDialingHandler(() {
      _updateState('Dialing');
    });

    _plugin.setConnectedHandler(() {
      _updateState('Connected');
    });

    _plugin.setDisconnectedHandler(() {
      _updateState('Disconnected');
    });

    _plugin.setErrorHandler((String message) {
      _updateState('Error: $message');
    });
  }

  void _updateState(String state) {
    _currentState = state;
    _callStateController.add(state);
  }

  void dispose() {
    _callStateController.close();
  }
}
```

### 2. Use StreamBuilder in Your Widget

Now use `StreamBuilder` to reactively update your UI:

```dart
import 'package:flutter/material.dart';

class CallStateWidget extends StatefulWidget {
  @override
  _CallStateWidgetState createState() => _CallStateWidgetState();
}

class _CallStateWidgetState extends State<CallStateWidget> {
  final CallStateService _callStateService = CallStateService();

  @override
  void initState() {
    super.initState();
    _callStateService.initialize();
  }

  @override
  void dispose() {
    _callStateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _callStateService.callStateStream,
      initialData: 'Idle',
      builder: (context, snapshot) {
        final state = snapshot.data ?? 'Idle';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  _getStateIcon(state),
                  size: 48,
                  color: _getStateColor(state),
                ),
                const SizedBox(height: 8),
                Text(
                  'Call State',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  state,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _getStateColor(state),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStateIcon(String state) {
    switch (state) {
      case 'Incoming Call':
        return Icons.phone_in_talk;
      case 'Dialing':
        return Icons.phone;
      case 'Connected':
        return Icons.phone_callback;
      case 'Disconnected':
        return Icons.phone_disabled;
      default:
        return Icons.phone_paused;
    }
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'Incoming Call':
        return Colors.orange;
      case 'Dialing':
        return Colors.blue;
      case 'Connected':
        return Colors.green;
      case 'Disconnected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

### 3. Advanced: Multiple StreamBuilders

You can use multiple `StreamBuilder` widgets to update different parts of your UI:

```dart
class CallStateDashboard extends StatelessWidget {
  final CallStateService callStateService;

  const CallStateDashboard({required this.callStateService});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current state indicator
        StreamBuilder<String>(
          stream: callStateService.callStateStream,
          initialData: 'Idle',
          builder: (context, snapshot) {
            return Container(
              padding: EdgeInsets.all(16),
              color: _getStateColor(snapshot.data ?? 'Idle'),
              child: Text(
                snapshot.data ?? 'Idle',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          },
        ),

        // State history list
        StreamBuilder<String>(
          stream: callStateService.callStateStream,
          builder: (context, snapshot) {
            // This will rebuild whenever state changes
            return ListTile(
              leading: Icon(Icons.history),
              title: Text('Last State Change'),
              subtitle: Text(
                snapshot.data ?? 'No changes yet',
              ),
              trailing: Text(
                DateTime.now().toString().substring(11, 19),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStateColor(String state) {
    // Same color logic as before
    return Colors.grey;
  }
}
```

### 4. Complete Example with State History

Here's a complete example that tracks state history:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:call_state_plugin/call_state_plugin.dart';

class CallStateHistoryService {
  final CallStatePlugin _plugin = CallStatePlugin();
  final _stateHistoryController = StreamController<List<CallStateEntry>>.broadcast();
  final List<CallStateEntry> _history = [];

  Stream<List<CallStateEntry>> get stateHistoryStream => _stateHistoryController.stream;

  Future<void> initialize() async {
    bool hasPermission = await _plugin.checkPermission();
    if (!hasPermission) {
      hasPermission = await _plugin.requestPermission();
    }

    _plugin.setIncomingHandler(() => _addToHistory('Incoming Call'));
    _plugin.setDialingHandler(() => _addToHistory('Dialing'));
    _plugin.setConnectedHandler(() => _addToHistory('Connected'));
    _plugin.setDisconnectedHandler(() => _addToHistory('Disconnected'));
  }

  void _addToHistory(String state) {
    _history.insert(0, CallStateEntry(
      state: state,
      timestamp: DateTime.now(),
    ));
    if (_history.length > 50) {
      _history.removeLast();
    }
    _stateHistoryController.add(List.from(_history));
  }

  void dispose() {
    _stateHistoryController.close();
  }
}

class CallStateEntry {
  final String state;
  final DateTime timestamp;

  CallStateEntry({required this.state, required this.timestamp});
}

class CallStateHistoryWidget extends StatefulWidget {
  @override
  _CallStateHistoryWidgetState createState() => _CallStateHistoryWidgetState();
}

class _CallStateHistoryWidgetState extends State<CallStateHistoryWidget> {
  final CallStateHistoryService _service = CallStateHistoryService();

  @override
  void initState() {
    super.initState();
    _service.initialize();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallStateEntry>>(
      stream: _service.stateHistoryStream,
      initialData: [],
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return Center(
            child: Text('No call state history yet'),
          );
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index];
            return ListTile(
              leading: Icon(_getIcon(entry.state)),
              title: Text(entry.state),
              subtitle: Text(
                '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIcon(String state) {
    // Icon logic here
    return Icons.phone;
  }
}
```

### Benefits of Using StreamBuilder

- **Reactive UI**: Automatically updates when call state changes
- **Separation of Concerns**: Business logic separated from UI
- **Multiple Listeners**: Multiple widgets can listen to the same stream
- **Built-in State Management**: No need for external state management libraries
- **Performance**: Only rebuilds widgets that depend on the stream

## API Reference

### Methods

#### `Future<bool> checkPermission()`

Checks if the `READ_PHONE_STATE` permission is granted.

**Returns:** `true` if permission is granted, `false` otherwise.

#### `Future<bool> requestPermission()`

Requests the `READ_PHONE_STATE` permission from the user.

**Returns:** `true` if permission was granted, `false` if denied.

#### `void setIncomingHandler(VoidCallback callback)`

Sets a callback that is triggered when an incoming call is detected.

#### `void setDialingHandler(VoidCallback callback)`

Sets a callback that is triggered when a call is being dialed (outgoing call).

#### `void setConnectedHandler(VoidCallback callback)`

Sets a callback that is triggered when a call is connected.

#### `void setDisconnectedHandler(VoidCallback callback)`

Sets a callback that is triggered when a call is disconnected.

#### `void setErrorHandler(ErrorHandler handler)`

Sets a callback that is triggered when an error occurs.

**ErrorHandler signature:** `void Function(String message)`

#### `Future<dynamic> setTestMode(double seconds)`

Enables test mode to simulate call state changes for the specified duration.

**Parameters:**

- `seconds`: Duration in seconds for the test mode simulation

## Platform-Specific Notes

### Android

- Uses modern `TelephonyCallback` API on Android 12+ (API 31+)
- Falls back to `PhoneStateListener` for older Android versions
- Requires `READ_PHONE_STATE` permission

### iOS

- Uses `CallKit` framework's `CXCallObserver`
- **No Info.plist permissions required** - `CXCallObserver` works without any permission keys
- Works on iOS 10.0+

## Example App

The example app demonstrates all features of the plugin:

- Permission management
- Real-time call state monitoring
- Test mode with start/stop functionality
- State history tracking
- Modern Material 3 UI

Run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/yourusername/call_state_plugin/issues) page.
