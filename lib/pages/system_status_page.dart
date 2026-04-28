import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../widgets/gradient_text.dart';
import '../constants/status_management.dart';

class SystemStatusPage extends StatefulWidget {
  const SystemStatusPage({super.key});

  @override
  State<SystemStatusPage> createState() => _SystemStatusPageState();
}

class _SystemStatusPageState extends State<SystemStatusPage> {
  late Future<Map<String, dynamic>> _statusFuture;

  String _selectedCategory = systemStatusDocs.keys.first;
  String _selectedTopic = systemStatusDocs.values.first.keys.first;

  @override
  void initState() {
    super.initState();
    _statusFuture = _fetchSystemStatus();
  }

  void _selectTopic(String category, String topic) {
    setState(() {
      _selectedCategory = category;
      _selectedTopic = topic;
    });
  }

  // ... (Keep existing fetch and dashboard methods)
  // Re-injecting the rest of the file exactly down to build

  Future<Map<String, dynamic>> _fetchSystemStatus() async {
    try {
      final response = await http.get(Uri.parse('https://api.escrow.pesacrow.top/api/status'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load system status');
      }
    } catch (e) {
      return {
        'status': 'degraded',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
      case 'success':
      case 'up':
        return Colors.greenAccent;
      case 'degraded':
      case 'warning':
        return AppColors.orange;
      case 'down':
      case 'failed':
      case 'error':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusIndicator(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDashboard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: AppColors.cyan),
          ));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.containsKey('error')) {
          return Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unable to fetch live status',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We could not reach the live status endpoint. Please try again later.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _statusFuture = _fetchSystemStatus();
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange.withOpacity(0.2),
                    foregroundColor: AppColors.orange,
                  ),
                )
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final overallStatus = data['status'] ?? 'unknown';
        final components = data['components'] ?? {};
        final darajaApi = components['daraja_api'] ?? {};
        final apiEndpoints = components['api_endpoints'] ?? {};
        final routes = apiEndpoints['routes'] ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashboard Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live API Status',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: ${data['timestamp'] ?? 'Unknown'}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    _buildStatusIndicator(overallStatus),
                  ],
                ),
              ),
              
              // M-Pesa Daraja Status
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'External Dependencies',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Safaricom M-Pesa (Daraja)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(darajaApi['message'] ?? 'No details available', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStatusIndicator(darajaApi['status'] ?? 'unknown'),
                              const SizedBox(height: 8),
                              Text('${darajaApi['latency_ms'] ?? 0} ms', style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Internal Endpoints
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Open Integration Endpoints',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        Text(
                          'v${data['version'] ?? '1.0.0'}',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...routes.entries.map((entry) {
                      final routeName = entry.key;
                      final routeData = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.01),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routeData['description'] ?? 'API Endpoint',
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    routeName,
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusIndicator(routeData['status'] ?? 'unknown'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: systemStatusDocs.entries.map((categoryEntry) {
        final category = categoryEntry.key;
        final topics = categoryEntry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...topics.keys.map((topic) {
                final isSelected = category == _selectedCategory && topic == _selectedTopic;
                return InkWell(
                  onTap: () {
                    _selectTopic(category, topic);
                    if (Scaffold.of(context).isDrawerOpen) {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.cyan.withOpacity(0.1) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? AppColors.cyan : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      topic,
                      style: TextStyle(
                        color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainContent() {
    if (_selectedTopic == 'Live API Status') {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildLiveDashboard(),
          ),
        ),
      );
    }

    final markdownData = systemStatusDocs[_selectedCategory]![_selectedTopic]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: MarkdownBody(
            data: markdownData,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1.3),
              h2: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.5),
              h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
              p: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.7),
              listBullet: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              code: TextStyle(
                color: AppColors.orange,
                backgroundColor: Colors.white.withOpacity(0.05),
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              blockquoteDecoration: BoxDecoration(
                border: const Border(left: BorderSide(color: AppColors.cyan, width: 4)),
                color: AppColors.cyan.withOpacity(0.05),
              ),
              tableBorder: TableBorder.all(color: Colors.white.withOpacity(0.1), width: 1),
              tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              tableBody: const TextStyle(color: AppColors.textSecondary),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        titleSpacing: isDesktop ? 24 : NavigationToolbar.kMiddleSpacing,
        leading: !isDesktop 
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
        title: const GradientText('System Status & Incidents', fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.cyan),
            tooltip: 'Refresh Status',
            onPressed: () {
              setState(() {
                _statusFuture = _fetchSystemStatus();
              });
            },
          ),
          const SizedBox(width: 24),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        backgroundColor: AppColors.surface,
        child: _buildSidebar(),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: _buildSidebar(),
            ),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }
}
