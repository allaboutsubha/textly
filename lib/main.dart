import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isLoading = false;
  bool _hasPermission = false;

  // আপনার ক্লায়েন্টকে দেখানোর জন্য বা প্রজেক্ট সচল রাখার জন্য ডামি বা লোকাল ইনবক্স ডাটা
  final List<Map<String, String>> _dummyMessages = [
    {"sender": "RBL Bank", "body": "13198 is the OTP to provide consent for your RBL Bank Credit Card application.", "date": "25 Sept"},
    {"sender": "Jio Info", "body": "এই জিও নম্বর 9614207279 এ আপনার প্ল্যান শেষ হয়ে গেছে এবং পরিষেবা বন্ধ হয়ে গেছে।", "date": "25 Sept"},
    {"sender": "Bsnl Subha", "body": "Hi, how are you? Let me know when you are free.", "date": "25 Sept"},
  ];

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    PermissionStatus status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });
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
            onPressed: _requestPermission,
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
                          onPressed: _requestPermission,
                          child: const Text('পারমিশন দিন'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: constEDI = const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  itemCount: _dummyMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _dummyMessages[index];
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