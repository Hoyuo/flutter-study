# Flutter CI/CD Guide

> 이 문서는 Flutter 앱의 CI/CD 파이프라인 설정 방법을 설명합니다.

## 1. 개요

### 1.1 CI/CD란?

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI (Continuous Integration)                   │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │  Push   │ →  │ Analyze │ →  │  Test   │ →  │  Build  │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CD (Continuous Delivery/Deployment)            │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐      │
│  │  Sign   │ →  │ Upload  │ →  │ Review  │ →  │ Release │      │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 CI/CD 도구 비교

| 도구 | 장점 | 단점 | 비용 |
|------|------|------|------|
| **GitHub Actions** | GitHub 통합, 무료 tier | macOS 비용 높음 | 무료 2,000분/월 |
| **Codemagic** | Flutter 특화, M1 Mac | 무료 tier 제한 | 무료 500분/월 |
| **Bitrise** | 다양한 워크플로우 | 설정 복잡 | 유료 |
| **Fastlane** | 자동화 강력 | 학습 곡선 | 무료 (오픈소스) |

### 1.3 권장 조합

```
┌─────────────────────────────────────────────────────────────────┐
│                     권장 CI/CD 스택                               │
├─────────────────────────────────────────────────────────────────┤
│  CI/CD 플랫폼: GitHub Actions (또는 Codemagic)                   │
│  빌드 자동화: Fastlane                                           │
│  코드 서명: Match (iOS) + Gradle Signing (Android)               │
│  배포: Firebase App Distribution (테스트) + Store (프로덕션)      │
│  모니터링: Slack/Discord 알림                                     │
└─────────────────────────────────────────────────────────────────┘
```

## 2. GitHub Actions

### 2.1 기본 워크플로우 구조

```yaml
# .github/workflows/flutter_ci.yml
name: Flutter CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  release:
    types: [published]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  FLUTTER_VERSION: '3.27.0'
  JAVA_VERSION: '17'

jobs:
  analyze:
    name: Analyze & Test
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true
          cache-key: flutter-${{ env.FLUTTER_VERSION }}-${{ hashFiles('**/pubspec.lock') }}

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze code
        run: flutter analyze --fatal-infos

      - name: Run tests with coverage
        run: flutter test --coverage --test-randomize-ordering-seed=random

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: coverage/lcov.info
          flags: unittests
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: false
```

### 2.2 Android 빌드 Job

```yaml
# .github/workflows/flutter_ci.yml (계속)
  build-android:
    name: Build Android (${{ matrix.flavor }})
    needs: analyze
    runs-on: ubuntu-latest
    timeout-minutes: 30

    strategy:
      fail-fast: false
      matrix:
        flavor: [dev, staging, prod]
        include:
          - flavor: dev
            build-type: apk
          - flavor: staging
            build-type: apk
          - flavor: prod
            build-type: appbundle

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}
          cache: 'gradle'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Decode keystore
        if: matrix.flavor == 'prod'
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Create key.properties
        if: matrix.flavor == 'prod'
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build APK
        if: matrix.build-type == 'apk'
        run: |
          flutter build apk \
            --flavor ${{ matrix.flavor }} \
            --dart-define=ENV=${{ matrix.flavor }} \
            --dart-define=BUILD_NUMBER=${{ github.run_number }} \
            --dart-define=COMMIT_SHA=${{ github.sha }}

      - name: Build App Bundle
        if: matrix.build-type == 'appbundle'
        run: |
          flutter build appbundle \
            --flavor ${{ matrix.flavor }} \
            --dart-define=ENV=${{ matrix.flavor }} \
            --dart-define=BUILD_NUMBER=${{ github.run_number }} \
            --dart-define=COMMIT_SHA=${{ github.sha }}

      - name: Upload APK
        if: matrix.build-type == 'apk'
        uses: actions/upload-artifact@v4
        with:
          name: apk-${{ matrix.flavor }}
          path: build/app/outputs/flutter-apk/app-${{ matrix.flavor }}-release.apk
          retention-days: 7

      - name: Upload App Bundle
        if: matrix.build-type == 'appbundle'
        uses: actions/upload-artifact@v4
        with:
          name: aab-${{ matrix.flavor }}
          path: build/app/outputs/bundle/${{ matrix.flavor }}Release/app-${{ matrix.flavor }}-release.aab
          retention-days: 14
```

### 2.3 iOS 빌드 Job

```yaml
# .github/workflows/flutter_ci.yml (계속)
  build-ios:
    name: Build iOS (${{ matrix.flavor }})
    needs: analyze
    runs-on: macos-14  # M1 Mac
    timeout-minutes: 45

    strategy:
      fail-fast: false
      matrix:
        flavor: [dev, staging, prod]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: ios

      - name: Install CocoaPods
        run: |
          cd ios
          bundle exec pod install --repo-update

      - name: Import Code Signing Certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}

      - name: Download Provisioning Profiles
        uses: apple-actions/download-provisioning-profiles@v2
        with:
          bundle-id: com.example.app.${{ matrix.flavor }}
          profile-type: IOS_APP_STORE
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}

      - name: Build IPA
        run: |
          flutter build ipa \
            --flavor ${{ matrix.flavor }} \
            --dart-define=ENV=${{ matrix.flavor }} \
            --dart-define=BUILD_NUMBER=${{ github.run_number }} \
            --export-options-plist=ios/ExportOptions-${{ matrix.flavor }}.plist

      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: ipa-${{ matrix.flavor }}
          path: build/ios/ipa/*.ipa
          retention-days: 14
```

### 2.4 배포 Job

