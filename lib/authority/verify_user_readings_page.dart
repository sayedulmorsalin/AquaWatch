import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aquawatch/services/auth_service.dart';
import 'package:aquawatch/services/reading_verification_service.dart';

class VerifyUserReadingsPage extends StatefulWidget {
  const VerifyUserReadingsPage({super.key});

  @override
  State<VerifyUserReadingsPage> createState() => _VerifyUserReadingsPageState();
}

class _VerifyUserReadingsPageState extends State<VerifyUserReadingsPage> {
  final ReadingVerificationService _verificationService =
      ReadingVerificationService();
  final AuthService _authService = AuthService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      return value.toString();
    }
    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final local = date.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year;
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
    return '-';
  }

  bool _matchesQuery(Map<String, dynamic> data) {
    if (_query.isEmpty) return true;
    final text = _query.toLowerCase();
    return [
      data['userName'],
      data['userEmail'],
      data['verificationStatus'],
      data['overallQuality'],
      data['ph'],
      data['tds'],
      data['ec'],
      data['salinity'],
      data['temperature'],
    ].whereType<Object>().any(
      (value) => value.toString().toLowerCase().contains(text),
    );
  }

  Future<void> _approveReading(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _verificationService.approveReading(
        reference: ref,
        verifiedBy: user.email ?? user.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission approved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not approve submission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectReading(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject submission'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Enter rejection note'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(reasonController.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();

    if (reason == null) return;

    try {
      await _verificationService.rejectReading(
        reference: ref,
        verifiedBy: user.email ?? user.uid,
        reason: reason.isEmpty ? 'Rejected by authority' : reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission rejected.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not reject submission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openDetails(Map<String, dynamic> data) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final images = <String>[
          ...(data['phImageUrls'] as List<dynamic>? ?? const []).cast<String>(),
          ...(data['tdsImageUrls'] as List<dynamic>? ?? const [])
              .cast<String>(),
          ...(data['ecImageUrls'] as List<dynamic>? ?? const []).cast<String>(),
          ...(data['salinityImageUrls'] as List<dynamic>? ?? const [])
              .cast<String>(),
        ];

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data['userName']?.toString() ?? 'Unknown user',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['userEmail']?.toString() ?? '-',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _infoChip('pH ${_formatValue(data['ph'])}'),
                      _infoChip('TDS ${_formatValue(data['tds'])}'),
                      _infoChip('EC ${_formatValue(data['ec'])}'),
                      _infoChip('Salinity ${_formatValue(data['salinity'])}'),
                      _infoChip('Temp ${_formatValue(data['temperature'])}'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Overall: ${data['overallQuality'] ?? '-'} (${data['overallScore'] ?? '-'}/100)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Location: ${_formatValue(data['latitude'])}, ${_formatValue(data['longitude'])}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Attached Images',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (images.isEmpty)
                    Text(
                      'No images attached.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.white.withValues(alpha: 0.08),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.cyan.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify User Submissions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review and verify pending water quality data',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by user, status, or value',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  stream: _verificationService.pendingReadings(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Failed to load submissions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final docs =
                        snapshot.data
                            ?.where((doc) => _matchesQuery(doc.data()))
                            .toList() ??
                        [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No pending submissions found.'
                              : 'No matching submissions found.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final status =
                            data['verificationStatus']?.toString() ?? 'pending';
                        final statusColor = status == 'pending'
                            ? Colors.amber
                            : status == 'approved'
                            ? Colors.greenAccent
                            : Colors.redAccent;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['userName']?.toString() ??
                                                'Unknown user',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            data['userEmail']?.toString() ??
                                                '-',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: statusColor.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _infoChip('pH ${_formatValue(data['ph'])}'),
                                    _infoChip(
                                      'TDS ${_formatValue(data['tds'])}',
                                    ),
                                    _infoChip('EC ${_formatValue(data['ec'])}'),
                                    _infoChip(
                                      'Salinity ${_formatValue(data['salinity'])}',
                                    ),
                                    _infoChip(
                                      'Temp ${_formatValue(data['temperature'])}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Overall: ${data['overallQuality'] ?? '-'} | Score: ${_formatValue(data['overallScore'])}/100',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Submitted: ${_formatDate(data['submittedAt'])}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openDetails(data),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        label: const Text('Details'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await _approveReading(doc.reference);
                                        },
                                        icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                        ),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await _rejectReading(doc.reference);
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
