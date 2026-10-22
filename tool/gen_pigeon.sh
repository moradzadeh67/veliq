#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart run pigeon --input pigeons/messages.dart
cp macos/Runner/Messages.g.swift ios/Runner/Messages.g.swift
