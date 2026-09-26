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
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
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

  Future<void> _deleteMessage(String id) async {
    try {
      await platform.invokeMethod('deleteSms', {"id": id});
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
        title: const Text('Conversations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications),
            onPressed: _requestDefaultSmsApp,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGroupedSms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? Center(
                  child: ElevatedButton(
                    onPressed: _requestAndInitSms,
                    child: const Text('Grant SMS Permission'),
                  ),
                )
              : _groupedMessages.isEmpty
                  ? const Center(child: Text('No messages found'))
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
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            // Group-er shob message ba latest message delete korar jonno
                            for (var msg in messages) {
                              final m = Map<String, dynamic>.from(msg);
                              if (m['id'] != null) {
                                _deleteMessage(m['id'].toString());
                              }
                            }
                            setState(() {
                              _groupedMessages.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Conversation deleted')),
                            );
                          },
                          child: Card(
                            color: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                              title: Text(
                                sender,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: Text(
                                "${messages.length}",
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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

// Conversation Detail View Screen (Image 2 style)
class ConversationDetailScreen extends StatelessWidget {
  final String sender;
  final List<dynamic> messages;

  const ConversationDetailScreen({super.key, required this.sender, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sender),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = Map<String, dynamic>.from(messages[index]);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              msg['body'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}