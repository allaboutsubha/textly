import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const TextlyApp());
}

class TextlyApp extends StatelessWidget {
  const TextlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Textly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF2563EB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
      ),
      home: const InboxScreen(),
    );
  }
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, String>> _realMessages = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  
  static const platform = MethodChannel('com.textly.app/sms');
  static const EventChannel _smsStream = EventChannel('com.textly.app/sms_stream');
  StreamSubscription? _smsSubscription;

  @override
  void initState() {
    super.initState();
    _requestAndInitSms();
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestAndInitSms() async {
    setState(() => _isLoading = true);
    PermissionStatus status = await Permission.sms.request();
    
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _fetchInitialSms();
      _startSmsListener(); // লাইভ স্ট্রিম লিসেনার চালু করা হলো
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchInitialSms() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInboxSms');
      _updateMessageList(result);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // গুগল মেসেজের মতো রিয়েল-টাইম লাইভ লিসেনার
  void _startSmsListener() {
    _smsSubscription = _smsStream.receiveBroadcastStream().listen((dynamic event) {
      if (event != null) {
        _updateMessageList(event as List<dynamic>);
      }
    }, onError: (dynamic error) {
      debugPrint("SMS Stream Error: $error");
    });
  }

  void _updateMessageList(List<dynamic> result) {
    final List<Map<String, String>> loadedMessages = result.map((item) {
      final map = Map<String, dynamic>.from(item);
      return {
        "sender": map["address"]?.toString() ?? "Unknown",
        "body": map["body"]?.toString() ?? "",
        "date": "Recent",
      };
    }).toList();

    if (mounted) {
      setState(() {
        _realMessages = loadedMessages;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestDefaultSmsApp() async {
    try {
      await platform.invokeMethod('setDefaultSmsApp');
    } catch (e) {
      debugPrint("Error setting default app: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Textly SMS',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications, color: Color(0xFF2563EB)),
            tooltip: 'Set as Default SMS App',
            onPressed: _requestDefaultSmsApp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: _fetchInitialSms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : !_hasPermission
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ইনবক্স দেখতে এসএমএস পারমিশন প্রয়োজন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _requestAndInitSms,
                          child: const Text('পারমিশন দিন'),
                        ),
                      ],
                    ),
                  ),
                )
              : _realMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'আপনার ফোনে কোনো মেসেজ পাওয়া যায়নি!',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _realMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _realMessages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                              child: const Icon(Icons.message, color: Color(0xFF2563EB)),
                            ),
                            title: Text(
                              msg['sender']!,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                msg['body']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                            trailing: Text(
                              msg['date']!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}