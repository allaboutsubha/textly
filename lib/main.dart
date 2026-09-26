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
  List<dynamic> _groupedMessages = [];
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
      await _fetchGroupedSms();
      _startSmsListener();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGroupedSms() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getGroupedSms');
      if (mounted) {
        setState(() {
          _groupedMessages = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startSmsListener() {
    _smsSubscription = _smsStream.receiveBroadcastStream().listen((dynamic event) {
      if (event != null && mounted) {
        setState(() {
          _groupedMessages = event as List<dynamic>;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _deleteGroupMessages(List<dynamic> messages) async {
    try {
      for (var msg in messages) {
        final m = Map<String, dynamic>.from(msg);
        if (m['id'] != null) {
          await platform.invokeMethod('deleteSms', {"id": m['id'].toString()});
        }
      }
      _fetchGroupedSms();
    } catch (e) {
      debugPrint("Delete error: $e");
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
          'Conversations',
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
            onPressed: _fetchGroupedSms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : !_hasPermission
              ? Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    onPressed: _requestAndInitSms,
                    child: const Text('Grant SMS Permission'),
                  ),
                )
              : _groupedMessages.isEmpty
                  ? const Center(child: Text('No messages found', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _groupedMessages.length,
                      itemBuilder: (context, index) {
                        final group = Map<String, dynamic>.from(_groupedMessages[index]);
                        final sender = group['sender'] ?? 'Unknown';
                        final lastMessage = group['lastMessage'] ?? '';
                        final messages = group['messages'] as List<dynamic>;

                        return Dismissible(
                          key: Key(sender + index.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            setState(() {
                              _groupedMessages.removeAt(index);
                            });
                            _deleteGroupMessages(messages);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Conversation deleted')),
                            );
                          },
                          child: Container(
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
                                child: const Icon(Icons.person, color: Color(0xFF2563EB)),
                              ),
                              title: Text(
                                sender,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${messages.length}",
                                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConversationDetailScreen(
                                      sender: sender,
                                      messages: messages,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class ConversationDetailScreen extends StatelessWidget {
  final String sender;
  final List<dynamic> messages;

  const ConversationDetailScreen({super.key, required this.sender, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sender, style: const TextStyle(color: Color(0xFF0F172A))),
        backgroundColor: const Color(0xFFFFFFFF),
        iconTheme: const IconThemeData(color: Color(0xFF2563EB)),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = Map<String, dynamic>.from(messages[index]);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              msg['body'] ?? '',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
            ),
          );
        },
      ),
    );
  }
}