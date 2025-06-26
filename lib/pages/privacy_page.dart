import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
          _privacyContent,
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
        ),
      ),
    );
  }

  static const String _privacyContent = '''
Privacy Policy

1. Information Collection
We collect information you provide directly to us, such as when you use our services, contact us, or participate in surveys. This may include personal information such as your name, email address, and usage data.

2. Use of Information
We use the information we collect to provide, maintain, and improve our services, communicate with you, and personalize your experience. We may also use this information for analytics and research purposes.

3. Information Sharing
We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this privacy policy or as required by law.

4. Data Security
We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. Cookies and Tracking Technologies
We use cookies, web beacons, and similar tracking technologies to collect and store information about your interactions with our services to improve functionality and user experience.

6. Third-Party Services
Our services may contain links to third-party websites or integrate with third-party services. We are not responsible for the privacy practices of these third parties.

7. Data Retention
We retain your personal information for as long as necessary to provide our services, comply with legal obligations, resolve disputes, and enforce our agreements.

8. Children's Privacy
Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13 without parental consent.

9. International Data Transfers
Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information during such transfers.

10. Your Rights and Choices
You have the right to access, update, correct, or request deletion of your personal information. You may also opt out of certain communications from us.

11. Data Accuracy
We strive to maintain accurate and up-to-date information. You are responsible for providing accurate information and notifying us of any changes to your personal information.

12. Business Transfers
In the event of a merger, acquisition, or sale of assets, your personal information may be transferred as part of the transaction, subject to equivalent privacy protections.

13. Legal Compliance
We may disclose your information when required by law, legal process, or government request, or when we believe disclosure is necessary to protect our rights or comply with judicial proceedings.

14. Privacy Policy Updates
We may update this privacy policy from time to time. We will notify you of any material changes by posting the updated policy on our website or through other appropriate communication channels.

15. Contact Information
If you have any questions, concerns, or requests regarding this privacy policy or our privacy practices, please contact us through the contact information provided in our application or website.

This privacy policy is effective as of the date specified and governs the collection, use, and disclosure of information through our services.
''';
}
