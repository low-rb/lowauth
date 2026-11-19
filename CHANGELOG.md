# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- `PasswordLinks` for emailed links that set a password, to reset one or choose one when invited. They keep only each token's SHA-256, work once and expire
- `LowAuth.find_user(login)`, and `config.password_length` with `Passwords.long_enough?`

## 0.1.0

### Added

- Argon2 passwords, with old hashes from another site rehashed when their users log in
- Sessions in a `sessions` table, with only a SHA-256 of each cookie's token
- `requires :role` to guard a node's actions, and same-origin checks on forms
- `login`, `logout` and `current_user` for nodes
- `LoginLimit` to stop password guessing
