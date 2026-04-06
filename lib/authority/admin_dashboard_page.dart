import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:aquawatch/touhid-e-khuda/geo_map.dart';

import 'bangladesh_area_data.dart';
import 'verify_user_readings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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
              Colors.cyan.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<_AdminStats>(
            stream: _adminStatsStream(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? const _AdminStats.empty();
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildBackButton(context),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Manage water quality workflow',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildHealthBanner(stats),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                      children: [
                        _buildStatCard(
                          title: 'Total Users',
                          value: stats.totalUsers.toString(),
                          icon: Icons.groups_rounded,
                          color: Colors.white,
                        ),
                        _buildStatCard(
                          title: 'Pending Review',
                          value: stats.pendingReadings.toString(),
                          icon: Icons.hourglass_top_rounded,
                          color: const Color(0xFFFFC857),
                        ),
                        _buildStatCard(
                          title: 'Approved',
                          value: stats.approvedReadings.toString(),
                          icon: Icons.verified_rounded,
                          color: const Color(0xFF7EE081),
                        ),
                        _buildStatCard(
                          title: 'Rejected',
                          value: stats.rejectedReadings.toString(),
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFFF7A7A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      title: 'Review Pending Submissions',
                      subtitle: 'Open verification queue and process reports.',
                      icon: Icons.fact_check_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerifyUserReadingsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'View Verified Map Data',
                      subtitle:
                          'Track approved reports on the map in real-time.',
                      icon: Icons.map_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GeoMap()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'View Area Results',
                      subtitle:
                          'Select district and upazila to see verification summary.',
                      icon: Icons.location_city_rounded,
                      onTap: () => _showAreaFilterSheet(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Stream<_AdminStats> _adminStatsStream() {
    final firestore = FirebaseFirestore.instance;

    final users = firestore.collection('users').snapshots();
    final pending = firestore
        .collection('water_quality_readings')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots();
    final approved = firestore
        .collection('verified_water_quality_readings')
        .snapshots();
    final rejected = firestore
        .collection('water_quality_readings')
        .where('verificationStatus', isEqualTo: 'rejected')
        .snapshots();

    return StreamZip<QuerySnapshot<Map<String, dynamic>>>([
      users,
      pending,
      approved,
      rejected,
    ]).map(
      (snapshots) => _AdminStats(
        totalUsers: snapshots[0].docs.length,
        pendingReadings: snapshots[1].docs.length,
        approvedReadings: snapshots[2].docs.length,
        rejectedReadings: snapshots[3].docs.length,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthBanner(_AdminStats stats) {
    final healthy = stats.pendingReadings <= 15;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: healthy
                  ? const Color(0xFF7EE081).withValues(alpha: 0.22)
                  : const Color(0xFFFFC857).withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              healthy ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: healthy
                  ? const Color(0xFF7EE081)
                  : const Color(0xFFFFC857),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  healthy
                      ? 'Review Queue Under Control'
                      : 'Queue Needs Attention',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pending reports: ${stats.pendingReadings}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAreaFilterSheet(BuildContext context) async {
    final parentContext = context;
    String selectedDistrict = districtToThanas.keys.first;
    String selectedThana = districtToThanas[selectedDistrict]!.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final thanas = districtToThanas[selectedDistrict] ?? const [];
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              margin: const EdgeInsets.all(12),
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              decoration: BoxDecoration(
                color: const Color(0xFF10263D),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Area',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose district and upazila to view area results.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  _buildDropdownContainer(
                    child: DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      dropdownColor: const Color(0xFF10263D),
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      items: districtToThanas.keys
                          .map(
                            (district) => DropdownMenuItem<String>(
                              value: district,
                              child: Text(district),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedDistrict = value;
                          final nextThanas =
                              districtToThanas[value] ?? const [];
                          selectedThana = nextThanas.isNotEmpty
                              ? nextThanas.first
                              : '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownContainer(
                    child: DropdownButtonFormField<String>(
                      value: thanas.contains(selectedThana)
                          ? selectedThana
                          : (thanas.isNotEmpty ? thanas.first : null),
                      decoration: const InputDecoration(
                        labelText: 'Upazila / Thana',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      dropdownColor: const Color(0xFF10263D),
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      items: thanas
                          .map(
                            (thana) => DropdownMenuItem<String>(
                              value: thana,
                              child: Text(thana),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedThana = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: thanas.isEmpty || selectedThana.isEmpty
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                              _showAreaResultDialog(
                                parentContext,
                                district: selectedDistrict,
                                thana: selectedThana,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.analytics_rounded),
                      label: const Text('View Result'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }

  Future<void> _showAreaResultDialog(
    BuildContext context, {
    required String district,
    required String thana,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Area Result'),
          content: FutureBuilder<_AreaResultData>(
            future: _loadAreaResultData(district: district, thana: thana),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text('Could not load area result: ${snapshot.error}');
              }

              final result = snapshot.data ?? const _AreaResultData.empty();
              return SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$district • $thana',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _buildResultLine('Pending', result.pending),
                    _buildResultLine('Approved', result.approved),
                    _buildResultLine('Rejected', result.rejected),
                    const Divider(height: 20),
                    _buildResultLine('Total', result.total, isBold: true),
                    const SizedBox(height: 10),
                    const Text(
                      'Water Quality Reports',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (result.reports.isEmpty)
                      const Text('No reports found for this area.')
                    else
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          itemCount: result.reports.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final report = result.reports[index];
                            return _buildAreaReportCard(report);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAreaReportCard(_AreaWaterReport report) {
    final statusColor = _statusColor(report.status);
    final submittedText = _formatDate(report.submittedAt);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                submittedText,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.userName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            report.userEmail,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          if (report.overallQuality.isNotEmpty)
            Text('Overall: ${report.overallQuality}'),
          Text(
            'pH ${report.ph.toStringAsFixed(2)} | TDS ${report.tds.toStringAsFixed(2)}',
          ),
          Text(
            'EC ${report.ec.toStringAsFixed(2)} | Salinity ${report.salinity.toStringAsFixed(2)} | Temp ${report.temperature.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return const Color(0xFFEF6C00);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown time';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  Widget _buildResultLine(String label, int value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<_AreaResultData> _loadAreaResultData({
    required String district,
    required String thana,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final normalizedDistrict = _normalizeText(district);
    final normalizedThana = _normalizeText(thana);

    final snapshots = await Future.wait([
      firestore.collection('water_quality_readings').get(),
      firestore.collection('verified_water_quality_readings').get(),
    ]);

    final reports = <_AreaWaterReport>[];

    var pending = 0;
    var rejected = 0;
    for (final doc in snapshots[0].docs) {
      final data = doc.data();
      if (!_matchesArea(data, normalizedDistrict, normalizedThana)) {
        continue;
      }

      final status =
          (data['verificationStatus'] ?? 'pending').toString().toLowerCase();
      if (status == 'pending') {
        pending++;
      }
      if (status == 'rejected') {
        rejected++;
      }

      reports.add(_toAreaWaterReport(data, status: status));
    }

    var approved = 0;
    for (final doc in snapshots[1].docs) {
      final data = doc.data();
      if (!_matchesArea(data, normalizedDistrict, normalizedThana)) {
        continue;
      }
      approved++;
      reports.add(_toAreaWaterReport(data, status: 'approved'));
    }

    reports.sort((a, b) {
      final aTime = a.submittedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.submittedAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return _AreaResultData(
      pending: pending,
      approved: approved,
      rejected: rejected,
      reports: reports,
    );
  }

  _AreaWaterReport _toAreaWaterReport(
    Map<String, dynamic> data, {
    required String status,
  }) {
    return _AreaWaterReport(
      status: status[0].toUpperCase() + status.substring(1),
      userName: (data['userName'] ?? 'Unknown User').toString(),
      userEmail: (data['userEmail'] ?? 'Unknown Email').toString(),
      overallQuality: (data['overallQuality'] ?? '').toString(),
      ph: (data['ph'] as num?)?.toDouble() ?? 0,
      tds: (data['tds'] as num?)?.toDouble() ?? 0,
      ec: (data['ec'] as num?)?.toDouble() ?? 0,
      salinity: (data['salinity'] as num?)?.toDouble() ?? 0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
      submittedAt:
          (data['approvedAt'] as Timestamp?)?.toDate() ??
          (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool _matchesArea(
    Map<String, dynamic> data,
    String normalizedDistrict,
    String normalizedThana,
  ) {
    final districtValue = _readFirstNonEmpty(data, const [
      'district',
      'zila',
      'zilla',
    ]);
    final thanaValue = _readFirstNonEmpty(data, const [
      'upazila',
      'upozilla',
      'upazilla',
      'thana',
      'upojila',
      'upojela',
      'upozila',
    ]);

    final normalizedDistrictValue = _normalizeText(districtValue);
    final normalizedThanaValue = _normalizeText(thanaValue);

    final districtMatch =
        normalizedDistrictValue == normalizedDistrict ||
        normalizedDistrictValue.contains(normalizedDistrict) ||
        normalizedDistrict.contains(normalizedDistrictValue);
    final thanaMatch =
        normalizedThanaValue == normalizedThana ||
        normalizedThanaValue.contains(normalizedThana) ||
        normalizedThana.contains(normalizedThanaValue);

    if (normalizedDistrictValue.isNotEmpty && normalizedThanaValue.isNotEmpty) {
      return districtMatch && thanaMatch;
    }

    final areaText = _normalizeText(
      [
        data['area'],
        data['address'],
        data['locationName'],
      ].whereType<String>().join(' '),
    );

    if (areaText.isEmpty) return false;
    return areaText.contains(normalizedDistrict) &&
        areaText.contains(normalizedThana);
  }

  String _readFirstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _normalizeText(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _AdminStats {
  const _AdminStats({
    required this.totalUsers,
    required this.pendingReadings,
    required this.approvedReadings,
    required this.rejectedReadings,
  });

  const _AdminStats.empty()
    : totalUsers = 0,
      pendingReadings = 0,
      approvedReadings = 0,
      rejectedReadings = 0;

  final int totalUsers;
  final int pendingReadings;
  final int approvedReadings;
  final int rejectedReadings;
}

class _AreaResultData {
  const _AreaResultData({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.reports,
  });

  const _AreaResultData.empty()
    : pending = 0,
      approved = 0,
      rejected = 0,
      reports = const [];

  final int pending;
  final int approved;
  final int rejected;
  final List<_AreaWaterReport> reports;

  int get total => pending + approved + rejected;
}

class _AreaWaterReport {
  const _AreaWaterReport({
    required this.status,
    required this.userName,
    required this.userEmail,
    required this.overallQuality,
    required this.ph,
    required this.tds,
    required this.ec,
    required this.salinity,
    required this.temperature,
    required this.submittedAt,
  });

  final String status;
  final String userName;
  final String userEmail;
  final String overallQuality;
  final double ph;
  final double tds;
  final double ec;
  final double salinity;
  final double temperature;
  final DateTime? submittedAt;
}
