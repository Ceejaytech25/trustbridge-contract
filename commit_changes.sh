#!/bin/bash
# Git commit script for Issue #615: NFC/NFD Normalization Hardening

set -e

cd "$(dirname "$0")" || exit 1

# Configure git user
git config --local user.name "Ceejaytech25" || git config user.name "Ceejaytech25"
git config --local user.email "ceejaytech25@users.noreply.github.com" || git config user.email "ceejaytech25@users.noreply.github.com"

# Create feature branch if it doesn't exist
BRANCH="feat/nfc-homoglyph-corpus-615"
if ! git rev-parse --verify "$BRANCH" > /dev/null 2>&1; then
    git checkout -b "$BRANCH"
else
    git checkout "$BRANCH"
fi

# Add all changes
git add .

# Commit with the prepared message
git commit -F - << 'EOF'
test(security): nfc homoglyph corpus hardening #615

## Summary
Hardens username normalization against NFC/NFD edge-case attacks by implementing
comprehensive test coverage and documentation for Unicode normalization gaps.

## Changes

### Test Corpus (tests/homoglyph_corpus.rs)
- `test_nfc_nfd_normalization_edge_pairs_rejected`: Tests NFC vs NFD forms of
  accented letters (á, é, í, ó, ú, ã̀). Both forms are non-ASCII and rejected.
  
- `test_combining_marks_at_any_position_rejected`: Comprehensive combining mark
  testing at prefix, infix, suffix, and multiple positions. Covers U+0300–U+036F
  combining diacritics range.
  
- `test_nfc_nfd_lookalike_pairs_both_rejected`: Real-world homonym attack vectors
  (café, naïve) tested in both NFC and NFD normalizations.
  
- `test_normalization_never_reaches_canonicalize_username`: Integration test
  confirming validation gate rejects non-ASCII before canonicalize_username.

### Documentation (docs/SECURITY.md)
- New section: "NFC/NFD Normalization Policy (Issue #615)"
- Policy: Contract performs NO Unicode normalization; byte-level ASCII validation
- Rationale table: Shows NFC/NFD forms are both non-ASCII, rejected at byte level
- Edge cases: Composed accented, decomposed combining marks, mixed states
- Test coverage references and off-chain guidance

### Developer Guidance (docs/CONTRIBUTING.md)
- New section: "Normalization Policy (Issue #615)"
- Clear guidance on no normalization + byte-level ASCII validation
- Steps for adding new NFC/NFD test cases
- Recommended Unicode codepoint documentation format
- Bypass detection verification checklist

### Corpus Summary (tests/homoglyph_SUMMARY.md)
- Category #13: NFC/NFD Normalization Edge Pairs (Issue #615)
  - Lists all four new test functions
  - Explains composed vs decomposed forms
  - Real-world homonym examples
- Updated attack vectors with normalization ambiguity threat/defense/coverage
- Corpus size now: 90+ codepoints and normalization edge pairs

### Changelog (CHANGELOG.md)
- [1.2.0] entry for NFC/NFD normalization hardening
- Lists all test additions and documentation changes
- Confirms no ABI changes, maintains security guarantee

## Verification
✅ All new tests compile without warnings or errors
✅ No regressions: existing username_case_fold tests unaffected  
✅ SECURITY.md documents NFC policy explicitly
✅ CI homoglyph step remains blocking (test-homoglyph passes)
✅ Corpus covers 90+ codepoints and edge pairs

Closes #615
EOF

echo "✅ Changes committed to branch: $BRANCH"
echo ""
echo "To push to GitHub, run:"
echo "  git remote add origin https://github.com/Ceejaytech25/trustbridge-contract.git"
echo "  git push -u origin $BRANCH"
echo ""
echo "Then open a PR from $BRANCH to main"
