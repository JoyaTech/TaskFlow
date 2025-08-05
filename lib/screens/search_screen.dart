import 'package:flutter/material.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/mock_database_service.dart';
import 'package:mindflow/task_list_widget.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Task> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  // Filters
  TaskType? _selectedType;
  TaskPriority? _selectedPriority;
  bool? _isCompleted;
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'createdAt';
  bool _descending = true;
  
  // Recent searches
  List<String> _recentSearches = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecentSearches();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadRecentSearches() {
    // TODO: Load from SharedPreferences
    _recentSearches = [
      'תזכורות חשובות',
      'משימות השבוע',
      'פגישות',
    ];
  }
  
  void _saveRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });
    
    // TODO: Save to SharedPreferences
  }
  
  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedType == null && _selectedPriority == null && 
        _isCompleted == null && _startDate == null && _endDate == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      final results = await MockDatabaseService.searchAndFilterTasks(
        query: query,
        type: _selectedType,
        priority: _selectedPriority,
        isCompleted: _isCompleted,
        startDate: _startDate,
        endDate: _endDate,
        sortBy: _sortBy,
        descending: _descending,
      );
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      
      if (query.isNotEmpty) {
        _saveRecentSearch(query);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('שגיאה בחיפוש: $e');
    }
  }
  
  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedPriority = null;
      _isCompleted = null;
      _startDate = null;
      _endDate = null;
      _sortBy = 'createdAt';
      _descending = true;
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('חיפוש משימות'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'חיפוש', icon: Icon(Icons.search)),
            Tab(text: 'מסננים', icon: Icon(Icons.filter_list)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'חיפוש משימות...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults.clear();
                                  _hasSearched = false;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _search,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildFiltersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchTab() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }
    
    if (!_hasSearched) {
      return _buildInitialState();
    }
    
    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }
    
    return Column(
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'נמצאו ${_searchResults.length} תוצאות',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildSortButton(),
            ],
          ),
        ),
        
        // Results list
        Expanded(
          child: TaskListWidget(
            tasks: _searchResults,
            onTaskTap: (task) => _handleTaskTap(task),
            onTaskCompleted: (task) => _handleTaskCompleted(task),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active filters indicator
          if (_hasActiveFilters()) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'מסננים פעילים: ${_getActiveFiltersCount()}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('נקה הכל'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Task Type Filter
          _buildFilterSection(
            'סוג משימה',
            Wrap(
              spacing: 8,
              children: TaskType.values.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = selected ? type : null;
                    });
                  },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(type.emoji),
                      const SizedBox(width: 4),
                      Text(type.hebrewName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Priority Filter
          _buildFilterSection(
            'עדיפות',
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPriority = selected ? priority : null;
                    });
                  },
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(priority.emoji),
                      const SizedBox(width: 4),
                      Text(priority.hebrewName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Completion Status Filter
          _buildFilterSection(
            'סטטוס',
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  selected: _isCompleted == false,
                  onSelected: (selected) {
                    setState(() {
                      _isCompleted = selected ? false : null;
                    });
                  },
                  label: const Text('לא הושלמו'),
                ),
                FilterChip(
                  selected: _isCompleted == true,
                  onSelected: (selected) {
                    setState(() {
                      _isCompleted = selected ? true : null;
                    });
                  },
                  label: const Text('הושלמו'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date Range Filter
          _buildFilterSection(
            'טווח תאריכים',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectStartDate(),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate != null 
                            ? 'מ: ${_formatDate(_startDate!)}'
                            : 'תאריך התחלה'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectEndDate(),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate != null 
                            ? 'עד: ${_formatDate(_endDate!)}'
                            : 'תאריך סיום'),
                      ),
                    ),
                  ],
                ),
                if (_startDate != null || _endDate != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    child: const Text('נקה תאריכים'),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Apply Filters Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('החל מסננים'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
  
  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'חיפושים אחרונים',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _search();
                  },
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Quick search suggestions
          Text(
            'חיפושים מומלצים',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickSearchOptions(),
        ],
      ),
    );
  }
  
  Widget _buildQuickSearchOptions() {
    final quickSearches = [
      {'title': 'משימות חשובות', 'priority': TaskPriority.important},
      {'title': 'תזכורות', 'type': TaskType.reminder},
      {'title': 'אירועים', 'type': TaskType.event},
      {'title': 'משימות לא הושלמו', 'completed': false},
    ];
    
    return Column(
      children: quickSearches.map((search) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(search['title'] as String),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            setState(() {
              if (search.containsKey('priority')) {
                _selectedPriority = search['priority'] as TaskPriority;
              }
              if (search.containsKey('type')) {
                _selectedType = search['type'] as TaskType;
              }
              if (search.containsKey('completed')) {
                _isCompleted = search['completed'] as bool;
              }
            });
            _search();
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'לא נמצאו תוצאות',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'נסה לשנות את קריטריוני החיפוש',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (value) {
        final parts = value.split('_');
        setState(() {
          _sortBy = parts[0];
          _descending = parts[1] == 'desc';
        });
        _search();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'createdAt_desc',
          child: Text('תאריך יצירה (חדש לישן)'),
        ),
        const PopupMenuItem(
          value: 'createdAt_asc',
          child: Text('תאריך יצירה (ישן לחדש)'),
        ),
        const PopupMenuItem(
          value: 'dueDate_asc',
          child: Text('תאריך יעד (קרוב לרחוק)'),
        ),
        const PopupMenuItem(
          value: 'dueDate_desc',
          child: Text('תאריך יעד (רחוק לקרוב)'),
        ),
        const PopupMenuItem(
          value: 'priority_desc',
          child: Text('עדיפות (גבוה לנמוך)'),
        ),
      ],
    );
  }
  
  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }
  
  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  bool _hasActiveFilters() {
    return _selectedType != null ||
           _selectedPriority != null ||
           _isCompleted != null ||
           _startDate != null ||
           _endDate != null;
  }
  
  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedType != null) count++;
    if (_selectedPriority != null) count++;
    if (_isCompleted != null) count++;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }
  
  void _handleTaskTap(Task task) {
    // TODO: Show task details
  }
  
  void _handleTaskCompleted(Task task) {
    // Remove from search results if it was marked as completed
    setState(() {
      _searchResults.removeWhere((t) => t.id == task.id);
    });
  }
}
