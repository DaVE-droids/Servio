import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../providers/firebase_providers.dart';
import '../result/result.dart';
import '../services/maps_service.dart';

/// Address field with live search suggestions (LocationIQ-backed). The user
/// picks a real suggested address rather than typing free text that later
/// gets blindly geocoded — the picked suggestion already carries its own
/// coordinates. See docs/LOCATION_SERVICES.md.
class AddressSearchField extends ConsumerStatefulWidget {
  /// Creates an address search field.
  const AddressSearchField({
    required this.controller,
    required this.onSelected,
    this.countryCode,
    this.errorText,
    this.enabled = true,
    this.onTextEdited,
    super.key,
  });

  /// Text controller backing the field.
  final TextEditingController controller;

  /// Called when the user picks a suggestion.
  final ValueChanged<AddressSuggestion> onSelected;

  /// Restricts suggestions to this ISO 3166-1 alpha-2 country code.
  final String? countryCode;

  /// Optional validation error to display.
  final String? errorText;

  /// Whether the field accepts input.
  final bool enabled;

  /// Called whenever the user edits the text, so a caller can clear a
  /// previously selected suggestion that no longer matches what's typed.
  final VoidCallback? onTextEdited;

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onTextEdited?.call();
    _debounce?.cancel();
    setState(() => _searchError = null);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    if (!mounted) {
      return;
    }
    setState(() => _isSearching = true);
    final result = await ref
        .read(mapsServiceProvider)
        .searchAddress(value, countryCode: widget.countryCode);
    if (!mounted) {
      return;
    }
    switch (result) {
      case Success<List<AddressSuggestion>>(:final data):
        setState(() {
          _suggestions = data;
          _isSearching = false;
        });
      case Failure<List<AddressSuggestion>>(:final error):
        setState(() {
          _suggestions = [];
          _isSearching = false;
          _searchError = error.message;
        });
    }
  }

  void _select(AddressSuggestion suggestion) {
    widget.controller.text = suggestion.displayName;
    setState(() => _suggestions = []);
    _focusNode.unfocus();
    widget.onSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          maxLines: 2,
          minLines: 1,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Company address',
            hintText: 'Start typing, then pick from the list',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            errorText: widget.errorText ?? _searchError,
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0) const Divider(),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 20),
                    title: Text(_suggestions[i].displayName),
                    onTap: () => _select(_suggestions[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
