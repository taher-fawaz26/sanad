import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_suggestion.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_chat_suggestions.dart';
import 'package:testing/testing.dart';

void main() {
  const suggestions = [
    AiChatSuggestion(id: 'a', labelKey: 'ai_chat.suggestion_renew_emirates_id'),
    AiChatSuggestion(id: 'b', labelKey: 'ai_chat.suggestion_passport_expiry'),
  ];

  testWidgets('every suggestion renders its localized label', (tester) async {
    await pumpDsWidget(
      tester,
      Scaffold(
        body: AiChatSuggestions(suggestions: suggestions, onSelected: (_) {}),
      ),
    );

    expect(
      find.text('ai_chat.suggestion_renew_emirates_id'),
      findsOneWidget,
    );
    expect(find.text('ai_chat.suggestion_passport_expiry'), findsOneWidget);
  });

  testWidgets('tapping one reports that suggestion, not the widget owning '
      'any send logic', (tester) async {
    AiChatSuggestion? selected;
    await pumpDsWidget(
      tester,
      Scaffold(
        body: AiChatSuggestions(
          suggestions: suggestions,
          onSelected: (s) => selected = s,
        ),
      ),
    );

    await tester.tap(find.text('ai_chat.suggestion_passport_expiry'));
    await tester.pump();

    expect(selected, suggestions[1]);
  });

  testWidgets('an empty suggestion list renders nothing, not an error', (
    tester,
  ) async {
    await pumpDsWidget(
      tester,
      Scaffold(
        body: AiChatSuggestions(suggestions: const [], onSelected: (_) {}),
      ),
    );

    expect(find.byType(AiChatSuggestions), findsOneWidget);
    expect(find.text('ai_chat.suggestion_renew_emirates_id'), findsNothing);
  });
}