```yaml
# .github/workflows/flutter_ci.yml (계속)
  deploy-firebase:
    name: Deploy to Firebase (${{ matrix.flavor }})
    needs: [build-android, build-ios]
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/develop'

    strategy:
      matrix:
        flavor: [dev, staging]

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download APK
        uses: actions/download-artifact@v4
        with:
          name: apk-${{ matrix.flavor }}
          path: artifacts/android

      - name: Download IPA
        uses: actions/download-artifact@v4
        with:
          name: ipa-${{ matrix.flavor }}
          path: artifacts/ios

      - name: Deploy Android to Firebase
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_ANDROID_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: testers
          file: artifacts/android/app-${{ matrix.flavor }}-release.apk
          releaseNotes: |
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
            Build: ${{ github.run_number }}

      - name: Deploy iOS to Firebase
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_IOS_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: testers
          file: artifacts/ios/*.ipa
          releaseNotes: |
            Branch: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
            Build: ${{ github.run_number }}

  deploy-stores:
    name: Deploy to Stores
    needs: [build-android, build-ios]
    runs-on: macos-14
    if: github.event_name == 'release'
    environment: production

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Download AAB
        uses: actions/download-artifact@v4
        with:
          name: aab-prod
          path: artifacts/android

      - name: Download IPA
        uses: actions/download-artifact@v4
        with:
          name: ipa-prod
          path: artifacts/ios

      - name: Deploy to Play Store
        run: |
          bundle exec fastlane android deploy_internal
        env:
          SUPPLY_JSON_KEY_DATA: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          AAB_PATH: artifacts/android/app-prod-release.aab

      - name: Deploy to TestFlight
        run: |
          bundle exec fastlane ios deploy_testflight
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APPSTORE_API_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APPSTORE_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
          IPA_PATH: artifacts/ios/*.ipa
```

### 2.5 알림 Job

```yaml
# .github/workflows/flutter_ci.yml (계속)
  notify:
    name: Notify
    needs: [deploy-firebase, deploy-stores]
    runs-on: ubuntu-latest
    if: always()

    steps:
      - name: Notify Slack on Success
        if: needs.deploy-firebase.result == 'success' || needs.deploy-stores.result == 'success'
        uses: slackapi/slack-github-action@v1.27.0
        with:
          payload: |
            {
              "blocks": [
                {
                  "type": "header",
                  "text": {
                    "type": "plain_text",
                    "text": "✅ Build Deployed Successfully"
                  }
                },
                {
                  "type": "section",
                  "fields": [
                    {"type": "mrkdwn", "text": "*Repository:*\n${{ github.repository }}"},
                    {"type": "mrkdwn", "text": "*Branch:*\n${{ github.ref_name }}"},
                    {"type": "mrkdwn", "text": "*Build:*\n#${{ github.run_number }}"},
                    {"type": "mrkdwn", "text": "*Triggered by:*\n${{ github.actor }}"}
                  ]
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {"type": "plain_text", "text": "View Workflow"},
                      "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                    }
                  ]
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Notify Slack on Failure
        if: failure()
        uses: slackapi/slack-github-action@v1.27.0
        with:
          payload: |
            {
              "blocks": [
                {
                  "type": "header",
                  "text": {
                    "type": "plain_text",
                    "text": "❌ Build Failed"
                  }
                },
                {
                  "type": "section",
                  "fields": [
                    {"type": "mrkdwn", "text": "*Repository:*\n${{ github.repository }}"},
                    {"type": "mrkdwn", "text": "*Branch:*\n${{ github.ref_name }}"},
                    {"type": "mrkdwn", "text": "*Commit:*\n${{ github.sha }}"}
                  ]
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {"type": "plain_text", "text": "View Logs"},
                      "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                    }
                  ]
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK
```

### 2.6 PR 검증 워크플로우

```yaml
# .github/workflows/pr_check.yml
name: PR Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  check:
    name: PR Validation
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage

      - name: Check coverage threshold
        uses: VeryGoodOpenSource/very_good_coverage@v3
        with:
          path: coverage/lcov.info
          min_coverage: 80
          exclude: '**/*.g.dart **/*.freezed.dart'

      - name: Comment PR with coverage
        uses: romeovs/lcov-reporter-action@v0.4.0
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          lcov-file: coverage/lcov.info
          filter-changed-files: true
```

## 3. Codemagic

### 3.1 codemagic.yaml 전체 설정

```yaml
# codemagic.yaml
definitions:
  environment: &environment
    flutter: stable
    xcode: latest
    cocoapods: default
    java: 17

  scripts:
    - &install_deps
      name: Install dependencies
      script: |
        flutter pub get

    - &run_tests
      name: Run tests
      script: |
        flutter analyze --fatal-infos
        flutter test --coverage

  artifacts: &artifacts
    - build/**/outputs/apk/**/*.apk
    - build/**/outputs/bundle/**/*.aab
    - build/ios/ipa/*.ipa
    - flutter_drive.log

  publishing: &publishing
    email:
      recipients:
        - team@example.com
      notify:
        success: true
        failure: true
    slack:
      channel: '#builds'
      notify_on_build_start: false
      notify:
        success: true
        failure: true

workflows:
  # Development 빌드
  dev-workflow:
    name: Development Build
    instance_type: mac_mini_m1
    max_build_duration: 60
    environment:
      <<: *environment
      groups:
        - development
      vars:
        FLAVOR: dev

    triggering:
      events:
        - push
      branch_patterns:
        - pattern: develop
          include: true
        - pattern: 'feature/*'
          include: true

    scripts:
      - *install_deps
      - *run_tests
      - name: Build Android APK
        script: |
          flutter build apk \
            --flavor $FLAVOR \
            --dart-define=ENV=$FLAVOR \
            --dart-define=BUILD_NUMBER=$PROJECT_BUILD_NUMBER
      - name: Build iOS
        script: |
          flutter build ios \
            --flavor $FLAVOR \
            --dart-define=ENV=$FLAVOR \
            --no-codesign

    artifacts: *artifacts

    publishing:
      <<: *publishing
      firebase:
        firebase_service_account: $FIREBASE_SERVICE_ACCOUNT
        android:
          app_id: $FIREBASE_ANDROID_APP_ID
          groups:
            - developers

  # Staging 빌드
  staging-workflow:
    name: Staging Build
    instance_type: mac_mini_m1
    max_build_duration: 90
    environment:
      <<: *environment
      groups:
        - staging
      vars:
        FLAVOR: staging
      ios_signing:
        distribution_type: ad_hoc
        bundle_identifier: com.example.app.staging

    triggering:
      events:
        - push
      branch_patterns:
        - pattern: 'release/*'
          include: true

    scripts:
      - *install_deps
      - *run_tests
      - name: Build Android APK
        script: |
          flutter build apk \
            --flavor $FLAVOR \
            --dart-define=ENV=$FLAVOR \
            --dart-define=BUILD_NUMBER=$PROJECT_BUILD_NUMBER
      - name: Build iOS IPA
        script: |
          flutter build ipa \
            --flavor $FLAVOR \
            --dart-define=ENV=$FLAVOR \
            --export-options-plist=ios/ExportOptions-staging.plist

    artifacts: *artifacts

    publishing:
      <<: *publishing
      firebase:
        firebase_service_account: $FIREBASE_SERVICE_ACCOUNT
        android:
          app_id: $FIREBASE_ANDROID_APP_ID_STAGING
          groups:
            - qa-team
        ios:
          app_id: $FIREBASE_IOS_APP_ID_STAGING
          groups:
            - qa-team

  # Production 빌드
  production-workflow:
    name: Production Build
    instance_type: mac_mini_m1
    max_build_duration: 120
    environment:
      <<: *environment
      groups:
        - production
      vars:
        FLAVOR: prod
      android_signing:
        - release_keystore
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.example.app

    triggering:
      events:
        - tag
      tag_patterns:
        - pattern: 'v*'
          include: true

    scripts:
      - *install_deps
      - *run_tests
      - name: Build Android AAB
        script: |
          flutter build appbundle \
            --flavor $FLAVOR \
            --dart-define=ENV=$FLAVOR \
            --dart-define=BUILD_NUMBER=$PROJECT_BUILD_NUMBER
      - name: Build iOS IPA
        script: |
          flutter build ipa \
            --flavor $FLAVOR \
            --dart-define=ENV=$FLAVOR \
            --export-options-plist=ios/ExportOptions-prod.plist

    artifacts: *artifacts

    publishing:
      <<: *publishing
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: internal
        submit_as_draft: true
      app_store_connect:
        api_key: $APP_STORE_CONNECT_API_KEY
        key_id: $APP_STORE_CONNECT_KEY_ID
        issuer_id: $APP_STORE_CONNECT_ISSUER_ID
        submit_to_testflight: true
        beta_groups:
          - Internal Testers
```

