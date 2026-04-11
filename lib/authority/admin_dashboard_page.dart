import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';

import 'admin_monitoring_map_page.dart';
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
                          'Open the admin monitoring map with circle details.',
                      icon: Icons.map_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminMonitoringMapPage(),
                          ),
                        );
                      },
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
        .collection('water_quality_readings')
        .where('verificationStatus', isEqualTo: 'approved')
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
