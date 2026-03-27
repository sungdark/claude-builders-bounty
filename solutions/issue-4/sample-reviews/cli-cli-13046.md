## Summary
This PR addresses a bug in the `gh` CLI's pagination handling for large result sets. It introduces a cursor-based pagination approach for API responses exceeding 100 items, replacing the current page-number based approach. The change is targeted and minimal, affecting only the API client layer.

## Identified Risks
- The cursor-based pagination may not be compatible with all GitHub API endpoints that still use page-number pagination (e.g., some Search API routes).
- If the `Link` header is absent from the API response, the new code falls back to page-number pagination — verify this fallback works correctly for all edge cases.
- Changing pagination behavior could break scripts that depend on deterministic ordering of paginated results.

## Improvement Suggestions
- Add an integration test that verifies pagination works correctly across API endpoints with different pagination styles (cursor vs page-number).
- Consider adding a warning log when falling back to page-number pagination so users are aware of the degraded behavior.
- The new `getNextPageURL()` helper could be made generic and moved to a shared utilities module if other commands need similar logic.

## Confidence Score
High
