# <Project name>

Short description: what the project is and who uses it.

## Stack

- Language / framework:
- Database:
- Package manager:

## Commands

| What | Command |
|---|---|
| Lint | |
| Typecheck | |
| Unit tests | |
| Build | |

Heavy commands (build, full test suite) must run through: `<wrapper or "no restriction">`.

## Architecture rules

1. Where business logic lives, where it must never be.
2. How data access works (only through X).
3. How mutations are validated, authorised and logged.

## Forbidden

- Commands that must never run (destructive DB commands, deploys, pushes without asking).
- Patterns that must never appear in code.

## Conventions

- Naming, language of UI texts, date and time formats.
- Testing: framework, where tests live, test data rules.