### 3.2 Codemagic 환경 변수 그룹

```yaml
# Codemagic UI에서 설정할 환경 변수 그룹

# development 그룹
FIREBASE_SERVICE_ACCOUNT: <JSON 파일 내용>
FIREBASE_ANDROID_APP_ID: 1:xxxxx:android:xxxxx
FIREBASE_IOS_APP_ID: 1:xxxxx:ios:xxxxx

# staging 그룹
FIREBASE_SERVICE_ACCOUNT: <JSON 파일 내용>
FIREBASE_ANDROID_APP_ID_STAGING: 1:xxxxx:android:xxxxx
FIREBASE_IOS_APP_ID_STAGING: 1:xxxxx:ios:xxxxx

# production 그룹
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS: <JSON 파일 내용>
APP_STORE_CONNECT_API_KEY: <API Key 내용>
APP_STORE_CONNECT_KEY_ID: XXXXXXXXXX
APP_STORE_CONNECT_ISSUER_ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 4. Fastlane

### 4.1 프로젝트 구조

```
project/
├── android/
│   └── fastlane/
│       ├── Fastfile
│       ├── Appfile
│       └── Pluginfile
├── ios/
│   └── fastlane/
│       ├── Fastfile
│       ├── Appfile
│       ├── Matchfile
│       └── Pluginfile
├── Gemfile
└── Gemfile.lock
```

### 4.2 Gemfile

```ruby
# Gemfile
source "https://rubygems.org"

gem "fastlane", "~> 2.225"
gem "cocoapods", "~> 1.15"

plugins_path = File.join(File.dirname(__FILE__), 'ios', 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)

