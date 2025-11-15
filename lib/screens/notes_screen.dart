import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'dart:html' show AnchorElement, document;

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? _selectedCourse;
  List<String> _availableCourses = ['All Courses'];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final snapshot = await _firestore.collection('notes').get();
    final courses = <String>{};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final course = data['course'];
      if (course != null && course.toString().isNotEmpty) {
        courses.add(course.toString());
      }
    }
    
    setState(() {
      _availableCourses = ['All Courses', ...courses.toList()]..sort();
    });
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final courseController = TextEditingController();
    final descController = TextEditingController();
    PlatformFile? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.cloud_upload, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Upload Course Material'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File size info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Maximum file size: 1MB\nSupported: PDF, JPG, PNG',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g., Midterm Notes Chapter 1-5',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    enabled: !isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: courseController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Course Code *',
                      hintText: 'e.g., CS101, MATH201',
                      prefixIcon: const Icon(Icons.school),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    enabled: !isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'What does this material cover?',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    enabled: !isUploading,
                  ),
                  const SizedBox(height: 16),
                  
                  // File Picker Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedFile != null 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedFile != null 
                            ? Colors.green 
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          selectedFile != null 
                              ? Icons.check_circle 
                              : Icons.upload_file,
                          size: 48,
                          color: selectedFile != null 
                              ? Colors.green 
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        if (selectedFile == null)
                          Text(
                            'No file selected',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          )
                        else
                          Column(
                            children: [
                              Text(
                                selectedFile!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatFileSize(selectedFile!.size),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            );

                            if (result != null) {
                              final file = result.files.first;
                              
                              // Check file size (1MB = 1048576 bytes)
                              if (file.size > 1048576) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('File size must be less than 1MB'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              setDialogState(() {
                                selectedFile = file;
                              });
                            }
                          },
                          icon: const Icon(Icons.folder_open),
                          label: Text(selectedFile == null ? 'Select File' : 'Change File'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (isUploading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Uploading... Please wait',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: (isUploading || selectedFile == null) ? null : () async {
                  if (titleController.text.trim().isEmpty || 
                      courseController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Title and Course Code are required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setDialogState(() => isUploading = true);

                  try {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid == null) return;

                    final userDoc = await _firestore.collection('users').doc(uid).get();
                    final userName = userDoc.data()?['name'] ?? 'Anonymous';

                    // Convert file to base64
                    String base64File;
                    if (kIsWeb) {
                      // For web
                      base64File = base64Encode(selectedFile!.bytes!);
                    } else {
                      // For mobile
                      final bytes = await File(selectedFile!.path!).readAsBytes();
                      base64File = base64Encode(bytes);
                    }

                    // Get file extension
                    final extension = selectedFile!.extension ?? 'pdf';

                    // Save to Firestore
                    await _firestore.collection('notes').add({
                      'title': titleController.text.trim(),
                      'course': courseController.text.trim().toUpperCase(),
                      'description': descController.text.trim(),
                      'fileData': base64File,
                      'fileName': selectedFile!.name,
                      'fileSize': selectedFile!.size,
                      'fileExtension': extension,
                      'uploadedBy': userName,
                      'uploaderId': uid,
                      'timestamp': FieldValue.serverTimestamp(),
                      'likes': 0,
                      'downloads': 0,
                    });

                    await _loadCourses();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('File uploaded successfully!'),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Upload failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setDialogState(() => isUploading = false);
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadFile(String base64Data, String fileName, String extension, String noteId) async {
    try {
      // Increment download count first
      await _firestore.collection('notes').doc(noteId).update({
        'downloads': FieldValue.increment(1),
      });

      // Decode base64
      final bytes = base64Decode(base64Data);

      if (kIsWeb) {
        // For web - create a download link
        final blob = bytes;
        final url = Uri.dataFromBytes(blob, mimeType: _getMimeType(extension));
        
        // Create download link (this will open in new tab on web)
        final anchor = document.createElement('a') as AnchorElement
          ..href = url.toString()
          ..download = fileName
          ..style.display = 'none';
        
        document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download started! Check your downloads folder.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // For mobile - save to downloads (requires permission)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File: $fileName\nSize: ${_formatFileSize(bytes.length)}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // On mobile, you could use path_provider and open_file packages
                // For now, just show file info
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Course Materials'),
        actions: [
          PopupMenuButton<String>(
            icon: Row(
              children: [
                Text(
                  _selectedCourse ?? 'All Courses',
                  style: const TextStyle(fontSize: 14),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              setState(() {
                _selectedCourse = value == 'All Courses' ? null : value;
              });
            },
            itemBuilder: (context) => _availableCourses
                .map((course) => PopupMenuItem(
                      value: course,
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(course),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _selectedCourse == null
            ? _firestore.collection('notes').orderBy('timestamp', descending: true).snapshots()
            : _firestore
                .collection('notes')
                .where('course', isEqualTo: _selectedCourse)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedCourse == null
                        ? 'No materials uploaded yet'
                        : 'No materials for $_selectedCourse',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to upload study materials!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final dateStr = timestamp != null
                  ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
                  : 'Just now';
              final extension = data['fileExtension'] ?? 'pdf';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['course'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (data['uploaderId'] == FirebaseAuth.instance.currentUser?.uid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Your Upload',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        data['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E2C),
                        ),
                      ),

                      // Description
                      if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          data['description'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],

                      // File Info Card
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getFileColor(extension).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getFileColor(extension).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(extension),
                              size: 32,
                              color: _getFileColor(extension),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['fileName'] ?? 'Unknown file',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatFileSize(data['fileSize'] ?? 0),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info Row
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            data['uploadedBy'] ?? 'Anonymous',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Action Buttons Row
                      Row(
                        children: [
                          // Download Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _downloadFile(
                                data['fileData'] ?? '',
                                data['fileName'] ?? 'file',
                                extension,
                                doc.id,
                              ),
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Download'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Like Button
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () async {
                                await doc.reference.update({
                                  'likes': FieldValue.increment(1),
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.thumb_up_outlined, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${data['likes'] ?? 0}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Delete Button (only for owner)
                          if (data['uploaderId'] == FirebaseAuth.instance.currentUser?.uid) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Delete Material'),
                                    content: const Text(
                                      'Are you sure you want to delete this file?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await doc.reference.delete();
                                  await _loadCourses();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('File deleted'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ],
                      ),

                      // Stats Row
                      if (data['downloads'] != null && data['downloads'] > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.download, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${data['downloads']} downloads',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

