import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const FitnessTrackerApp());
}

/// The root application widget.
/// Sets up a modern dark theme using Material 3 with teal and cyan accents.
class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to dark mode for a premium aesthetic
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488), // Teal accent
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D9488), // Teal 600
          secondary: Color(0xFF06B6D4), // Cyan 500
          surface: Color(0xFF1E293B), // Slate 800
          onSurface: Color(0xFFF8FAFC), // Slate 50
          error: Color(0xFFEF4444), // Red 500
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B), // Slate 800
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.2),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E293B), // Slate 800
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const FitnessTrackerHomeScreen(),
    );
  }
}

/// Supported workout types with their MET values, display names, custom icons, and color themes.
enum ActivityType {
  walking,
  running,
  cycling,
  swimming,
  yoga,
  skipping,
  gymWorkout;

  String get displayName {
    switch (this) {
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.swimming:
        return 'Swimming';
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.skipping:
        return 'Skipping';
      case ActivityType.gymWorkout:
        return 'Gym Workout';
    }
  }

  double get met {
    switch (this) {
      case ActivityType.walking:
        return 3.5;
      case ActivityType.running:
        return 8.0;
      case ActivityType.cycling:
        return 7.5;
      case ActivityType.swimming:
        return 6.0;
      case ActivityType.yoga:
        return 2.5;
      case ActivityType.skipping:
        return 10.0;
      case ActivityType.gymWorkout:
        return 5.0;
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.walking:
        return Icons.directions_walk_rounded;
      case ActivityType.running:
        return Icons.directions_run_rounded;
      case ActivityType.cycling:
        return Icons.directions_bike_rounded;
      case ActivityType.swimming:
        return Icons.pool_rounded;
      case ActivityType.yoga:
        return Icons.self_improvement_rounded;
      case ActivityType.skipping:
        return Icons.offline_bolt_rounded;
      case ActivityType.gymWorkout:
        return Icons.fitness_center_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.walking:
        return const Color(0xFF10B981); // Emerald Green
      case ActivityType.running:
        return const Color(0xFFF97316); // Orange
      case ActivityType.cycling:
        return const Color(0xFF3B82F6); // Blue
      case ActivityType.swimming:
        return const Color(0xFF06B6D4); // Cyan
      case ActivityType.yoga:
        return const Color(0xFF8B5CF6); // Purple
      case ActivityType.skipping:
        return const Color(0xFFF59E0B); // Amber
      case ActivityType.gymWorkout:
        return const Color(0xFFEF4444); // Red
    }
  }
}

/// Model representing a logged workout activity.
class Activity {
  final String id;
  final ActivityType type;
  final double duration; // in minutes
  final double weight; // in kg
  final double caloriesBurned;
  final DateTime dateTime;

  Activity({
    required this.id,
    required this.type,
    required this.duration,
    required this.weight,
    required this.caloriesBurned,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'duration': duration,
    'weight': weight,
    'caloriesBurned': caloriesBurned,
    'dateTime': dateTime.toIso8601String(),
  };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'],
    type: ActivityType.values.byName(json['type']),
    duration: (json['duration'] as num).toDouble(),
    weight: (json['weight'] as num).toDouble(),
    caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
    dateTime: DateTime.parse(json['dateTime']),
  );

  /// Helper to calculate calories using formula: Calories = MET * Weight (kg) * (Duration (mins) / 60)
  static double calculateCalories(ActivityType type, double weight, double durationMins) {
    return type.met * weight * (durationMins / 60.0);
  }
}

/// The Main Dashboard / Home Screen of the Fitness Tracker.
class FitnessTrackerHomeScreen extends StatefulWidget {
  const FitnessTrackerHomeScreen({Key? key}) : super(key: key);

  @override
  State<FitnessTrackerHomeScreen> createState() => _FitnessTrackerHomeScreenState();
}

