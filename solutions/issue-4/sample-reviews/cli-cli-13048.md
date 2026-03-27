## Summary
This PR replaces the `yaml.v2` dependency with `yaml.v3` throughout the codebase. The upgrade is motivated by `yaml.v3`'s improved security posture and better handling of anchor/alias resolution. The diff shows mechanical find-and-replace changes across ~40 files with minimal logic changes, as the YAML library API is largely compatible between versions.

## Identified Risks
- **Low risk**: The YAML API compatibility between v2 and v3 is generally good, but some edge cases around anchor/alias behavior have changed. Review the test suite to ensure full coverage.
- The PR touches many files (40+). A regression in any one of them would be hard to bisect.
- Some deprecated `yaml.v2`-specific workarounds in the codebase may now be unnecessary — verify they don't cause silent failures with v3.

## Improvement Suggestions
- Add a `//go:generate` directive or build tag to ensure the dependency upgrade is documented and reproducible.
- Consider adding a integration test that verifies YAML round-tripping (serialize → deserialize) works correctly for all config file formats used by `gh`.
- The PR could be split into two commits: one mechanical dependency upgrade, and one follow-up cleanup of now-unnecessary v2 workarounds.

## Confidence Score
High
