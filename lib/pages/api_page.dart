import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_text.dart';
import '../constants/developer_docs_content.dart';

class APIPage extends StatefulWidget {
  const APIPage({super.key});

  @override
  State<APIPage> createState() => _APIPageState();
}

class _APIPageState extends State<APIPage> {
  String _selectedCategory = developerDocs.keys.first;
  late String _selectedTopic;

  @override
  void initState() {
    super.initState();
    _selectedTopic = developerDocs[_selectedCategory]!.keys.first;
  }

  void _selectTopic(String category, String topic) {
    setState(() {
      _selectedCategory = category;
      _selectedTopic = topic;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

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
          : null, // No back button on desktop as this is the home page
        title: const GradientText('PesaCrow Docs', fontSize: 22, fontWeight: FontWeight.bold),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/system-status'),
            icon: const Icon(Icons.monitor_heart, color: AppColors.cyan, size: 18),
            label: const Text(
              'System Status',
              style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600),
            ),
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

  Widget _buildSidebar() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: developerDocs.entries.map((categoryEntry) {
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
    final markdownData = developerDocs[_selectedCategory]![_selectedTopic]!;

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
                color: const Color(0xFF1E1E1E), // Deeper dark for code blocks
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
}
