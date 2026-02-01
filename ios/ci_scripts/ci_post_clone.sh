#!/bin/bash
set -e

cd "$CI_WORKSPACE"

flutter pub get
flutter build ios --config-only

cd ios
pod install --repo-update
