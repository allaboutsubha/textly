import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

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
          surface: const Color(0xFFFFFFFF),
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
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> _messages = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
  }

  // পারমিশন চেক এবং চাওয়ার ফাংশন
  Future<void> _requestSmsPermission() async {
    PermissionStatus status = await Permission.sms.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _loadMessages();
    } else {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
    }
  }

  // ইনবক্স থেকে এসএমএস লোড করার ফাংশন
  Future<void> _loadMessages() async {
    try {
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: SortOrder.DESC)],
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error loading SMS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Textly',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: _hasPermission ? _loadMessages : _requestSmsPermission,
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
                          'অ্যাপটি চালাতে এসএমএস পারমিশন প্রয়োজন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _requestSmsPermission,
                          child: const Text('পারমিশন দিন'),
                        ),
                      ],
                    ),
                  ),
                )
              : _messages.isEmpty
                  no Messages found.
                  const Center(
                      child: Text(
                        'কোনো মেসেজ পাওয়া যায়নি!',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        SmsMessage message = _messages[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                              child: const Icon(Icons.message, color: Color(0xFF2563EB)),
                            ),
                            title: Text(
                              message.address ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                message.body ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}