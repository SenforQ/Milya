import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _termsContent,
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
        ),
      ),
    );
  }

  static const String _termsContent = '''
Terms of Use

1. Acceptance of Terms
By accessing and using our services, you agree to be bound by these Terms of Use and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using our services.

2. Service Description
Our services provide users with access to jewelry sharing and community features. We reserve the right to modify, suspend, or discontinue any aspect of our services at any time without prior notice.

3. User Conduct
You agree to use our services only for lawful purposes and in accordance with these terms. You shall not engage in any conduct that restricts or inhibits anyone's use or enjoyment of the services.

4. Prohibited Activities
You may not use our services to upload, post, or transmit any content that is illegal, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, or otherwise objectionable.

5. Intellectual Property Rights
All content, features, and functionality of our services are owned by us or our licensors and are protected by copyright, trademark, and other intellectual property laws.

6. User-Generated Content
You retain ownership of content you submit to our services but grant us a non-exclusive, royalty-free license to use, modify, and display such content in connection with our services.

7. Content Moderation
We reserve the right to review, edit, or remove any user-generated content that violates these terms or is otherwise deemed inappropriate, without prior notice.

8. Privacy and Data Protection
Your use of our services is subject to our Privacy Policy, which governs how we collect, use, and protect your personal information.

9. Disclaimer of Warranties
Our services are provided "as is" and "as available" without warranties of any kind, either express or implied, including but not limited to warranties of merchantability or fitness for a particular purpose.

10. Limitation of Liability
We shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of our services.

11. Indemnification
You agree to defend, indemnify, and hold us harmless from any claims, damages, losses, or expenses arising out of your use of our services or violation of these terms.

12. Termination
We may terminate or suspend your access to our services immediately, without prior notice, for conduct that we believe violates these terms or is harmful to other users or our business.

13. Governing Law
These terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law provisions.

14. Modification of Terms
We reserve the right to modify these terms at any time. Material changes will be communicated through our services or other appropriate means. Continued use constitutes acceptance of modified terms.

15. Severability and Entire Agreement
If any provision of these terms is found to be unenforceable, the remaining provisions will remain in full force and effect. These terms constitute the entire agreement between you and us regarding the use of our services.

These Terms of Use are effective as of the date specified and govern your use of our services. Please review them periodically for updates.
''';
}
