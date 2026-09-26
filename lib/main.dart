import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    _requestAndFetchSms();
  }

  Future<void> _requestAndFetchSms() async {
    setState(() => _isLoading = true);
    PermissionStatus status = await Permission.sms.request();
    
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      await _fetchInboxSMS();
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  // অ্যান্ড্রয়েডের নেটিভ ইনবক্স থেকে রিয়েল এসএমএস ফেচ করার ফাংশন
  Future<void> _fetchInboxSMS() async {
    try {
      // প্ল্যাটফর্ম চ্যানেলের মাধ্যমে ফোনের ইনবক্স রিড করা
      final List<dynamic> result = await platform.invokeMethod('getInboxSms');
      final List<Map<String, String>> loadedMessages = result.map((item) {
        final map = Map<String, dynamic>.from(item);
        return {
          "sender": map["address"]?.toString() ?? "Unknown",
          "body": map["body"]?.toString() ?? "",
          "date": "Recent",
        };
      }).toList();

      setState(() {
        _realMessages = loadedMessages;
        _isLoading = false;
      });
    } catch (e) {
      // যদি নেটিভ কোড কনফিগার করা না থাকে, তবে সেফ হ্যান্ডলিং
      setState(() {
        _realMessages = [];
        _isLoading = false;
      });
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
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: _requestAndFetchSms,
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
                          'ইনবক্স দেখতে এসএমএস পারমিشن প্রয়োজন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _requestAndFetchSms,
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