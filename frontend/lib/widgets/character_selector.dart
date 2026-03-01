import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class CharacterSelector extends StatelessWidget {
  final String selectedId;
  final Function(String) onSelect;

  const CharacterSelector({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AppConstants.characters.entries.map((entry) {
            final info = entry.value;
            final selected = selectedId == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? info.color.withOpacity(0.35)
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? info.color : AppTheme.borderColor,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: info.color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info.emoji,
                          style: TextStyle(
                              fontSize: selected ? 20 : 18)),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key == 'citizen'
                                ? 'Historian'
                                : info.name.split(' ').first,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white60,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (selected)
                            Text(
                              info.title.split('(').first.trim(),
                              style: TextStyle(
                                  color: info.accentColor,
                                  fontSize: 10),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
