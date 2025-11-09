## 📦 Download

You can download the latest release of **SABANG-ES-PROJECT v1.0.0** from the link below:

➡️ [**Download SABANG-ES-PROJECT v1.0.0**](https://github.com/shazkun/SABANG-ES-PROJECT/releases/tag/v1.0.0)

---

### 🧩 How to Install
1. Go to the [releases page](https://github.com/shazkun/SABANG-ES-PROJECT/releases).
2. Find **v1.0.0** and click on **Assets**.
3. Download the `.zip` or `.bin` file you need.
4. Follow the instructions in the documentation to install.

---

# 📱 QR Scanner and Generator App

A powerful app for schools and organizations to manage **attendance** and **identity verification** using dynamic QR codes. Features include **scanning with IN/OUT toggle**, **QR generation (single and batch)**, **custom messages**, and **secure Gmail integration** using **App Passwords**.

---

## 🚀 Features Overview

### 🔍 QR Scanner

* **IN/OUT Toggle** — Select scan type: `IN` or `OUT`
* **Floating Action Button** — Tap to initiate scan
* **Custom Message Display** — Shows a personalized message after a successful scan
* **Timestamp Logging** — Automatically logs date and time of each scan

### 🧾 QR Generator

* **Input Fields**:

  * `Name` (required)
  * `Email` (required)
  * `Year/Section` (required)
* **Options**:

  * Generate **Single QR** code
  * Generate **Batch QR** codes via `.csv` or `.xlsx`
* **Preview & Manage** output in **QR Viewer**

### 🖼️ QR Viewer

* View all generated QR codes
* Actions:

  * ✅ Save/Download QR (stored in `Documents` folder)
  * 🗑️ Delete QR
  * ✏️ Edit/Update QR details

### ✉️ Email Integration (Gmail)

* Uses **Google App Passwords** for secure email sending
* **Gmail requirements**:

  * Verified mobile number
  * 2-Step Verification **enabled**
* Configuration:

  * Enter your **Gmail address**
  * Enter **App Password** (16-character code from Google)

---

## 🛠️ Custom IN/OUT Messages

Set custom messages shown after each scan.
Supports dynamic placeholders:

| Placeholder  | Description               |
| ------------ | ------------------------- |
| `{name}`     | Scanned person's name     |
| `{datetime}` | Date and time of the scan |

**Example Templates:**

* IN: `Hi {name}, welcome! You checked in at {datetime}.`
* OUT: `Goodbye {name}, you checked out at {datetime}.`

> Configure under `Settings > Custom Messages`.

---

## 📂 Sample CSV Format (for Batch QR Generation)

```
Name,Email,Year
John Doe,john.doe@example.com,2325
Jane Smith,jane.smith@example.com,2325
Carlos Dela Cruz,carlos.delacruz@example.com,2325
Maria Santos,maria.santos@example.com,2325
Mark Reyes,mark.reyes@example.com,2325
```

✅ **Important Notes**:

* Column headers must be: `Name`, `Email`, `Year` (no extra spaces)
* File must be `.csv` or `.xlsx`
* For large lists, use a new page when printing

---

## 🛠️ Requirements

### 📦 Python Modules

Make sure these Python modules are installed.

**For CMD (Windows):**

```cmd
pip install opencv-python pyzbar pandas openpyxl
```

**For Microsoft Store Python (using `py`):**

```cmd
py -m pip install opencv-python pyzbar pandas openpyxl
```

These libraries are needed for:

* `opencv-python`: camera access and image processing
* `pyzbar`: scanning and decoding QR codes
* `pandas` and `openpyxl`: reading `.csv` and `.xlsx` files for batch generation

---

### 🧱 Windows Dependencies

If you're on Windows and see errors related to missing DLL files or runtime components:

➡️ **Install the latest Microsoft Visual C++ Redistributable**
🔗 [https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170)

---

## 📋 Troubleshooting

| Issue                       | Solution                                                        |
| --------------------------- | --------------------------------------------------------------- |
| QR not scanning             | Ensure camera is clear and lighting is good                     |
| Custom messages not showing | Check if message template is set in Settings                    |
| Batch file errors           | Ensure proper column names and format (see sample above)        |
| Email not sending           | Confirm 2FA is enabled and App Password is correctly configured |

---

## 📞 Support

For questions or technical help:

* **Email**: [seanwiltonr@gmail.com](mailto:seanwiltonr@gmail.com)
* **Phone**: +63-966-987-7706

---


