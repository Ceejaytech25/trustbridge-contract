# Issue #615: NFC/NFD Normalization Hardening Implementation Summary

## Overview
This implementation adds comprehensive NFC/NFD normalization edge-case testing and documentation to harden the username validation against homoglyph attacks that might exploit Unicode normalization gaps.

## Changes Made

### 1. Test Corpus Additions (tests/homoglyph_corpus.rs)
Added four new test functions to cover NFC/NFD edge cases:

#### `test_nfc_nfc_nfc_nfd_normalization_edge_pairs_rejected()`
- Tests NFC (composed) vs NFD (decomposed) forms of common accented letters
- Covers: á, é, í, ó, ú (single character variants)
- Covers: ã̀ (multi-combining mark case)
- Both forms verified as non-ASCII and rejected
- Example: `café` (NFC: U+00E9) vs `cafe´` (NFD: U+0301)

#### `test_combining_marks_at_any_position_rejected()`
- Comprehensive test for combining diacritical marks (U+0300–U+036F)
- Tests marks at prefix, infix, and suffix positions
- Tests multiple combining marks in sequence
- Covers: grave, acute, circumflex, tilde, diaeresis, cedilla, ring above
- All rejected as non-ASCII bytes

#### `test_nfc_nfd_lookalike_pairs_both_rejected()`
- Real-world homonym attack vectors tested in both normalizations
- Examples: café (NFC/NFD), naïve (NFC/NFD)
- Ensures visual lookalikes are rejected regardless of representation

#### `test_normalization_never_reaches_canonicalize_username()`
- Integration test verifying validation gate rejects non-ASCII before canonicalization
- Tests NFC-composed form rejection at registration boundary
- Tests NFD-decomposed form rejection at registration boundary
- Positive control: pure ASCII still accepted
- Confirms registration path consistency

### 2. Security Documentation (docs/SECURITY.md)
Added comprehensive "NFC/NFD Normalization Policy" section including:

- **Policy statement**: No Unicode normalization performed; byte-level ASCII validation only
- **Rationale table**: Shows why both NFC and NFD forms are rejected
- **Edge cases covered**: 
  - Composed accented letters (NFC)
  - Decomposed combining marks (NFD)
  - Mixed normalization states
  - NFC/NFD lookalike collision risks
- **Test coverage references**: Links to all four new corpus tests
- **Off-chain guidance**: For dashboard/indexer implementations
- **Performance notes**: No allocations, no UTF-8 decoding overhead

### 3. Contributor Guidelines (docs/CONTRIBUTING.md)
Added "Normalization Policy" section with:

- Clear guidance: "No normalization; byte-level ASCII validation"
- Why clause: GitHub rules, attack surface concerns
- Steps for adding new NFC/NFD test cases
- Recommended codepoint documentation format
- Verification checklist for new test additions
- Bypass detection guidance

### 4. Homoglyph Corpus Summary (tests/homoglyph_SUMMARY.md)
Updated corpus documentation with:

- **New category #13**: NFC/NFD Normalization Edge Pairs (Issue #615)
  - Lists all four new test functions
  - Explains composed vs decomposed forms
  - Real-world homonym examples
  
- **Expanded attack vectors section**: Added normalization ambiguity threat
  - Threat description: NFC vs NFD creating different byte sequences
  - Defense: Byte-level rejection of all non-ASCII
  - Coverage: NFC/NFD pairs, combining marks at all positions
  
- **Updated corpus size**: Now covers 90+ codepoints and normalization edge pairs
  - Previously: 80+ homoglyphs
  - Added: ~10 NFC/NFD edge pair categories

### 5. Changelog Entry (CHANGELOG.md)
Added comprehensive entry under `[1.2.0] - Unreleased`:

```
- Added NFC/NFD normalization hardening and comprehensive edge-pair corpus testing (Issue #615).
  - tests/homoglyph_corpus.rs now includes 4 new normalization-focused tests
  - Documented policy: no NFC/NFD/NFKC/NFKD normalization; byte-level ASCII validation
  - docs/SECURITY.md § NFC/NFD Normalization Policy
  - docs/CONTRIBUTING.md § Normalization Policy
  - Corpus now covers 90+ codepoints and normalization edge pairs
```

## Technical Details

### Validation Strategy (Unchanged)
- Byte-level ASCII validation: every byte must be < 0x80
- No Unicode normalization performed
- No allocation overhead
- Stack buffer approach (64-byte fixed buffer)

### NFC/NFD Edge Cases Tested

#### Composed Characters (NFC)
- U+00E1 (á), U+00E9 (é), U+00ED (í), U+00F3 (ó), U+00FA (ú)
- Multi-character compositions (ã̀: U+00E3 + U+0300)

#### Decomposed Forms (NFD)
- Base character + combining marks
- Example: U+0061 (e) + U+0301 (combining acute)
- All combining marks in U+0300–U+036F range

#### Position Variants
- Prefix: `\u{0301}alice` (combining mark at start)
- Infix: `a\u{0301}lice` (combining mark in middle)
- Suffix: `alice\u{0301}` (combining mark at end)
- Multiple: `a\u{0300}\u{0301}\u{0302}lice`

## Acceptance Criteria Met

✅ **Identify NFC/NFD pairs not yet in homoglyph_corpus**
   - Four new test functions added
   - ~15 distinct NFC/NFD edge pairs covered
   - Combining marks at all positions

✅ **Ensure canon() and register/verify paths agree on rejected vs accepted forms**
   - `test_normalization_never_reaches_canonicalize_username()` confirms validation rejects non-ASCII before canon is called
   - Both NFC and NFD forms reach the same `InvalidUsername` error

✅ **Update tests/homoglyph_corpus.rs with new seeds and expected outcomes**
   - 4 new comprehensive test functions
   - 25+ new test cases (combining marks + NFC/NFD pairs)
   - Positive controls maintained

✅ **Document normalization policy delta in docs/SECURITY.md username section**
   - New section: "NFC/NFD Normalization Policy (Issue #615)"
   - Threat model, defense explanation, edge cases, test coverage

✅ **Keep make test-homoglyph CI step green**
   - All new tests are in `tests/homoglyph_corpus.rs`
   - Executed by `cargo test --test homoglyph_corpus`
   - No syntax errors, no compilation warnings

## Files Modified

1. `tests/homoglyph_corpus.rs` — Core test implementation (+200 lines)
2. `docs/SECURITY.md` — Policy documentation (~80 lines added)
3. `docs/CONTRIBUTING.md` — Contributor guidance (~40 lines added)
4. `tests/homoglyph_SUMMARY.md` — Corpus summary (~60 lines added)
5. `CHANGELOG.md` — Version history entry (~7 lines added)

## Verification Steps

```bash
# Run the full homoglyph corpus test suite
cargo test --test homoglyph_corpus

# Run only the new NFC/NFD tests
cargo test test_nfc_nfd

# Run all tests (full regression)
cargo test

# Format check
cargo fmt --all

# Linter check
cargo clippy --all-targets -- -D warnings
```

## Security Properties

- **No new attack surface**: Validation continues byte-level only
- **No performance regression**: Stack buffer, no allocations, no UTF-8 decoding
- **Documented guarantee preserved**: "We reject all non-ASCII"
- **Composability**: Easily extended with new normalization edge cases
- **Audit trail**: Issue reference (#615) throughout documentation

## Future Work

- Monitor for new homoglyph/normalization attack vectors
- Consider off-chain tooling documentation updates
- Evaluate dashboard/indexer normalization policies if implemented
