# Test Strategy: CLI Tool

## Detection Signals

The onboarding system (`/onboard`) auto-detects a CLI project when:

- **Rust:**
  - `Cargo.toml` contains `clap`, `structopt`, `argh`, `bpaf`, or `lexopt`.
  - `[[bin]]` section in `Cargo.toml` with a CLI-facing binary name.

- **Python:**
  - `pyproject.toml` contains `click`, `typer`, `argparse`, `fire`, or `rich-click`.
  - `[project.scripts]` section in `pyproject.toml` defines CLI entry points.
  - A `setup.py` or `setup.cfg` with `console_scripts` entry points.

- **Node.js:**
  - `package.json` contains `commander`, `yargs`, `oclif`, `ink`, `pastel`, or `clipanion`.
  - `"bin"` field in `package.json` maps a command name to a JavaScript file.
  - `@oclif/core` or `@oclif/command` in dependencies.

- **Go:**
  - `go.mod` with `cobra`, `urfave/cli`, `alecthomas/kingpin`, or `charmbracelet/bubbletea`.
  - `main.go` in the project root (not in `cmd/` subdirectory pattern typical
    of server projects).

- **General signals:**
  - Project has `--help` output defined.
  - Man page source files (`man/`, `docs/man/`, or `.1`/`.8` files).
  - Shell completion scripts (bash, zsh, fish) bundled.
  - No HTTP server startup code in the entry point.
  - CI pipeline builds a single binary (or package) for distribution.

---

## Smoke Test Checklist

Smoke tests verify the CLI is functional at a basic level.

- [ ] CLI binary can be invoked (installed or run from source).
  - Rust: `cargo run -- --help` succeeds.
  - Python: `python -m <module> --help` or `poetry run <cli> --help` succeeds.
  - Node.js: `node bin/<cli>.js --help` or `npx <cli> --help` succeeds.
  - Go: `go run . --help` or `./<binary> --help` succeeds.
- [ ] `--help` displays usage information without errors:
  - [ ] Shows the command name and description.
  - [ ] Lists all subcommands.
  - [ ] Shows `--version` flag.
- [ ] `--version` outputs the current version string without errors.
- [ ] Each core subcommand parses correctly:
  - [ ] Running with `--help` shows subcommand-specific help.
  - [ ] Running with valid required arguments does not error on parse.
  - [ ] Running with missing required arguments shows a helpful error message.
- [ ] Exit codes are correct:
  - [ ] Success (no error) returns exit code 0.
  - [ ] User error (bad input) returns exit code 1 (or defined non-zero).
  - [ ] Unexpected error (bug) returns a non-zero exit code.
- [ ] Error messages go to stderr, normal output goes to stdout.
- [ ] Shell completions can be generated (if supported):
  - [ ] `--generate-completion bash` (or equivalent) produces valid output.

---

## Unit Tests

**Approach:** Test argument parsing logic, command handler functions, business
logic, and utility functions in isolation. The CLI framework's own parsing
can usually be trusted; focus on what happens AFTER parsing.

**Per-language tooling:**

| Language | Test Runner | Best Practices |
|---|---|---|
| Rust | `cargo test` | Test clap `Command` configuration for correct args/flags. Test handler functions directly with parsed args struct. |
| Python | `pytest` | Use `click.testing.CliRunner` / `typer.testing.CliRunner` for command invocation. Test logic functions with direct Python calls. |
| Node.js | Vitest / Jest | Mock `process.argv`, `process.exit`, `console.log`, `console.error`. Test command action handlers directly. |
| Go | `go test` | Test `cobra.Command.RunE` handlers directly. Use `cmd.SetArgs()` to simulate argument passing. |

**Coverage Target:** 80% line coverage on command handler functions, argument
parsing logic, business logic, and utility functions. Exclude: framework
boilerplate (new Command, new App), shell completion generators, generated
code.

**Key patterns to test:**
- Argument parsing edge cases:
  - Required args missing, optional args with defaults, flag combinations.
  - `--` separator handling (end of options).
  - Negative numbers vs. flags (e.g., `-1` as a value vs. `-1` as flags).
