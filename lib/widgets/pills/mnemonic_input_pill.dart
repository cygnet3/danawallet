import 'package:bitcoin_ui/bitcoin_ui.dart';
import 'package:danawallet/constants.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MnemonicInputPill extends StatefulWidget {
  final int number;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String)? onSubmitted;

  const MnemonicInputPill(
      {super.key,
      required this.number,
      required this.controller,
      this.onSubmitted,
      required this.focusNode});

  @override
  State<MnemonicInputPill> createState() => _MnemonicInputPillState();
}

class _MnemonicInputPillState extends State<MnemonicInputPill> {
  List<String> suggestions = [];
  bool showSuggestions = false;
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) {
      _removeOverlay();
      return;
    }

    // Filter BIP39 words that start with the input
    final filteredSuggestions = bip39Words
        .where((word) => word.startsWith(text))
        .take(5) // Show top 5 suggestions
        .toList();

    setState(() {
      suggestions = filteredSuggestions;
      showSuggestions = filteredSuggestions.isNotEmpty;
    });

    if (showSuggestions) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: _getOverlayTop(),
        left: _getOverlayLeft(),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: _getOverlayWidth(),
            constraints: const BoxConstraints(
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    suggestions[index],
                    style: BitcoinTextStyle.body3(Colors.black),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onTap: () {
                    widget.controller.text = suggestions[index];
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestions[index].length),
                    );
                    _removeOverlay();
                    widget.focusNode.nextFocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  double _getOverlayTop() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0;
    final position = renderBox.localToGlobal(Offset.zero);
    return position.dy + renderBox.size.height;
  }

  double _getOverlayLeft() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 0;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calculate the width of the number part (approximately 1/4 of total width)
    final numberPartWidth = renderBox.size.width * 0.25;

    // Position the popup to align with the text input part
    return position.dx + numberPartWidth;
  }

  double _getOverlayWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return 200;

    // Get the screen width and current position
    final screenWidth = MediaQuery.of(context).size.width;
    final currentLeft = _getOverlayLeft();

    // Calculate available width on the right side
    final availableWidthRight = screenWidth - currentLeft - 20; // 20px margin

    // Use 75% of the input field width (the text input part)
    final inputWidth = renderBox.size.width * 0.75;

    // Use the smaller of available space or input width, but ensure minimum readability
    final optimalWidth =
        availableWidthRight < inputWidth ? availableWidthRight : inputWidth;

    return optimalWidth > 120 ? optimalWidth : 120;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Adaptive.h(6), // Define a fixed height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
              child: Container(
            decoration: BoxDecoration(
                color: Bitcoin.neutral3,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                )),
            child: Center(
                child: Text(widget.number.toString(),
                    style: BitcoinTextStyle.title5(Bitcoin.black)
                    // .copyWith(fontFamily: "Inter"),
                    )),
          )),
          const SizedBox(width: 5.0),
          Flexible(
              flex: 3,
              child: Container(
                  decoration: BoxDecoration(
                      // border: Border.all(color: Bitcoin.black),
                      color: Bitcoin.neutral2,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      )),
                  child: Center(
                    child: TextField(
                      controller: widget.controller,
                      onSubmitted: widget.onSubmitted,
                      focusNode: widget.focusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 15.0),
                        hintText: 'word',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ))),
        ],
      ),
    );
  }
}
