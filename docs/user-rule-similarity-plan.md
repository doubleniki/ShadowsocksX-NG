# User Rule Similarity Guard – Implementation Plan

## Context

- Quick-add flow (`addDomain`, `addFromClipboard`) sanitizes the input via `extractDomain` and appends `||domain` directly to the text view.
- `addRuleToTextView` only prevents literal duplicates, so semantic overlaps (e.g., existing `||example.com` vs. new `shop.example.com`) slip through.
- The text view mixes ABP syntax (`||`, `@@`, wildcards, comments), so comparisons must target normalized domains rather than raw lines.

## Similarity Detection Strategy

1. Introduce `RuleSimilarityChecker` that ingests the current text buffer and exposes `findSimilarity(for:) -> RuleSimilarity?`.
2. Normalization pipeline per stored line: trim whitespace/comments, strip ABP prefixes (`@@`, `||`, `|`), drop wildcard markers (`*.`), trailing terminators (`^`, `/…`), lowercase, and remove leading `www.`.
3. Categorize entries (`.exact`, `.wildcard`, `.exception`, `.other`) while retaining the original rule string for messaging.
4. Compare the normalized candidate domain (same sanitation rules) against each stored entry:
   - **Exact**: strings match.
   - **Broader existing rule**: stored rule matches the candidate’s suffix on a dot boundary or contains wildcards covering it.
   - **Narrower existing rule**: candidate is broader than stored (e.g., adding `example.com` when `sub.example.com` exists).
5. Return the first/highest-priority hit with the detected relationship for downstream UX.

## Controller Integration

- In both `addDomain` and `addFromClipboard`, run the checker immediately after `extractDomain` succeeds and before constructing the final rule string.
- If a similarity is found, present an alert describing the overlap and offer:
  - Primary button “Добавить всё равно” → continue to `addRuleToTextView`.
  - Secondary “Отмена” → exit early.
- Keep the existing “Rule already exists” guard inside `addRuleToTextView` as a last line of defense.

## Testing & QA

- Add unit tests in `ShadowsocksX-NGTests` covering duplicate detection, wildcard vs. subdomain handling, exception rules (`@@||`), mixed casing, and noisy inputs containing schemes or paths.
- Manual regression checklist: populate the text view with `||example.com`, attempt to add `https://shop.example.com`, verify the warning modal appears, confirm both alert buttons behave correctly, and ensure successful additions still clear the quick-add text field / prefill from clipboard.
- Document the new behavior in release notes or contributor docs so maintainers expect the warning dialog during QA scripts.

## Task Breakdown

1. Implement `RuleSimilarityChecker` with normalization/comparison helpers and add unit tests that cover exact, wildcard, exception, and broader/narrower scenarios.
2. Inject the checker into `UserRulesController.addDomain` and `addFromClipboard`, introducing a shared confirmation dialog helper for similar-rule conflicts.
3. Ensure `addRuleToTextView` handles literal duplicates consistently with the new flow (adjust messaging if needed).
4. Extend `ShadowsocksX-NGTests` with integration-style specs that mock text view content to hit the new alert paths.
5. Run the manual QA checklist (quick add + clipboard) and document the warning flow in release notes or contributor docs.
