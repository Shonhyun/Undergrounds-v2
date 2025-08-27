import 'package:cloud_firestore/cloud_firestore.dart';

// Function returns question with subject, specific creation date, author name, and author's school
Future<List<Map<String, dynamic>>> fetchQuestions({
  String? authorId,
  String? subject,
  DateTime? specificDate,
}) async {
  try {
    // Fetch approved questions from firestore
    Query query = await FirebaseFirestore.instance
        .collection('library')
        .doc('questions')
        .collection('items')
        .where('approved', isEqualTo: true);

    // Author filter
    if (authorId != null) {
      query = query.where('authorId', isEqualTo: authorId);
    }

    // Subject filter
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }

    // Date filter
    if (specificDate != null) {
      final start = Timestamp.fromDate(
        DateTime(specificDate.year, specificDate.month, specificDate.day),
      );
      final end = Timestamp.fromDate(specificDate.add(Duration(days: 1)));
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end);
    }

    // Execute query
    final querySnapshot =
        await query.orderBy('createdAt', descending: true).get();

    // Collect question data and authorIds for enrichment
    final List<Map<String, dynamic>> fetchedQuestions = [];
    final Set<String> authorIds = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final authorId = data['authorId'];
      if (authorId != null) authorIds.add(authorId);
      fetchedQuestions.add({...data, 'id': doc.id});
    }

    // Fetches author and school info for each authorId
    final Map<String, String> authorIdToName = {};
    final Map<String, String> authorIdToSchool = {};

    for (final id in authorIds) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        authorIdToName[id] = userData?['fullName'] ?? 'Unknown Author';
        authorIdToSchool[id] = userData?['schoolName'] ?? 'Unknown School';
      } else {
        authorIdToName[id] = 'Unknown Author';
        authorIdToSchool[id] = 'Unknown School';
      }
    }

    // Enrich each question with author and school info
    return fetchedQuestions.map((q) {
      final authorId = q['authorId'];
      return {
        ...q,
        'author': authorIdToName[authorId] ?? 'Unknown Author',
        'schoolName': authorIdToSchool[authorId] ?? 'Unknown School',
      };
    }).toList();
  } catch (e) {
    print("Error fetching questions: $e");
    rethrow; // So the calling widget can handle the error
  }
}
