import 'package:flutter/material.dart';
import 'package:learningexamapp/utils/common_widgets/fetch_questions.dart';
import 'package:learningexamapp/utils/common_widgets/library/question_UI.dart';
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class BrowseByAuthorScreen extends StatefulWidget {
  const BrowseByAuthorScreen({super.key, Map<String, dynamic>? userData});

  @override
  State<BrowseByAuthorScreen> createState() => _BrowseByAuthorScreenState();
}

class _BrowseByAuthorScreenState extends State<BrowseByAuthorScreen> {
  String searchQuery = '';
  List<String> authorNames = [];
  Map<String, List<Map<String, dynamic>>> authorQuestions = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestionsFromFirestore();
  }

  Future<void> fetchQuestionsFromFirestore() async {
    try {
      final enrichedQuestions = await fetchQuestions();

      final Map<String, List<Map<String, dynamic>>> groupedByAuthor = {};

      // Reorganize data to focus on author
      for (final question in enrichedQuestions) {
        final name = question['author'] ?? 'Unknown Author';
        groupedByAuthor.putIfAbsent(name, () => []).add(question);
      }

      setState(() {
        authorQuestions = groupedByAuthor;
        authorNames = groupedByAuthor.keys.toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error in BrowseByAuthorScreen: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredAuthors =
        authorNames
            .where(
              (name) => name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Browse by Author"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search author",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          filteredAuthors.isEmpty
                              ? const Center(
                                child: Text("No matching authors found."),
                              )
                              : ListView.builder(
                                itemCount: filteredAuthors.length,
                                itemBuilder: (context, index) {
                                  final name = filteredAuthors[index];
                                  final questions = authorQuestions[name] ?? [];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.redAccent,
                                        child: Text(
                                          name[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(name),
                                      subtitle: Text(
                                        "${questions.length} questions added",
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          slideForward(
                                            AuthorQuestionsScreen(
                                              authorName: name,
                                              questions: questions,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class AuthorQuestionsScreen extends StatefulWidget {
  final String authorName;
  final List<Map<String, dynamic>> questions;

  const AuthorQuestionsScreen({
    super.key,
    required this.authorName,
    required this.questions,
  });

  @override
  State<AuthorQuestionsScreen> createState() => _AuthorQuestionsScreenState();
}

class _AuthorQuestionsScreenState extends State<AuthorQuestionsScreen> {
  // We still need selectedAnswers to track the user's choice before they submit
  late List<String?> selectedAnswers;

  @override
  void initState() {
    super.initState();
    final count = widget.questions.length;
    selectedAnswers = List<String?>.filled(count, null);
    // answerResults is no longer needed here as feedback is on a separate page
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.authorName),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body:
          widget.questions.isEmpty
              ? const Center(child: Text("No questions found for this author."))
              : Padding(
                padding: const EdgeInsets.all(16),
                child: QuestionListWidget(
                  questions: widget.questions,
                  isLoading: false,
                  onAnswerSelected: (index, answer) {
                    setState(() {
                      selectedAnswers[index] = answer;
                    });
                  },
                  selectedAnswers: {
                    for (int i = 0; i < selectedAnswers.length; i++)
                      if (selectedAnswers[i] != null) i: selectedAnswers[i]!,
                  },
                ),
              ),
    );
  }
}
