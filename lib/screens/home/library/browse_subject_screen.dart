import 'package:flutter/material.dart';
import 'package:learningexamapp/utils/common_widgets/fetch_questions.dart';
import 'package:learningexamapp/utils/common_widgets/library/question_UI.dart'; // This file contains QuestionListWidget
import 'package:learningexamapp/utils/common_widgets/slide_animation.dart';

class BrowseBySubjectScreen extends StatefulWidget {
  const BrowseBySubjectScreen({super.key, Map<String, dynamic>? userData});

  @override
  State<BrowseBySubjectScreen> createState() => _BrowseBySubjectScreenState();
}

class _BrowseBySubjectScreenState extends State<BrowseBySubjectScreen> {
  Future<Map<String, List<Map<String, dynamic>>>> subjectData = Future.value(
    {},
  );
  Map<String, List<Map<String, dynamic>>> subjectQuestions = {};
  List<String> subjectNames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    subjectData = fetchSubjectQuestions();
  }

  Future<Map<String, List<Map<String, dynamic>>>>
  fetchSubjectQuestions() async {
    try {
      final enrichedQuestions = await fetchQuestions();

      final Map<String, List<Map<String, dynamic>>> groupedBySubject = {};

      for (final question in enrichedQuestions) {
        final subject = question['subject'] ?? 'Unknown Subject';
        groupedBySubject.putIfAbsent(subject, () => []).add(question);
      }

      setState(() {
        subjectQuestions = groupedBySubject;
        subjectNames = groupedBySubject.keys.toList();
        isLoading = false;
      });

      return groupedBySubject;
    } catch (e) {
      print("Error in BrowseBySubjectScreen: $e");
      setState(() {
        isLoading = false;
      });
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text("Browse by Subject"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                future: subjectData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No subjects found."));
                  }

                  final data = snapshot.data!;
                  final subjects = data.keys.toList();

                  return ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subjectName = subjects[index];
                      final questionsForSubject = data[subjectName]!;

                      final topicMap = <String, List<Map<String, dynamic>>>{};
                      for (var q in questionsForSubject) {
                        final topic = q['topic'] ?? 'Unknown';
                        topicMap.putIfAbsent(topic, () => []).add(q);
                      }
                      final topics =
                          topicMap.keys.map((name) => {"name": name}).toList();

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
                              subjectName[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(subjectName),
                          subtitle: Text(
                            "${questionsForSubject.length} questions added",
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              slideForward(
                                TopicQuestionsScreen(
                                  subjectName: subjectName,
                                  topics: topics,
                                  questions: questionsForSubject,
                                ),
                              )
                            );
                          },
                        ),
                      );
                    },
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

// Topics Questions Screen (No changes needed here as it doesn't directly use QuestionListWidget)
class TopicQuestionsScreen extends StatefulWidget {
  final String subjectName;
  final List<Map<String, dynamic>> topics;
  final List<Map<String, dynamic>> questions;

  const TopicQuestionsScreen({
    super.key,
    required this.subjectName,
    required this.topics,
    required this.questions,
  });

  @override
  State<TopicQuestionsScreen> createState() => _TopicQuestionsScreenState();
}

class _TopicQuestionsScreenState extends State<TopicQuestionsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text("${widget.subjectName} Topics"),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child:
                  widget.topics.isEmpty
                      ? const Center(
                        child: Text("No topics found for this subject."),
                      )
                      : ListView.builder(
                        itemCount: widget.topics.length,
                        itemBuilder: (context, index) {
                          final name = widget.topics[index]['name'];
                          final topicQuestions =
                              widget.questions
                                  .where(
                                    (q) =>
                                        (q['topic'] ?? '')
                                            .toString()
                                            .toLowerCase() ==
                                        name.toLowerCase(),
                                  )
                                  .toList();
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  name[0],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(name),
                              subtitle: Text(
                                "${topicQuestions.length} questions added",
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  slideForward(
                                    DisplayQuestionsScreen(
                                          topicName: name,
                                          questions: topicQuestions,
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

// Display Questions Screen (Changes applied here)
class DisplayQuestionsScreen extends StatefulWidget {
  final String topicName;
  final List<Map<String, dynamic>> questions;

  const DisplayQuestionsScreen({
    super.key,
    required this.topicName,
    required this.questions,
  });

  @override
  State<DisplayQuestionsScreen> createState() => _DisplayQuestionsScreenState();
}

class _DisplayQuestionsScreenState extends State<DisplayQuestionsScreen> {
  // Only selectedAnswers is needed now.
  // answerResults is removed as it's not used by the current QuestionListWidget.
  Map<int, String?> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.topicName),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body:
          widget.questions.isEmpty
              ? const Center(child: Text("No questions found for this topic."))
              : QuestionListWidget(
                questions: widget.questions,
                isLoading: false,
                selectedAnswers: {
                  // Ensure selectedAnswers is correctly built
                  for (
                    int i = 0;
                    i < widget.questions.length;
                    i++
                  ) // Iterate based on questions length
                    if (selectedAnswers.containsKey(i) &&
                        selectedAnswers[i] !=
                            null) // Check if key exists and value is not null
                      i: selectedAnswers[i]!,
                },
                // Removed answerResults parameter
                // Removed onSubmit parameter
                onAnswerSelected: (index, selected) {
                  setState(() {
                    selectedAnswers[index] = selected;
                  });
                },
              ),
    );
  }
}
