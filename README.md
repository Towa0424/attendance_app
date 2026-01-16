# Attendance App

## アプリケーション名
Attendance App

## アプリケーション概要
勤怠の打刻と管理を行う勤怠管理アプリです。従業員は打刻（出退勤登録）を行い、管理者はユーザー・グループ・勤務時間帯・シフトパターンを管理し、シフトの割り当てや詳細更新を行えます。

## URL
- https://46.51.245.248

## テスト用アカウント
### 管理アカウント
- ID：demo@mail.com
- PW：demo1234
### 一般アカウント
- ID：demo1@mail.com
- PW：demo1234
## 利用方法
- ログイン後、勤怠一覧から打刻を登録します。
- 管理者は管理画面からユーザー・グループ・勤務時間帯・シフトパターンを管理します。
- 管理者はシフト一覧で割り当て・詳細更新を行います。

## アプリケーションを作成した背景
- 勤怠管理の入力・集計を簡略化し、現場と管理者の負担を減らすことを目的としています。

## 実装した機能についての説明
- 勤怠打刻（時間記録の登録）
  - [![Image from Gyazo](https://i.gyazo.com/801e3a69e453a115c3f8ebe30a53927f.gif)](https://gyazo.com/801e3a69e453a115c3f8ebe30a53927f)
- 管理者によるユーザー管理
  - [![Image from Gyazo](https://i.gyazo.com/a398f9757ad6c2e69f32664ad23aaa85.gif)](https://gyazo.com/a398f9757ad6c2e69f32664ad23aaa85)
- 管理者によるグループ管理
  - [![Image from Gyazo](https://i.gyazo.com/1ce194b027b8d211b352cf15f8437ee7.gif)](https://gyazo.com/1ce194b027b8d211b352cf15f8437ee7)
- 管理者による時間ブロック管理
  - [![Image from Gyazo](https://i.gyazo.com/1344c6cfb4c334a4a44cbe45bd064c27.gif)](https://gyazo.com/1344c6cfb4c334a4a44cbe45bd064c27)
- 管理者によるシフトパターン管理
  - [![Image from Gyazo](https://i.gyazo.com/1976f6af0fec6bcc3cb0e4e409efc551.gif)](https://gyazo.com/1976f6af0fec6bcc3cb0e4e409efc551)    
- シフトの割り当て・詳細更新
  - [![Image from Gyazo](https://i.gyazo.com/3567d5af0af4b6022fe9400041309867.gif)](https://gyazo.com/3567d5af0af4b6022fe9400041309867)

  ## 実装予定の機能
- 各スタッフごとの勤怠詳細一覧機能
- シフト希望提出機能
- 各種集計ダッシュボード機能

## データベース設計

## 開発環境
- Ruby 3.2.0
- Rails 7.1.6
- MySQL（`mysql2`）
