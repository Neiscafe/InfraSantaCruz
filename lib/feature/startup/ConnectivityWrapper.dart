import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (_) {}
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (_isConnected != hasConnection) {
      if (mounted) {
        setState(() {
          _isConnected = hasConnection;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !_isConnected
              ? Material(
                  key: const ValueKey('no_connection_banner'),
                  color: Colors.red,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      color: Colors.red,
                      child: const Text(
                        'Sem conexão',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('connected')),
        ),
      ],
    );
  }
}