class _FitnessTrackerHomeScreenState extends State<FitnessTrackerHomeScreen> {
  // Global key for handling list item animations natively in a ScrollView
  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey<SliverAnimatedListState>();

  // In-memory data list for activity logs
  final List<Activity> _activities = [];

  // Loading and initialization states
  bool _isLoading = true;
  bool _isProfileSetupDone = false;

  // Track last weight entered to automatically prefill and improve user experience
  double _lastWeight = 70.0;

  // User profile information
  String _userName = 'Fitness Enthusiast';
  double _userHeight = 175.0;
  int _userAge = 25;

  // Daily target values for the dashboard progress rings
  double _calorieGoal = 1000.0;
  double _durationGoal = 60.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isProfileSetupDone = prefs.getBool('profile_setup_done') ?? false;
        if (_isProfileSetupDone) {
          _userName = prefs.getString('user_name') ?? 'Fitness Enthusiast';
          _userAge = prefs.getInt('user_age') ?? 25;
          _userHeight = prefs.getDouble('user_height') ?? 175.0;
          _lastWeight = prefs.getDouble('user_weight') ?? 70.0;
          _calorieGoal = prefs.getDouble('calorie_goal') ?? 1000.0;
          _durationGoal = prefs.getDouble('duration_goal') ?? 60.0;
        }

        // Load activities
        final activitiesJson = prefs.getString('activities_list');
        if (activitiesJson != null) {
          final List<dynamic> decoded = jsonDecode(activitiesJson);
          _activities.clear();
          _activities.addAll(decoded.map((item) => Activity.fromJson(item)).toList());
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setInt('user_age', _userAge);
    await prefs.setDouble('user_height', _userHeight);
    await prefs.setDouble('user_weight', _lastWeight);
    await prefs.setDouble('calorie_goal', _calorieGoal);
    await prefs.setDouble('duration_goal', _durationGoal);
    await prefs.setBool('profile_setup_done', true);
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _activities.map((a) => a.toJson()).toList();
    await prefs.setString('activities_list', jsonEncode(jsonList));
  }

  // Calculate totals dynamically
  double get _totalCaloriesBurned => _activities.fold(0.0, (sum, item) => sum + item.caloriesBurned);
  double get _totalDuration => _activities.fold(0.0, (sum, item) => sum + item.duration);