plugins_path = File.join(File.dirname(__FILE__), 'android', 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
```

### 4.3 iOS Fastfile

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  before_all do
    setup_ci if ENV['CI']
  end

  # ========================================
  # 인증서 관리 (Match)
  # ========================================

  desc "Sync all certificates and profiles"
  lane :sync_certificates do
    match(type: "development", readonly: true)
    match(type: "adhoc", readonly: true)
    match(type: "appstore", readonly: true)
  end

  desc "Register new device"
  lane :register_device do |options|
    device_name = options[:name] || prompt(text: "Device name: ")
    device_udid = options[:udid] || prompt(text: "Device UDID: ")

    register_devices(
      devices: {
        device_name => device_udid
      }
    )

    match(type: "development", force_for_new_devices: true)
    match(type: "adhoc", force_for_new_devices: true)
  end

  # ========================================
  # 빌드
  # ========================================

  desc "Build development IPA"
  lane :build_dev do
    build_ios_app(
      scheme: "Runner-dev",
      configuration: "Release-dev",
      export_method: "development",
      output_directory: "./build/ios",
      output_name: "app-dev.ipa"
    )
  end

  desc "Build staging IPA"
  lane :build_staging do
    match(type: "adhoc", readonly: true)

    build_ios_app(
      scheme: "Runner-staging",
      configuration: "Release-staging",
      export_method: "ad-hoc",
      output_directory: "./build/ios",
      output_name: "app-staging.ipa"
    )
  end

  desc "Build production IPA"
  lane :build_prod do
    match(type: "appstore", readonly: true)

    build_ios_app(
      scheme: "Runner-prod",
      configuration: "Release-prod",
      export_method: "app-store",
      output_directory: "./build/ios",
      output_name: "app-prod.ipa"
    )
  end

  # ========================================
  # 배포
  # ========================================

  desc "Deploy to Firebase App Distribution"
  lane :deploy_firebase do |options|
    firebase_app_distribution(
      app: ENV["FIREBASE_IOS_APP_ID"],
      ipa_path: options[:ipa_path] || "./build/ios/ipa/*.ipa",
      groups: options[:groups] || "testers",
      release_notes: options[:notes] || changelog_from_git_commits(commits_count: 10)
    )
  end

  desc "Deploy to TestFlight"
  lane :deploy_testflight do |options|
    api_key = app_store_connect_api_key(
      key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
      issuer_id: ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"],
      key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"],
      in_house: false
    )

    upload_to_testflight(
      api_key: api_key,
      ipa: options[:ipa_path] || "./build/ios/ipa/*.ipa",
      skip_waiting_for_build_processing: true,
      distribute_external: false,
      notify_external_testers: false,
      changelog: options[:notes] || changelog_from_git_commits(commits_count: 10)
    )
  end

  desc "Deploy to App Store"
  lane :deploy_appstore do |options|
    api_key = app_store_connect_api_key(
      key_id: ENV["APP_STORE_CONNECT_API_KEY_ID"],
      issuer_id: ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"],
      key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"],
      in_house: false
    )

    upload_to_app_store(
      api_key: api_key,
      ipa: options[:ipa_path] || "./build/ios/ipa/*.ipa",
      submit_for_review: false,
      automatic_release: false,
      skip_screenshots: true,
      skip_metadata: false,
      precheck_include_in_app_purchases: false
    )
  end

  # ========================================
  # 버전 관리
  # ========================================

  desc "Increment build number"
  lane :increment_build do
    build_number = latest_testflight_build_number + 1
    increment_build_number(build_number: build_number)
    build_number
  end

  desc "Increment version number"
  lane :increment_version do |options|
    increment_version_number(
      bump_type: options[:bump_type] || "patch"  # major, minor, patch
    )
  end

  # ========================================
  # 유틸리티
  # ========================================

  desc "Clean build artifacts"
  lane :clean do
    clear_derived_data
    sh("cd .. && rm -rf build/ios")
  end

  error do |lane, exception|
    # 에러 발생 시 Slack 알림
    slack(
      message: "iOS Build Failed",
      success: false,
      payload: {
        "Lane" => lane,
        "Error" => exception.message
      },
      default_payloads: [:git_branch, :git_author]
    ) if ENV["SLACK_URL"]
  end
end
```

### 4.4 iOS Appfile

```ruby
# ios/fastlane/Appfile
app_identifier(ENV["APP_IDENTIFIER"] || "com.example.app")
apple_id(ENV["APPLE_ID"] || "developer@example.com")
itc_team_id(ENV["ITC_TEAM_ID"])
team_id(ENV["TEAM_ID"])
```

### 4.5 iOS Matchfile

```ruby
# ios/fastlane/Matchfile
git_url(ENV["MATCH_GIT_URL"] || "git@github.com:example/certificates.git")
storage_mode("git")

type("development")  # 기본값, lane에서 오버라이드

app_identifier([
  "com.example.app",
  "com.example.app.dev",
  "com.example.app.staging"
])

username(ENV["APPLE_ID"])
team_id(ENV["TEAM_ID"])

readonly(true)  # CI에서는 항상 readonly
```

### 4.6 Android Fastfile

```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  # ========================================
  # 빌드
  # ========================================

  desc "Build development APK"
  lane :build_dev do
    gradle(
      task: "assemble",
      flavor: "dev",
      build_type: "Release",
      project_dir: "./"
    )
  end

  desc "Build staging APK"
  lane :build_staging do
    gradle(
      task: "assemble",
      flavor: "staging",
      build_type: "Release",
      project_dir: "./"
    )
  end

  desc "Build production AAB"
  lane :build_prod do
    gradle(
      task: "bundle",
      flavor: "prod",
      build_type: "Release",
      project_dir: "./"
    )
  end

  # ========================================
  # 배포
  # ========================================

  desc "Deploy to Firebase App Distribution"
  lane :deploy_firebase do |options|
    firebase_app_distribution(
      app: ENV["FIREBASE_ANDROID_APP_ID"],
      apk_path: options[:apk_path] || "../build/app/outputs/flutter-apk/app-release.apk",
      groups: options[:groups] || "testers",
      release_notes: options[:notes] || changelog_from_git_commits(commits_count: 10)
    )
  end

  desc "Deploy to Play Store Internal"
  lane :deploy_internal do |options|
    upload_to_play_store(
      track: "internal",
      aab: options[:aab_path] || ENV["AAB_PATH"] || "../build/app/outputs/bundle/prodRelease/app-prod-release.aab",
      json_key_data: ENV["SUPPLY_JSON_KEY_DATA"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Deploy to Play Store Alpha"
  lane :deploy_alpha do |options|
    upload_to_play_store(
      track: "alpha",
      aab: options[:aab_path] || "../build/app/outputs/bundle/prodRelease/app-prod-release.aab",
      json_key_data: ENV["SUPPLY_JSON_KEY_DATA"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Deploy to Play Store Beta"
  lane :deploy_beta do |options|
    upload_to_play_store(
      track: "beta",
      aab: options[:aab_path] || "../build/app/outputs/bundle/prodRelease/app-prod-release.aab",
      json_key_data: ENV["SUPPLY_JSON_KEY_DATA"],
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  desc "Promote Internal to Production"
  lane :promote_to_production do
    upload_to_play_store(
      track: "internal",
      track_promote_to: "production",
      json_key_data: ENV["SUPPLY_JSON_KEY_DATA"],
      skip_upload_aab: true,
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true
    )
  end

  # ========================================
  # 버전 관리
  # ========================================

  desc "Get current version code"
  lane :get_version_code do
    version_code = google_play_track_version_codes(
      track: "internal",
      json_key_data: ENV["SUPPLY_JSON_KEY_DATA"]
    ).max || 0

    UI.message("Current version code: #{version_code}")
    version_code
  end

  desc "Increment version code"
  lane :increment_version_code do
    current = get_version_code
    new_version_code = current + 1

    # Flutter pubspec.yaml의 build number 업데이트
    sh("cd ../.. && sed -i '' 's/version: \\(.*\\)+.*/version: \\1+#{new_version_code}/' pubspec.yaml")

    UI.success("Version code incremented to: #{new_version_code}")
    new_version_code
  end

  # ========================================
  # 유틸리티
  # ========================================

  desc "Clean build"
  lane :clean do
    gradle(task: "clean", project_dir: "./")
    sh("cd ../.. && rm -rf build/app")
  end

  error do |lane, exception|
    slack(
      message: "Android Build Failed",
      success: false,
      payload: {
        "Lane" => lane,
        "Error" => exception.message
      },
      default_payloads: [:git_branch, :git_author]
    ) if ENV["SLACK_URL"]
  end
end
```

### 4.7 Android Appfile

```ruby
# android/fastlane/Appfile
json_key_file(ENV["GOOGLE_PLAY_JSON_KEY_PATH"])
package_name(ENV["PACKAGE_NAME"] || "com.example.app")
```

## 5. 환경별 빌드

### 5.1 Flavor 설정 (Android)

```kotlin
// android/app/build.gradle.kts
android {
    namespace = "com.example.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "MyApp Dev")

            buildConfigField("String", "API_BASE_URL", "\"https://api-dev.example.com\"")
            buildConfigField("Boolean", "ENABLE_LOGGING", "true")
        }

        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "MyApp Staging")

            buildConfigField("String", "API_BASE_URL", "\"https://api-staging.example.com\"")
            buildConfigField("Boolean", "ENABLE_LOGGING", "true")
        }

        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "MyApp")

            buildConfigField("String", "API_BASE_URL", "\"https://api.example.com\"")
            buildConfigField("Boolean", "ENABLE_LOGGING", "false")
        }
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = java.util.Properties()
                keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))

                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".debug"
        }
    }
}
```

### 5.2 Scheme 설정 (iOS)

```ruby
# ios/Podfile
platform :ios, '14.0'

# Flavor별 Bundle ID 매핑
def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist."
  end
  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # 환경별 설정
  target 'Runner-dev' do
    inherit! :complete
  end

  target 'Runner-staging' do
    inherit! :complete
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### 5.3 ExportOptions.plist

```xml
<!-- ios/ExportOptions-dev.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>

<!-- ios/ExportOptions-staging.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.example.app.staging</key>
        <string>match AdHoc com.example.app.staging</string>
    </dict>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>

<!-- ios/ExportOptions-prod.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.example.app</key>
        <string>match AppStore com.example.app</string>
    </dict>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### 5.4 빌드 명령어

```bash
#!/bin/bash
# scripts/build.sh

set -e

FLAVOR=${1:-dev}
PLATFORM=${2:-all}
BUILD_NUMBER=${3:-$(date +%s)}

echo "Building $FLAVOR for $PLATFORM (build: $BUILD_NUMBER)"

# Android APK
if [[ "$PLATFORM" == "android" || "$PLATFORM" == "all" ]]; then
  echo "Building Android APK..."
  flutter build apk \
    --flavor $FLAVOR \
    --dart-define=ENV=$FLAVOR \
    --dart-define=BUILD_NUMBER=$BUILD_NUMBER \
    --release
fi

# Android App Bundle
if [[ "$PLATFORM" == "android-aab" ]]; then
  echo "Building Android AAB..."
  flutter build appbundle \
    --flavor $FLAVOR \
    --dart-define=ENV=$FLAVOR \
    --dart-define=BUILD_NUMBER=$BUILD_NUMBER \
    --release
fi

# iOS
if [[ "$PLATFORM" == "ios" || "$PLATFORM" == "all" ]]; then
  echo "Building iOS IPA..."
  flutter build ipa \
    --flavor $FLAVOR \
    --dart-define=ENV=$FLAVOR \
    --dart-define=BUILD_NUMBER=$BUILD_NUMBER \
    --export-options-plist=ios/ExportOptions-$FLAVOR.plist
fi

echo "Build completed!"
```

## 6. 코드 서명

### 6.1 Android Keystore 생성

```bash
#!/bin/bash
# scripts/generate_keystore.sh

# Keystore 생성
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias release

# key.properties 생성
cat > android/key.properties << EOF
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=release
storeFile=keystore.jks
EOF

echo "Keystore generated! Add key.properties to .gitignore"
```

### 6.2 Keystore Base64 인코딩 (CI용)

```bash
# Keystore를 Base64로 인코딩 (GitHub Secrets에 저장)
base64 -i android/app/keystore.jks | pbcopy
echo "Keystore copied to clipboard. Add to KEYSTORE_BASE64 secret."

# CI에서 복원
echo "$KEYSTORE_BASE64" | base64 -d > android/app/keystore.jks
```

### 6.3 iOS Match 설정

```bash
# Match 초기화 (처음 한 번)
cd ios
fastlane match init

# 인증서 생성 (개발/배포 모두)
fastlane match development
fastlane match adhoc
fastlane match appstore

# 기존 인증서 취소 후 재생성 (주의!)
fastlane match nuke development
fastlane match nuke adhoc
fastlane match nuke appstore
```

### 6.4 App Store Connect API Key 생성

```bash
# 1. App Store Connect → Users and Access → Keys → Generate API Key
# 2. Key 정보 저장:
#    - Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#    - Key ID: XXXXXXXXXX
#    - .p8 파일 다운로드

# 3. GitHub Secrets에 저장:
#    - APPSTORE_API_KEY_ID: Key ID
#    - APPSTORE_ISSUER_ID: Issuer ID
#    - APPSTORE_API_PRIVATE_KEY: .p8 파일 내용 (그대로)
```

### 6.5 Google Play Service Account 설정

```bash
# 1. Google Cloud Console → IAM & Admin → Service Accounts
# 2. Create Service Account
# 3. Grant "Service Account User" role
# 4. Create Key (JSON)

# 5. Google Play Console → Settings → API access
# 6. Link service account
# 7. Grant "Release Manager" or "Admin" permission

# 8. GitHub Secrets에 JSON 파일 내용 저장:
#    - PLAY_STORE_SERVICE_ACCOUNT: JSON 파일 전체 내용
```

## 7. 자동 배포

### 7.1 배포 파이프라인 전략

```
┌─────────────────────────────────────────────────────────────────┐
│                        배포 전략                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  feature/* ──┬──▶ develop ──▶ release/* ──▶ main ──▶ tag       │
│              │                                                   │
│              ▼                     ▼             ▼               │
│         Unit Tests            Firebase      Play Store          │
│         Lint/Analyze        (QA Team)        Internal           │
│                                                  │               │
│                                                  ▼               │
│                                            TestFlight            │
│                                                  │               │
│                                                  ▼               │
│                                           App Store /            │
│                                           Play Store             │
│                                           Production             │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Firebase App Distribution

```yaml
# .github/workflows/firebase_distribution.yml
name: Firebase Distribution

on:
  push:
    branches: [develop]
  workflow_dispatch:
    inputs:
      platform:
        description: 'Platform'
        required: true
        default: 'both'
        type: choice
        options:
          - android
          - ios
          - both
      groups:
        description: 'Tester groups'
        required: true
        default: 'internal-testers'

jobs:
  distribute:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          cache: true

      - name: Build & Distribute Android
        if: inputs.platform == 'android' || inputs.platform == 'both'
        run: |
          flutter build apk --flavor dev --dart-define=ENV=dev

          # Firebase CLI로 배포
          curl -sL https://firebase.tools | bash
          firebase appdistribution:distribute \
            build/app/outputs/flutter-apk/app-dev-release.apk \
            --app ${{ secrets.FIREBASE_ANDROID_APP_ID }} \
            --groups "${{ inputs.groups || 'internal-testers' }}" \
            --release-notes "Build ${{ github.run_number }} from ${{ github.ref_name }}"
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_PATH }}

      - name: Build & Distribute iOS
        if: inputs.platform == 'ios' || inputs.platform == 'both'
        run: |
          flutter build ipa --flavor dev --export-options-plist=ios/ExportOptions-dev.plist

          firebase appdistribution:distribute \
            "build/ios/ipa/*.ipa" \
            --app ${{ secrets.FIREBASE_IOS_APP_ID }} \
            --groups "${{ inputs.groups || 'internal-testers' }}" \
            --release-notes "Build ${{ github.run_number }} from ${{ github.ref_name }}"