- File I/O handling (read from stdin, write to stdout, file paths that
  don't exist, permission errors, empty files).
- Input validation (valid ranges, format checking, mutually exclusive options).
- Output formatting (JSON, YAML, table, plain text -- verify exact format).
- Error messages (clear, actionable, include context).
- Environment variable overrides (if supported).

---

## Integration Tests

**Approach:** Run the CLI as a real subprocess (or equivalent), pass fixture
inputs, and check exit codes, stdout, and stderr. Test the full pipeline:
parse arguments, execute logic, produce output.

**Per-language tooling:**

| Language | Subprocess Approach |
|---|---|
| Rust | `assert_cmd` crate -- builds the binary and runs it as a subprocess. `predicates` crate for output assertions. |
| Python | `subprocess.run([sys.executable, '-m', 'module', 'arg'])` or `CliRunner.invoke()` with temp files. |
| Node.js | `execa` / `child_process.spawnSync` to run the CLI as a subprocess. |
| Go | `os/exec` to run the compiled binary. Use `go build -o testbinary` before running. |

**Coverage Target:** One integration test per core subcommand. At minimum,
verify the happy path for the 3-5 most-used subcommands.

**Key flows to test:**
- Full pipeline with fixture inputs:
  - Provide input file → run CLI → verify output file content matches expected.
  - Pipe stdin → run CLI → verify stdout content matches expected.
- Environment variable and config file interaction (which takes precedence).
- Exit codes for every error condition tested at the unit level.
- Output format variants (default, --json, --quiet, --verbose).
- Concurrent safety (if the CLI writes to shared resources).

---

## E2E Tests

CLI tools typically do not have E2E tests in the traditional sense. Instead,
consider these as "distribution smoke tests":

- **Installation test:** Install the CLI from package manager (npm, pip, cargo
  install, brew, apt) on a clean environment and verify `--help` works.
- **PATH test:** The CLI is available on PATH after installation.
- **Upgrade test:** Install old version, run a command, upgrade to new version,
  run same command -- verify no data loss or config breakage.

For L3 projects, these can be automated in CI with Docker containers as clean
environments.

---

## Contract Validation

CLI tools do not have API contracts in the traditional sense. However:

- **Interface contract:** If the CLI is scripted (used in shell scripts,
  CI pipelines), the output format (stdout structure, exit codes) is a
  contract. Changes to output format are breaking changes.
- **Config file schema:** If the CLI uses a config file (YAML, TOML, JSON),
  the config schema is a contract. Schema changes should be backward-compatible
  or clearly versioned.
- **Verify with snapshot tests:** Snapshot the help text and output of key
  commands. A diff in the snapshot means the interface contract has changed --
  review with the user.

---

## Gate Integration

This test strategy integrates with `run_phase_gates 4` (Phase 4 -- Verify)
through three gates:

### Contract Gate
CLI tools do not use `oasdiff`. Instead, the Contract Gate for CLI projects
checks:
- Snapshot tests for `--help` output and key command outputs have no
  unexpected diffs.
- Config file schema changes are documented and backward-compatible.
- If the CLI has a JSON output mode, the JSON schema has not changed in a
  breaking way.

If the project also contains a REST API, the Contract Gate runs `oasdiff`
for the API portion in addition to the CLI checks.

### Security Gate
- **semgrep**: SAST scan for command injection, path traversal, unsafe
  file operations, and hardcoded secrets.
- **npm audit** (Node.js) / **pip-audit** (Python) / **cargo audit** (Rust):
  Dependency vulnerability scan.
- **Go**: `govulncheck ./...`
- Special attention: CLI tools often have elevated permissions (file system
  access, network access). Verify that user-supplied input is never passed
  directly to shell execution or file operations without sanitization.

### Smoke Test Gate
- The smoke test checklist at the top of this document provides the pass/fail
  criteria. All items must be checked and passing.
- Automated smoke test: build the CLI binary, run `--help` and `--version`,
  run each core subcommand with valid arguments, verify exit code 0 and
  non-empty output.
- If any smoke test item fails, the Smoke Test Gate fails and Phase 4 cannot
  advance.

---

## Quick Reference (for CLAUDE.md Extraction)

CLI tool: detected by clap/click/typer/commander/cobra in deps + bin entry. Smoke test: --help works, --version prints version, subcommands parse, exit codes correct (0=ok, non-0=error). Unit: argument parsing, handler logic, business functions, 80% coverage. Integration: run as subprocess with fixtures, check exit codes + stdout/stderr. Contract: snapshot --help text + key outputs, config schema backward-compat. Security: semgrep (command injection focus) + dependency audit. Gates: Contract (snapshot diffs), Security (SAST+SCA), Smoke Test (help+version+subcommands). Gated at Phase 4 run_phase_gates 4.
