# Contributing to Flutter Skills

## Note on contributions

We are not yet open for direct contributions as we are still actively working on publishing a larger set of skills. Your experience using these skills is important to us. If you find a bug or have an idea for a skill you'd like to see added, please [file an issue][issue] or request following the insturctions below. 

We appreciate your feedback!

## Providing Feedback on an existing skill
[File an issue][issue] and let us know:
1. What language model are you using? (Gemini 3.1 Flash, Claude Sonnet 4.6, etc)
2. What agent harness are you using? (Antigravity, Gemini CLI, Claude Code, Cursor)
3. Logs that show what prompt you used and steps the agent took to complete the task (Such as what skills it chose to use, MCP tools it used, etc).

## Requesting a skill
First check if its on the [list of skills we plan to work on next][next skills] and feel free to comment if you'd like us to prioritize differently.
If not [file an issue][issue] and we will prioritize it.

## Issue triage

We regularly triage issues by looking at newly filed issues and determining what we should do about each of them. Triage issues as follows:

- Open the [list of untriaged issues][untriaged_list].
- For each issue in the list, do one of:
  - If we don't plan to fix the issue, close it with an explanation.
  - If we plan to fix the issue, add the `triaged` label and assign a priority: [P0][P0], [P1][P1], [P2][P2], or [P3][P3]. If you don't know which priority to assign, apply `P2`. If an issue is `P0` or `P1`, add it to a milestone.

At the end of a triage session, the untriaged issue list should be as close to empty as possible.

[issue]: https://github.com/flutter/skills/issues
[next skills]: https://github.com/flutter/skills/issues/88
[untriaged_list]: https://github.com/flutter/skills/issues?q=is%3Aissue+state%3Aopen+-label%3Atriaged
[P0]: https://github.com/flutter/skills/labels?q=P0
[P1]: https://github.com/flutter/skills/labels?q=P1
[P2]: https://github.com/flutter/skills/labels?q=P2
[P3]: https://github.com/flutter/skills/labels?q=P3