```

### 7.3 Play Store 배포 자동화

```yaml
# .github/workflows/play_store.yml
name: Play Store Release

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      track:
        description: 'Release track'
        required: true
        default: 'internal'
        type: choice
        options:
          - internal
          - alpha
          - beta
          - production

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'

      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=keystore.jks
          EOF

      - name: Build AAB
        run: |
          flutter build appbundle \
            --flavor prod \
            --dart-define=ENV=prod \
            --dart-define=BUILD_NUMBER=${{ github.run_number }}

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true

      - name: Deploy to Play Store
        run: |
          cd android
          bundle exec fastlane deploy_${{ inputs.track || 'internal' }}
        env:
          SUPPLY_JSON_KEY_DATA: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
```

### 7.4 App Store 배포 자동화

```yaml
# .github/workflows/app_store.yml
name: App Store Release

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      submit_for_review:
        description: 'Submit for review'
        required: true
        default: false
        type: boolean

jobs:
  deploy:
    runs-on: macos-14
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
          working-directory: ios

      - name: Install CocoaPods
        run: cd ios && bundle exec pod install

      - name: Import certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_PASSWORD }}

      - name: Download provisioning profiles
        uses: apple-actions/download-provisioning-profiles@v2
        with:
          bundle-id: com.example.app
          profile-type: IOS_APP_STORE
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}

      - name: Build IPA
        run: |
          flutter build ipa \
            --flavor prod \
            --dart-define=ENV=prod \
            --export-options-plist=ios/ExportOptions-prod.plist

      - name: Deploy to TestFlight
        run: |
          cd ios
          bundle exec fastlane deploy_testflight
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APPSTORE_API_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APPSTORE_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}

      - name: Submit for Review
        if: inputs.submit_for_review
        run: |
          cd ios
          bundle exec fastlane deploy_appstore
        env:
          APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APPSTORE_API_KEY_ID }}
          APP_STORE_CONNECT_API_KEY_ISSUER_ID: ${{ secrets.APPSTORE_ISSUER_ID }}
          APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