  /// Helper method to format date-time without external libraries
  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute';
  }

  /// Inserts a new workout activity to the beginning of the list and triggers the animation.
  void _addWorkout(ActivityType type, double duration, double weight) {
    final calories = Activity.calculateCalories(type, weight, duration);
    final newWorkout = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      duration: duration,
      weight: weight,
      caloriesBurned: calories,
      dateTime: DateTime.now(),
    );

    setState(() {
      _activities.insert(0, newWorkout);
      _lastWeight = weight; // Cache the weight
    });

    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 350));
    _saveActivities();
    _saveProfileData(); // Save last weight to profile preferences
  }

  /// Prompts a dialog confirming deletion, then executes the exit animation and removes the item.
  Future<void> _confirmDelete(int index) async {
    final activityToDelete = _activities[index];

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 28),
              const SizedBox(width: 10),
              const Text('Delete Activity'),
            ],
          ),
          content: Text(
            'Are you sure you want to remove this ${activityToDelete.type.displayName} workout logged on ${_formatDateTime(activityToDelete.dateTime)}?',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _removeWorkout(index);
    }
  }

  /// Removes an activity from the internal data model and plays the slice-out animation.
  void _removeWorkout(int index) {
    final removedItem = _activities[index];

    // Remove from backing list
    setState(() {
      _activities.removeAt(index);
    });

    // Animate item removal out of view
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildActivityCard(removedItem, animation, -1, isDeleting: true),
      duration: const Duration(milliseconds: 250),
    );
    _saveActivities();
  }

  /// Shows the dialog to add a new workout.
  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddActivityDialog(
        initialWeight: _lastWeight,
        onSubmit: _addWorkout,
      ),
    );
  }

  /// Shows the dialog to view and edit user profile details and goals.
  void _showProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ProfileDialog(
        currentName: _userName,
        currentAge: _userAge,
        currentHeight: _userHeight,
        currentWeight: _lastWeight,
        currentCalorieGoal: _calorieGoal,
        currentDurationGoal: _durationGoal,
        onSave: (name, age, height, weight, calorieGoal, durationGoal) {
          setState(() {
            _userName = name;
            _userAge = age;
            _userHeight = height;
            _lastWeight = weight;
            _calorieGoal = calorieGoal;
            _durationGoal = durationGoal;
          });
          _saveProfileData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Your Fitness Dashboard...',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isProfileSetupDone) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ProfileSetupForm(
                onComplete: (name, age, height, weight, calorieGoal, durationGoal) {
                  setState(() {
                    _userName = name;
                    _userAge = age;
                    _userHeight = height;
                    _lastWeight = weight;
                    _calorieGoal = calorieGoal;
                    _durationGoal = durationGoal;
                    _isProfileSetupDone = true;
                  });
                  _saveProfileData();
                },
              ),
            ),
          ),
        ),
      );
    }

    // Determine screen sizing for responsive width limit
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width > 680;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Prevent infinite stretching on large desktop/web screens
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Dashboard Custom Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fitness Tracker',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Hello, $_userName',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        // Profile Avatar Button
                        Material(
                          color: Colors.transparent,
                          child: Tooltip(
                            message: 'User Profile & Goals',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: _showProfileDialog,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 26),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Responsive Summary Performance Ring Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: isWide
                        ? Row(
                            children: [
                              Expanded(child: _buildCalorieCard()),
                              const SizedBox(width: 12),
                              Expanded(child: _buildDurationCard()),
                              const SizedBox(width: 12),
                              Expanded(child: _buildWorkoutCountCard()),
                            ],
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildCalorieCard()),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildDurationCard()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildWorkoutCountCard(fullWidth: true),
                            ],
                          ),
                  ),
                ),

                // Activity History Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Workout History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_activities.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_activities.length} ${_activities.length == 1 ? "Session" : "Sessions"}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Empty State or List of Workouts
                _activities.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverAnimatedList(
                          key: _listKey,
                          initialItemCount: _activities.length,
                          itemBuilder: (context, index, animation) {
                            return _buildActivityCard(_activities[index], animation, index);
                          },
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWorkoutDialog,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
      ),
    );
  }

  /// Custom Card Widget for Calories Burned stat
  Widget _buildCalorieCard() {
    double progress = _calorieGoal > 0 ? (_totalCaloriesBurned / _calorieGoal) : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Burned',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_totalCaloriesBurned.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${_calorieGoal.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildCircularProgress(progress, const Color(0xFFF97316), Icons.local_fire_department_rounded),
          ],
        ),
      ),
    );
  }

  /// Custom Card Widget for Active Duration stat
  Widget _buildDurationCard() {
    double progress = _durationGoal > 0 ? (_totalDuration / _durationGoal) : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Time',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_totalDuration.toStringAsFixed(0)} min',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Goal: ${_durationGoal.toStringAsFixed(0)} min',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildCircularProgress(progress, const Color(0xFF06B6D4), Icons.timer_rounded),
          ],
        ),
      ),
    );
  }

  /// Custom Card Widget for workout counter
  Widget _buildWorkoutCountCard({bool fullWidth = false}) {
    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Workouts',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_activities.length} logged sessions',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          if (fullWidth)
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
        ],
      ),
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: Card(child: content))
        : Card(child: content);
  }

  /// Circular Progress Ring used in the Summary Cards
  Widget _buildCircularProgress(double percentage, Color color, IconData icon) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: 4.5,
            color: color,
            backgroundColor: color.withOpacity(0.12),
          ),
          Icon(
            icon,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// Builder for list items, representing activity logs
  Widget _buildActivityCard(Activity activity, Animation<double> animation, int index, {bool isDeleting = false}) {
    // Fade and slide transitions
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    // Icon inside customized circle Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: activity.type.color.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: activity.type.color.withOpacity(0.2), width: 1.5),
                      ),
                      child: Icon(
                        activity.type.icon,
                        color: activity.type.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Middle Section with Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.type.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.duration.toStringAsFixed(0)} min  •  ${activity.weight.toStringAsFixed(0)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(activity.dateTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Section with Calories and Delete button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${activity.caloriesBurned.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: activity.type.color,
                          ),
                        ),
                        if (!isDeleting)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 20,
                            ),
                            onPressed: () => _confirmDelete(index),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Beautiful empty-state widget when there are no logged entries.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Keep Up the Momentum!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 250,
            child: Text(
              'No workout logged for this session. Press the button below to add your first activity!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stateful Dialog widget to input workout details.
/// Features live validation & live calorie count calculations.
class AddActivityDialog extends StatefulWidget {
  final double initialWeight;
  final Function(ActivityType type, double duration, double weight) onSubmit;

  const AddActivityDialog({
    Key? key,
    required this.initialWeight,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();

  // Input Controllers
  late final TextEditingController _durationController;
  late final TextEditingController _weightController;

  // Selected Activity State
  ActivityType _selectedType = ActivityType.walking;

  // Calculated Preview Value
  double _liveCalories = 0.0;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController();
    _weightController = TextEditingController(text: widget.initialWeight.toStringAsFixed(0));

    // Listeners for live estimation recalculation
    _durationController.addListener(_recalculateCalories);
    _weightController.addListener(_recalculateCalories);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Recalculates estimated calories in real-time as users type.
  void _recalculateCalories() {
    final duration = double.tryParse(_durationController.text);
    final weight = double.tryParse(_weightController.text);

    if (duration != null && weight != null && duration > 0 && weight > 0) {
      setState(() {
        _liveCalories = Activity.calculateCalories(_selectedType, weight, duration);
      });
    } else {
      setState(() {
        _liveCalories = 0.0;
      });
    }
  }

  /// Submit function after validation checks
  void _submit() {
    if (_formKey.currentState!.validate()) {
      final duration = double.parse(_durationController.text);
      final weight = double.parse(_weightController.text);

      widget.onSubmit(_selectedType, duration, weight);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedType.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_selectedType.icon, color: _selectedType.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Log Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Activity Dropdown Selection
                DropdownButtonFormField<ActivityType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.fitness_center_rounded, size: 20),
                  ),
                  items: ActivityType.values.map((ActivityType type) {
                    return DropdownMenuItem<ActivityType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 18, color: type.color),
                          const SizedBox(width: 10),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (ActivityType? value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                      _recalculateCalories();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Duration Text Input Field
                TextFormField(
                  controller: _durationController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: 'e.g. 30',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.timer_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Duration is required';
                    }
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Enter a positive number';
                    }
                    if (number > 1440) {
                      return 'Duration cannot exceed 24 hours';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Weight Text Input Field
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'User Weight (kg)',
                    hintText: 'e.g. 70',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Weight is required';
                    }
                    final number = double.tryParse(value);
                    if (number == null || number <= 0) {
                      return 'Enter a positive number';
                    }
                    if (number > 500) {
                      return 'Enter a realistic weight';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Live Calories Calculator Banner Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _liveCalories > 0
                        ? _selectedType.color.withOpacity(0.08)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _liveCalories > 0
                          ? _selectedType.color.withOpacity(0.25)
                          : Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: _liveCalories > 0 ? _selectedType.color : Colors.white.withOpacity(0.2),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Energy Burned',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_liveCalories.toStringAsFixed(1)} kcal',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _liveCalories > 0 ? _selectedType.color : Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      child: const Text(
                        'Save Workout',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A stateful Dialog widget to input and edit user profile details and targets.
class ProfileDialog extends StatefulWidget {
  final String currentName;
  final int currentAge;
  final double currentHeight;
  final double currentWeight;
  final double currentCalorieGoal;
  final double currentDurationGoal;
  final Function(String name, int age, double height, double weight, double calorieGoal, double durationGoal) onSave;

  const ProfileDialog({
    Key? key,
    required this.currentName,
    required this.currentAge,
    required this.currentHeight,
    required this.currentWeight,
    required this.currentCalorieGoal,
    required this.currentDurationGoal,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _calorieGoalController;
  late final TextEditingController _durationGoalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _ageController = TextEditingController(text: widget.currentAge.toString());
    _heightController = TextEditingController(text: widget.currentHeight.toStringAsFixed(0));
    _weightController = TextEditingController(text: widget.currentWeight.toStringAsFixed(0));
    _calorieGoalController = TextEditingController(text: widget.currentCalorieGoal.toStringAsFixed(0));
    _durationGoalController = TextEditingController(text: widget.currentDurationGoal.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calorieGoalController.dispose();
    _durationGoalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text);
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      final calorieGoal = double.parse(_calorieGoalController.text);
      final durationGoal = double.parse(_durationGoalController.text);

      widget.onSave(name, age, height, weight, calorieGoal, durationGoal);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Profile & Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'User Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Age and Height side-by-side
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age (years)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final num = int.tryParse(value);
                          if (num == null || num <= 0 || num > 120) return 'Invalid age';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final num = double.tryParse(value);
                          if (num == null || num <= 50 || num > 300) return 'Invalid height';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weight Field
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Weight is required';
                    final num = double.tryParse(value);
                    if (num == null || num <= 0 || num > 500) return 'Invalid weight';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Daily Calorie Goal Field
                TextFormField(
                  controller: _calorieGoalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Calorie Goal (kcal)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.local_fire_department_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Goal is required';
                    final num = double.tryParse(value);
                    if (num == null || num <= 0) return 'Enter a positive goal';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Daily Active Time Goal Field
                TextFormField(
                  controller: _durationGoalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Active Time Goal (minutes)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: Icon(Icons.timer_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Goal is required';
                    final num = double.tryParse(value);
                    if (num == null || num <= 0) return 'Enter a positive goal';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A stateful widget to display the profile setup form on the very first app launch.
class ProfileSetupForm extends StatefulWidget {
  final Function(String name, int age, double height, double weight, double calorieGoal, double durationGoal) onComplete;

  const ProfileSetupForm({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends State<ProfileSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _calorieGoalController = TextEditingController(text: '1000');
  final _durationGoalController = TextEditingController(text: '60');

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _calorieGoalController.dispose();
    _durationGoalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text);
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      final calorieGoal = double.parse(_calorieGoalController.text);
      final durationGoal = double.parse(_durationGoalController.text);

      widget.onComplete(name, age, height, weight, calorieGoal, durationGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.5),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branding Logo & Greeting
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Welcome to Fitness Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Let\'s set up your profile and goals to customize your active workout tracking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'User Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age & Height
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age (years)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final num = int.tryParse(value);
                        if (num == null || num <= 0 || num > 120) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final num = double.tryParse(value);
                        if (num == null || num <= 50 || num > 300) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Current Weight (kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Weight is required';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0 || num > 500) return 'Invalid weight';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Calorie Goal
              TextFormField(
                controller: _calorieGoalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily Calorie Goal (kcal)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.local_fire_department_outlined, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Calorie goal required';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) return 'Enter a positive goal';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration Goal
              TextFormField(
                controller: _durationGoalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Daily Active Time Goal (minutes)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.timer_outlined, size: 20),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Active goal required';
                  final num = double.tryParse(value);
                  if (num == null || num <= 0) return 'Enter a positive goal';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Complete Setup',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
