# ASALARY – cấu trúc dự án

```
android_res/                      # biểu tượng app (chữ S) + biểu tượng thông báo, chép vào res/ khi build
lib/
├─ main.dart                      # điểm vào
├─ app/salary_app.dart            # MaterialApp, vòng đời, đổi ngôn ngữ, đặt lịch nhắc
├─ core/
│  ├─ constants/                  # app_colors, app_constants (kAppName...), platform_features
│  ├─ l10n/                       # app_language, en_translations, translator (tr)
│  └─ utils/                      # formatters, date_utils, number_parser, validators
├─ data/
│  ├─ models/                     # WorkRecord, PeriodSummary, Reminder/ReminderConfig, BackupData...
│  ├─ database/                   # AppDatabase (sqflite)
│  └─ preferences/                # AppSettings (hồ sơ, nhắc nhở...), ActiveShift
├─ logic/                         # nghiệp vụ thuần Dart
│  ├─ pay_calculator, summary_calculator, day_type, period_utils, export_range, import_planner
│  └─ controllers/                # AppController, AppLock, AvatarController
├─ services/
│  ├─ export/                     # csv / xlsx / pdf, lưu vào máy (file_picker) và chia sẻ
│  ├─ security/                   # lock_store, biometrics, password_hasher
│  └─ reminder_service, avatar_store, auto_backup_service (tự động sao lưu định kỳ)
└─ presentation/
   ├─ theme/                      # app_theme (có vuốt cạnh để quay lại), day_type_style
   ├─ widgets/                    # Text (có dịch), Pill, settings_widgets, profile_texts, toast...
   └─ screens/
      ├─ home/                    # trang chính + ProfileHeader (avatar, công ty, tên, ID)
      ├─ history/                 # lịch sử ca + thống kê từng ngày (DaySummaryCard)
      ├─ settings/                # SettingsPage + Hồ sơ + Lương & ngày lễ
      ├─ reminders/               # danh sách nhắc nhở + trang sửa (T2–CN, Lễ)
      ├─ lock/ backup/ export/ avatar/ about/ compare/ shift/
```

Quy ước: import nội bộ dạng `package:theo_doi_luong/...`; mỗi mục con của Cài đặt là một trang
riêng (mũi tên quay lại hoặc vuốt từ cạnh trái). Font `LiberationSans-*.ttf` để ở thư mục gốc repo.