## 8. 버전 관리

### 8.1 Semantic Versioning

```
버전 형식: MAJOR.MINOR.PATCH+BUILD

예: 1.2.3+45

- MAJOR: 호환되지 않는 API 변경
- MINOR: 하위 호환되는 기능 추가
- PATCH: 하위 호환되는 버그 수정
- BUILD: CI 빌드 번호 (자동 증가)
```

### 8.2 pubspec.yaml 버전 관리

```yaml
# pubspec.yaml
name: my_app
description: My Flutter App
version: 1.2.3+45  # MAJOR.MINOR.PATCH+BUILD

environment:
  sdk: '>=3.5.0 <4.0.0'
```

### 8.3 버전 자동 증가 스크립트

```bash
#!/bin/bash
# scripts/bump_version.sh

set -e

BUMP_TYPE=${1:-patch}  # major, minor, patch
PUBSPEC_FILE="pubspec.yaml"

# 현재 버전 추출
CURRENT_VERSION=$(grep "^version:" $PUBSPEC_FILE | sed 's/version: //')
VERSION_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# 버전 분리
MAJOR=$(echo $VERSION_NUMBER | cut -d'.' -f1)
MINOR=$(echo $VERSION_NUMBER | cut -d'.' -f2)
PATCH=$(echo $VERSION_NUMBER | cut -d'.' -f3)

# 버전 증가
case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

# 빌드 번호 증가
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_VERSION="$MAJOR.$MINOR.$PATCH+$NEW_BUILD"

# pubspec.yaml 업데이트
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC_FILE
else
  sed -i "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC_FILE
fi

echo "Version bumped: $CURRENT_VERSION → $NEW_VERSION"

# Git 태그 생성 (선택)
if [[ "$2" == "--tag" ]]; then
  git add $PUBSPEC_FILE
  git commit -m "chore: bump version to $NEW_VERSION"
  git tag -a "v$MAJOR.$MINOR.$PATCH" -m "Release v$MAJOR.$MINOR.$PATCH"
  echo "Created tag: v$MAJOR.$MINOR.$PATCH"
fi
```

### 8.4 Git Tag 기반 릴리즈

