# CodeCornTech · GitHub Actions runner inventory

Audit: 2026-10-24. **75 repositories inspected; 14 repositories / 20 workflow YAML files.** Changes to runners require repository PRs; this document is not a runner installer.

## Shared runner policy

| Capability | Runner targeting | Status |
| --- | --- | --- |
| macOS x86_64 / Node / PHP | `[self-hosted, macOS, X64]` | Registered org-level as `iMac-di-Federico`; cross-repository access and current availability require verification |
| Linux amd64 / Docker / legacy PHP | `[self-hosted, Linux, X64, codecorn-linux]` | **Not registered**; dedicate Debian/Ubuntu VM before updating Linux-specific jobs |
| Windows x64 / Windows PowerShell 5.1 / pwsh | `[self-hosted, Windows, X64, codecorn-windows]` | **Not registered**; dedicate Windows VM before changing Windows jobs |

One organization-level registration can serve multiple repositories. **Do not download/register a separate runner in every repository.** Runner groups should grant access to only the repositories needing them. On the persistent Mac runner, skip workflow code from forked PRs; never use `pull_request_target` to execute untrusted checkouts. Isolate network-sensitive workloads and secrets from untrusted jobs.

Linux jobs that use Docker Compose or image builds belong on a **dedicated Linux VM** with Docker installed. Do not mount the Docker host socket from the personal workstation into arbitrary pull-request workloads. Prefer ephemeral worker VMs or an isolated, restricted environment for untrusted jobs.

## Repository inventory and migration status

| Repository | CI / release workflow count | Mac migration | Remaining OS requirement |
| --- | ---: | --- | --- |
| euro-plate-validator | 1 | PR #5 | None |
| mu-cc-admin-popover-row-actions | 2 | Deferred | PHP 7.4/8.2 matrix on Linux; PHP release |
| prettier-guide-community | 1 | PR #1 (also fixes YAML indentation) | None |
| corn-logger | 1 | PR #1 | None |
| barbagia-media-manager | 4 | PR #78 for PHP CI only | Auto-version/release/deployment workflow pending CI verification |
| ccwin-nas-backup-agent | 1 | PR #60 for lint only | Windows 5.1, Windows package, Linux+macOS pwsh matrix |
| codecorn-managed | 1 | PR #30 | Verify PHP 8.4 and required extensions before merge |
| mu-cc-wp-diagnostics | 2 | Deferred | PHP 7.4/8.2 matrix on Linux; PHP release |
| cc-divi5-search-results | 1 | PR #6 | None |
| codecorn-control-plane | 1 | Deferred | Linux PHP/extension app job and Docker Compose/image builds |
| smsend-cli | 1 | Deferred | Current 'test' invokes interactive real-SMS CLI; replace with non-networked tests before self-hosting |
| empty-session-reaper | 1 | PR #1 | Verify Node 16 legacy matrix |
| intel-vtx-rescue | 1 | PR #1 for Bash/Python only | Windows PowerShell and pwsh |
| ccwp-service-catalog | 2 | Already on org runner | None |

**Migration status:** PRs are intentionally **not merged** until the target runner picks up and passes all checks. A workflow in `queued` status is not proof of runner access.

## Access and provisioning checks

1. GitHub organization > Settings > Actions > Runners: verify `iMac-di-Federico` is online, idle and labeled `self-hosted`, `macOS`, `X64`.
2. Organization > Settings > Actions > Runner groups: verify repository access to the nine migration PR repositories. Select only intended repositories and allow public repos only with deliberate trust policy.
3. Provide a dedicated Ubuntu/Debian VM (amd64) for `codecorn-linux`. Register **once** at organization level using GitHub's one-time registration token, with Docker/Compose and the required PHP runtimes. Do not commit tokens or mount production credentials.
4. Provide a Windows VM for `codecorn-windows` with Windows PowerShell 5.1 and pwsh 7; keep package tests on Windows.
5. Rerun PR checks after access is corrected. Migrate remaining Linux/Windows jobs in separate tested PRs; do not reroute them to macOS blindly.

No release, tag, production deploy, runner installation or merge is performed by this audit.
