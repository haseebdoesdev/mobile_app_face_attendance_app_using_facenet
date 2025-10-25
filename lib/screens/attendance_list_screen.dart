import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../models/attendance_record.dart';

class AttendanceListScreen extends StatefulWidget {
  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<AttendanceRecord> _todayAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() => _isLoading = true);
    final records = await _attendanceService.getTodayAttendance();
    setState(() {
      _todayAttendance = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteAttendance(AttendanceRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unmark Attendance'),
        content: Text('Remove ${record.name} from today\'s attendance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _attendanceService.deleteAttendance(record.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.name} unmarked')),
      );
      _loadTodayAttendance();
    }
  }

  Future<void> _clearAllAttendance() async {
    if (_todayAttendance.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Attendance'),
        content: Text('Remove all ${_todayAttendance.length} attendance records for today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _attendanceService.deleteAllTodayAttendance();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All attendance cleared')),
      );
      _loadTodayAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Attendance'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_todayAttendance.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _clearAllAttendance,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _todayAttendance.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'No attendance marked today',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTodayAttendance,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _todayAttendance.length,
                    itemBuilder: (context, index) {
                      final record = _todayAttendance[index];
                      return Dismissible(
                        key: Key(record.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Unmark Attendance'),
                              content: Text('Remove ${record.name} from today\'s attendance?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await _attendanceService.deleteAttendance(record.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${record.name} unmarked'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () async {
                                  await _attendanceService.insertAttendance(record);
                                  _loadTodayAttendance();
                                },
                              ),
                            ),
                          );
                          _loadTodayAttendance();
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete, color: Colors.white, size: 32),
                        ),
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                            title: Text(
                              record.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Marked at ${record.time}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Present',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