```yaml
# .github/workflows/release.yml
name: Create Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get version from tag
        id: version
        run: echo "VERSION=${GITHUB_REF#refs/tags/v}" >> $GITHUB_OUTPUT

      - name: Generate changelog
        id: changelog
        uses: metcalfc/changelog-generator@v4.1.0
        with:
          myToken: ${{ secrets.GITHUB_TOKEN }}

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          name: Release v${{ steps.version.outputs.VERSION }}
          body: ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: ${{ contains(github.ref, '-') }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 8.5 자동 버전 업데이트 워크플로우

```yaml
# .github/workflows/auto_version.yml
name: Auto Version Bump

on:
  pull_request:
    types: [closed]
    branches: [main]

jobs:
  bump:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.PAT_TOKEN }}

      - name: Determine bump type
        id: bump
        run: |
          PR_TITLE="${{ github.event.pull_request.title }}"
          if [[ "$PR_TITLE" == *"BREAKING"* ]] || [[ "$PR_TITLE" == *"!"* ]]; then
            echo "TYPE=major" >> $GITHUB_OUTPUT
          elif [[ "$PR_TITLE" == feat* ]]; then
            echo "TYPE=minor" >> $GITHUB_OUTPUT
          else
            echo "TYPE=patch" >> $GITHUB_OUTPUT
          fi

      - name: Bump version
        run: |
          chmod +x scripts/bump_version.sh
          ./scripts/bump_version.sh ${{ steps.bump.outputs.TYPE }}

      - name: Commit and push
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add pubspec.yaml
          git commit -m "chore: bump version [skip ci]"
          git push
```

## 9. 모니터링 및 알림

### 9.1 Slack 통합

```yaml
# .github/workflows/notify.yml
name: Build Notifications

on:
  workflow_run:
    workflows: ["Flutter CI/CD"]
    types: [completed]

jobs:
  notify:
    runs-on: ubuntu-latest

    steps:
      - name: Build Success
        if: ${{ github.event.workflow_run.conclusion == 'success' }}
        uses: slackapi/slack-github-action@v1.27.0
        with:
          payload: |
            {
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "✅ *Build Successful*\n*Repository:* ${{ github.repository }}\n*Branch:* ${{ github.event.workflow_run.head_branch }}\n*Commit:* `${{ github.event.workflow_run.head_sha }}`"
                  }
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {"type": "plain_text", "text": "View Build"},
                      "url": "${{ github.event.workflow_run.html_url }}"
                    }
                  ]
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK

      - name: Build Failure
        if: ${{ github.event.workflow_run.conclusion == 'failure' }}
        uses: slackapi/slack-github-action@v1.27.0
        with:
          payload: |
            {
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "❌ *Build Failed*\n*Repository:* ${{ github.repository }}\n*Branch:* ${{ github.event.workflow_run.head_branch }}\n*Triggered by:* ${{ github.event.workflow_run.actor.login }}"
                  }
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {"type": "plain_text", "text": "View Logs"},
                      "style": "danger",
                      "url": "${{ github.event.workflow_run.html_url }}"
                    }
                  ]
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK
```

### 9.2 Discord 통합

```yaml
# Discord 웹훅 알림
- name: Notify Discord
  uses: sarisia/actions-status-discord@v1
  if: always()
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK }}
    status: ${{ job.status }}
    title: "Flutter Build"
    description: "Build #${{ github.run_number }} on ${{ github.ref_name }}"
    color: ${{ job.status == 'success' && '0x00ff00' || '0xff0000' }}
    url: "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```

### 9.3 빌드 상태 배지

```markdown
<!-- README.md -->
# My Flutter App

[![CI](https://github.com/username/repo/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/username/repo/actions/workflows/flutter_ci.yml)
[![codecov](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
```

### 9.4 빌드 메트릭 수집

```yaml
# .github/workflows/metrics.yml
name: Build Metrics

on:
  workflow_run:
    workflows: ["Flutter CI/CD"]
    types: [completed]

jobs:
  metrics:
    runs-on: ubuntu-latest

    steps:
      - name: Collect build metrics
        run: |
          BUILD_DURATION=${{ github.event.workflow_run.run_started_at }}
          BUILD_STATUS=${{ github.event.workflow_run.conclusion }}

          # DataDog, New Relic 등으로 메트릭 전송
          curl -X POST "https://api.datadoghq.com/api/v1/series" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${{ secrets.DATADOG_API_KEY }}" \
            -d '{
              "series": [{
                "metric": "flutter.build.duration",
                "points": [['"$(date +%s)"', '"$BUILD_DURATION"']],
                "tags": ["status:'"$BUILD_STATUS"'", "repo:${{ github.repository }}"]
              }]
            }'
```

## 10. Best Practices

### 10.1 CI/CD 체크리스트

| 항목 | Dev | Staging | Prod |
|------|:---:|:-------:|:----:|
| 코드 분석 (lint) | ✅ | ✅ | ✅ |
| 단위 테스트 | ✅ | ✅ | ✅ |
| 통합 테스트 | ❌ | ✅ | ✅ |
| 코드 커버리지 | ✅ | ✅ | ✅ |
| 앱 빌드 | ✅ | ✅ | ✅ |
| 코드 서명 | ❌ | ✅ | ✅ |
| Firebase 배포 | ✅ | ✅ | ❌ |
| 스토어 배포 | ❌ | ❌ | ✅ |
| Slack 알림 | ❌ | ✅ | ✅ |

### 10.2 시크릿 관리

```yaml
# 환경별 시크릿 분리 (GitHub Environments)
Development:
  - FIREBASE_ANDROID_APP_ID_DEV
  - FIREBASE_IOS_APP_ID_DEV

Staging:
  - FIREBASE_ANDROID_APP_ID_STAGING
  - FIREBASE_IOS_APP_ID_STAGING

Production:
  - KEYSTORE_BASE64
  - KEYSTORE_PASSWORD
  - KEY_ALIAS
  - KEY_PASSWORD
  - CERTIFICATES_P12
  - CERTIFICATES_PASSWORD
  - APPSTORE_API_KEY_ID
  - APPSTORE_ISSUER_ID
  - APPSTORE_API_PRIVATE_KEY
  - PLAY_STORE_SERVICE_ACCOUNT
```

### 10.3 캐싱 전략

