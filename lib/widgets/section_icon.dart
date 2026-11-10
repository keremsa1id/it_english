import 'package:flutter/material.dart';

import '../models/section.dart';

/// Bölüm türünün menü kartlarında gösterilen simgesi.
IconData sectionIcon(SectionKind kind) => switch (kind) {
      SectionKind.itTerms => Icons.computer_rounded,
      SectionKind.advancedIt => Icons.code_rounded,
      SectionKind.verbs => Icons.directions_run_rounded,
      SectionKind.nouns => Icons.category_rounded,
      SectionKind.adjectives => Icons.palette_rounded,
      SectionKind.adverbs => Icons.speed_rounded,
      SectionKind.phrases => Icons.chat_bubble_rounded,
      SectionKind.phrasalVerbs => Icons.extension_rounded,
      SectionKind.idioms => Icons.lightbulb_rounded,
      SectionKind.linkers => Icons.link_rounded,
      SectionKind.prepositions => Icons.place_rounded,
      SectionKind.chat => Icons.forum_rounded,
      SectionKind.meetings => Icons.video_call_rounded,
      SectionKind.interview => Icons.work_rounded,
      SectionKind.errors => Icons.error_outline_rounded,
      SectionKind.falseFriends => Icons.warning_amber_rounded,
      SectionKind.confusables => Icons.compare_arrows_rounded,
      SectionKind.cyber => Icons.shield_rounded,
      SectionKind.weekly => Icons.calendar_month_rounded,
    };
