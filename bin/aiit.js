#!/usr/bin/env node
/**
 * AI Development Base CLI
 *
 * Commands:
 *   aiit init     - Initialize AI Development Base in current project
 *   aiit status   - Show active changes and current phase
 *   aiit doctor   - Diagnose installation health
 *   aiit update   - Update to latest version
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const AIIT_VERSION = '1.0.0';

// --- Helpers ---

function log(msg) {
  console.log(msg);
}

function logOk(msg) {
  console.log(`  ✓ ${msg}`);
}

function logWarn(msg) {
  console.log(`  ⚠ ${msg}`);
}

function logFail(msg) {
  console.log(`  ✗ ${msg}`);
}

function fileExists(filepath) {
  return fs.existsSync(filepath);
}

function dirExists(dirpath) {
  return fs.existsSync(dirpath) && fs.statSync(dirpath).isDirectory();
}

// --- aiit init ---

function cmdInit() {
  log('');
  log('==============================================');
  log('  AI Development Base — Initialize');
  log('==============================================');
  log('');

  const cwd = process.cwd();

  // Check if already initialized
  if (dirExists('.claude') && dirExists('.githooks')) {
    logWarn('AI Development Base already initialized in this project.');
    log('  Run `aiit doctor` to check health.');
    process.exit(0);
  }

  // Get package installation path
  const pkgPath = path.dirname(__dirname);

  log('  Installing AI Development Base...');
  log('');

  // Copy .claude directory
  if (dirExists(path.join(pkgPath, '.claude'))) {
    log('  Copying .claude/...');
    execSync(`cp -r "${pkgPath}/.claude" "${cwd}/"`, { stdio: 'inherit' });
    logOk('.claude/ installed');
  }

  // Copy .githooks directory
  if (dirExists(path.join(pkgPath, '.githooks'))) {
    log('  Copying .githooks/...');
    execSync(`cp -r "${pkgPath}/.githooks" "${cwd}/"`, { stdio: 'inherit' });
    logOk('.githooks/ installed');
  }

  // Copy specs directory
  if (dirExists(path.join(pkgPath, 'specs'))) {
    log('  Copying specs/...');
    execSync(`cp -r "${pkgPath}/specs" "${cwd}/"`, { stdio: 'inherit' });
    logOk('specs/ installed');
  }

  // Copy .gitleaks.toml if exists
  if (fileExists(path.join(pkgPath, '.gitleaks.toml'))) {
    execSync(`cp "${pkgPath}/.gitleaks.toml" "${cwd}/"`, { stdio: 'inherit' });
    logOk('.gitleaks.toml installed');
  }

  // Activate git hooks
  log('');
  log('  Activating git hooks...');
  try {
    execSync('git config core.hooksPath .githooks', { stdio: 'inherit' });
    logOk('Git hooks activated');
  } catch (e) {
    logWarn('Could not activate git hooks (not a git repository?)');
  }

  // Make scripts executable
  log('');
  log('  Setting permissions...');
  try {
    execSync('chmod +x .githooks/pre-commit .githooks/commit-msg .githooks/pre-push 2>/dev/null || true', { stdio: 'inherit' });
    execSync('chmod +x .claude/scripts/*.sh 2>/dev/null || true', { stdio: 'inherit' });
    logOk('Scripts made executable');
  } catch (e) {
    // Ignore permission errors on Windows
  }

  log('');
  log('==============================================');
  logOk('Initialization complete!');
  log('==============================================');
  log('');
  log('  Next steps:');
  log('    1. Run `/onboard` in Claude Code to configure role and level');
  log('    2. Start with `/discover "your idea"` to create a change');
  log('');
}

// --- aiit status ---

function cmdStatus() {
  log('');
  log('==============================================');
  log('  AI Development Base — Status');
  log('==============================================');
  log('');

  // Check if initialized
  if (!dirExists('.claude') || !dirExists('.githooks')) {
    logFail('AI Development Base not initialized in this project.');
    log('  Run `aiit init` to install.');
    process.exit(1);
  }

  // Run aiit-state.sh list
  const stateScript = '.claude/scripts/aiit-state.sh';
  if (fileExists(stateScript)) {
    try {
      const output = execSync(`bash ${stateScript} list`, { encoding: 'utf-8' });
      log(output);
    } catch (e) {
      log('  No active changes.');
    }
  } else {
    logWarn('State script not found. Run `aiit update` to install latest version.');
  }
}

// --- aiit doctor ---

function cmdDoctor() {
  log('');
  log('==============================================');
  log('  AI Development Base — Doctor');
  log('==============================================');
  log('');

  let passCount = 0;
  let failCount = 0;
  let warnCount = 0;

  function check(name, condition, failMsg, warnMsg) {
    if (condition) {
      logOk(name);
      passCount++;
    } else if (warnMsg) {
      logWarn(`${name} — ${warnMsg}`);
      warnCount++;
    } else {
      logFail(`${name} — ${failMsg}`);
      failCount++;
    }
  }

  // Check .claude directory
  check('.claude/ directory exists', dirExists('.claude'), 'Missing .claude/', 'Missing .claude/');

  // Check .githooks directory
  check('.githooks/ directory exists', dirExists('.githooks'), 'Missing .githooks/', 'Missing .githooks/');

  // Check specs directory
  check('specs/ directory exists', dirExists('specs'), 'Missing specs/', 'Missing specs/');

  // Check scripts
  check('Scripts directory exists', dirExists('.claude/scripts'), 'Missing .claude/scripts/', 'Missing .claude/scripts/');

  // Check state script
  check('aiit-state.sh exists', fileExists('.claude/scripts/aiit-state.sh'), 'Missing state script', 'Missing state script');

  // Check archive script
  check('aiit-archive.sh exists', fileExists('.claude/scripts/aiit-archive.sh'), 'Missing archive script', 'Missing archive script');

  // Check git hooks activation
  try {
    const hooksPath = execSync('git config core.hooksPath 2>/dev/null || echo ""', { encoding: 'utf-8' }).trim();
    check('Git hooks activated', hooksPath === '.githooks', `hooksPath is "${hooksPath}"`, `hooksPath is "${hooksPath}"`);
  } catch (e) {
    check('Git hooks activated', false, 'Not a git repository', 'Not a git repository');
  }

  // Check CLAUDE.md
  check('.claude/CLAUDE.md exists', fileExists('.claude/CLAUDE.md'), 'Missing CLAUDE.md', 'Missing CLAUDE.md');

  // Check settings.json
  check('.claude/settings.json exists', fileExists('.claude/settings.json'), 'Missing settings.json', 'Missing settings.json');

  // Summary
  log('');
  log('==============================================');
  if (failCount === 0) {
    logOk(`Health check passed: ${passCount} OK, ${warnCount} warnings`);
  } else {
    logFail(`Health check failed: ${passCount} OK, ${failCount} failures, ${warnCount} warnings`);
  }
  log('==============================================');
  log('');

  if (failCount > 0) {
    log('  Run `aiit init` to fix missing components.');
    process.exit(1);
  }
}

// --- aiit update ---

function cmdUpdate() {
  log('');
  log('==============================================');
  log('  AI Development Base — Update');
  log('==============================================');
  log('');

  log('  Updating via npm...');
  log('');

  try {
    execSync('npm install -g aiit-base@latest', { stdio: 'inherit' });
    log('');
    logOk('Update complete!');
    log('');
    log('  Run `aiit doctor` to verify installation.');
  } catch (e) {
    logFail('Update failed. Check your network connection and try again.');
    process.exit(1);
  }
}

// --- Main ---

function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  if (!command || command === 'help' || command === '--help' || command === '-h') {
    log('');
    log('AI Development Base CLI v' + AIIT_VERSION);
    log('');
    log('Usage: aiit <command>');
    log('');
    log('Commands:');
    log('  init     Initialize AI Development Base in current project');
    log('  status   Show active changes and current phase');
    log('  doctor   Diagnose installation health');
    log('  update   Update to latest version');
    log('');
    log('Examples:');
    log('  aiit init      # Install in current directory');
    log('  aiit status    # View active changes');
    log('  aiit doctor    # Check health');
    log('');
    process.exit(0);
  }

  if (command === '--version' || command === '-v') {
    log(AIIT_VERSION);
    process.exit(0);
  }

  switch (command) {
    case 'init':
      cmdInit();
      break;
    case 'status':
      cmdStatus();
      break;
    case 'doctor':
      cmdDoctor();
      break;
    case 'update':
      cmdUpdate();
      break;
    default:
      logFail(`Unknown command: ${command}`);
      log('  Run `aiit help` for usage.');
      process.exit(1);
  }
}

main();