```yaml
# 효율적인 캐싱으로 빌드 시간 단축
- name: Cache Flutter SDK
  uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      ${{ env.FLUTTER_HOME }}
    key: flutter-${{ env.FLUTTER_VERSION }}-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      flutter-${{ env.FLUTTER_VERSION }}-
      flutter-

- name: Cache Gradle
  uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    restore-keys: gradle-

- name: Cache CocoaPods
  uses: actions/cache@v4
  with:
    path: ios/Pods
    key: pods-${{ hashFiles('ios/Podfile.lock') }}
    restore-keys: pods-
```

### 10.4 DO (권장 사항)

```yaml
# ✅ 병렬 실행으로 시간 단축
jobs:
  analyze:
    runs-on: ubuntu-latest
  build-android:
    needs: analyze  # analyze 완료 후
  build-ios:
    needs: analyze  # 병렬로 실행

# ✅ Matrix 빌드로 중복 제거
strategy:
  matrix:
    flavor: [dev, staging, prod]

# ✅ 조건부 실행
if: github.event_name == 'release'

# ✅ 타임아웃 설정
timeout-minutes: 30

# ✅ 실패 시 계속 진행 (선택적)
continue-on-error: true

# ✅ Concurrency로 중복 빌드 취소
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 10.5 DON'T (금지 사항)

```yaml
# ❌ 시크릿 직접 노출
run: echo ${{ secrets.API_KEY }}  # 로그에 노출됨!

# ❌ 무한 타임아웃
# timeout-minutes 없으면 기본 6시간

# ❌ 불필요한 단계 반복
# 각 job에서 flutter pub get 여러 번 실행

# ❌ 큰 아티팩트 장기 보관
retention-days: 90  # 너무 김, 7-14일 권장

# ❌ main 브랜치 직접 푸시 허용
# Branch protection rules 설정 필요
```

### 10.6 보안 권장사항

```yaml
# 1. 최소 권한 원칙
permissions:
  contents: read
  packages: write

# 2. 환경 보호 (수동 승인)
environment:
  name: production
  url: https://example.com

# 3. 시크릿 스캔
- uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
    head: HEAD

# 4. 의존성 취약점 검사
- name: Run Snyk
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### 10.7 빌드 시간 최적화

| 최적화 기법 | 예상 절감 | 적용 난이도 |
|------------|----------|------------|
| Flutter/Gradle 캐싱 | 30-50% | 쉬움 |
| 병렬 job 실행 | 20-40% | 쉬움 |
| M1 Mac 사용 (iOS) | 30-50% | 쉬움 |
| 조건부 빌드 | 50-70% | 보통 |
| 증분 빌드 | 20-30% | 어려움 |

## 11. 롤백 및 장애 대응

### 11.1 롤백 절차

#### Play Store 롤백
```bash
# 1. 단계적 출시 중지
# Play Console → Release → Halt staged rollout

# 2. 이전 버전으로 롤백
# Play Console → Release management → App releases
# → Production → Release history → Select previous version → Rollback
```

#### App Store 롤백
```bash
# App Store에는 자동 롤백이 없음
# 옵션:
# 1. 이전 빌드를 새 버전으로 다시 제출 (Expedited Review 요청)
# 2. 현재 버전 판매 중지 (Remove from Sale)
# 3. Phased Release 일시 중지
```

#### Firebase App Distribution 롤백
```bash
# 이전 빌드 재배포
firebase appdistribution:distribute \
  --app <app-id> \
  --groups "beta-testers" \
  build/previous-version.apk
```

### 11.2 Hotfix 워크플로우

```yaml
# .github/workflows/hotfix.yml
name: Hotfix Deploy
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Hotfix version (e.g., 1.2.1)'
        required: true

jobs:
  hotfix:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
      - name: Create hotfix branch
        run: |
          git checkout -b hotfix/${{ inputs.version }}
      - name: Apply fix and build
        run: flutter build apk --release
      - name: Deploy to internal track
        run: fastlane android internal
```

### 11.3 장애 등급 및 대응

| 등급 | 정의 | 대응 시간 | 조치 |
|-----|------|---------|------|
| P1 | 앱 전체 크래시, 결제 불가 | 15분 내 | 즉시 롤백, 전체 팀 소집 |
| P2 | 주요 기능 장애 | 1시간 내 | 핫픽스 배포, 담당자 대응 |
| P3 | 일부 사용자 영향 | 24시간 내 | 다음 릴리즈에 수정 |
| P4 | 사소한 버그 | 1주일 내 | 백로그 등록 |

## 12. 문제 해결

### 12.1 일반적인 오류

```bash
# 오류: Gradle 빌드 실패
Error: Execution failed for task ':app:compileReleaseKotlin'

# 해결: Java 버전 확인
java -version  # Java 17 필요
```

```bash
# 오류: iOS 서명 실패
error: No signing certificate "iOS Distribution" found

# 해결: 인증서 확인
security find-identity -v -p codesigning
fastlane match appstore --readonly
```

```bash
# 오류: Pod 설치 실패
[!] CocoaPods could not find compatible versions for pod

# 해결: Pod 캐시 정리
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install --repo-update
```

### 12.2 GitHub Actions 디버깅

```yaml
# 디버그 로깅 활성화
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true

# SSH 디버깅 (tmate)
- name: Setup tmate session
  uses: mxschmitt/action-tmate@v3
  if: failure()
  timeout-minutes: 15
```

### 12.3 Fastlane 디버깅

```bash
# 상세 로그
fastlane ios build_prod --verbose

# 환경 정보
fastlane env

# 인증서 상태
fastlane match nuke development --readonly
```

## 13. 참고

### 13.1 공식 문서

- [Flutter CI/CD](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Codemagic](https://docs.codemagic.io/)
- [Fastlane](https://docs.fastlane.tools/)

### 13.2 관련 도구

- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Google Play Developer API](https://developers.google.com/android-publisher)

### 13.3 GitHub Actions Marketplace

- [flutter-action](https://github.com/subosito/flutter-action)
- [codecov-action](https://github.com/codecov/codecov-action)
- [slack-github-action](https://github.com/slackapi/slack-github-action)
- [firebase-distribution](https://github.com/wzieba/Firebase-Distribution-Github-Action)
