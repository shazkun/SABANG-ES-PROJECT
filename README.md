QR Scanner and Generator App
Introduction
The QR Scanner and Generator App is designed for schools and organizations to manage attendance and identity verification using QR code technology. Key features include QR scanning with IN/OUT toggle, customizable messages, QR code generation (single and batch), QR code management via QR Viewer, and secure email integration using Google App Password.
Features Overview
QR Scanner

IN/OUT Toggle: Select scan type (IN or OUT).
Floating Button: Located at the bottom-right of the scanner screen to initiate scanning.
Custom Message: Displays personalized messages after each scan.

QR Generator

Input Fields: Name (required), Email, Section.
Options:
Generate Single QR code.
Generate Batch QR codes using CSV/XLSX files.


Output: Preview generated QR codes in the QR Viewer.

Email Settings

Uses Google App Password for secure email sending.
Requires a Gmail account with:
Verified mobile number.
2-Step Verification enabled.



Custom IN/OUT Messages

Configure personalized messages for IN and OUT scans.
Supports dynamic fields:
{name}: Inserts the scanned person's name.
{datetime}: Inserts the date and time of the scan.



Using the QR Scanner

Tap the Floating QR Scanner button.
Set the IN/OUT Toggle to the desired mode.
Aim the camera at a valid QR code.
On successful scan:
Data is logged with a timestamp.
A custom message is displayed based on the selected mode.



Setting Custom IN/OUT Messages

Location: Settings > Custom Messages.
Input Fields:
IN Message: Message shown after a successful IN scan.
OUT Message: Message shown after a successful OUT scan.


Template Support:
Use {name} for the scanned person's name.
Use {datetime} for the scan date and time.


Example:
IN: Hi {name}, welcome! You have successfully checked in at {datetime}.
OUT: Hello {name}, your QR code was scanned for check-out at {datetime}.



QR Generator

Open the QR Generator tab.
Fill in the form:
Name (required)
Email (required)
Year (required)


Choose:
Generate Single: Creates one QR code.
Generate Batch: Creates multiple QR codes using a CSV/XLSX file.


View results in the QR Viewer.

Sample CSV Template for Batch Generation
Name,Email,Year
John Doe,john.doe@example.com,2325
Jane Smith,jane.smith@example.com,2325
Carlos Dela Cruz,carlos.delacruz@example.com,2325
Maria Santos,maria.santos@example.com,2325
Mark Reyes,mark.reyes@example.com,2325

Important: Ensure the CSV file uses exact column headers (Name, Email, Year) without extra spaces or special characters. For proper formatting, start the table on a new page if it does not fit the layout when printed.
QR Viewer

Displays all generated QR codes.
Actions:
Save/Download Image (saved to the device's Documents folder on mobile and desktop).
Delete QR code.
Edit/Update QR code.



Email Settings
To enable automated email features:

Enable 2-Step Verification on your Google account.
Go to Google Account Security > App Passwords.
Generate an App Password for "Mail" and "Other (QR App)".
Copy the 16-character code.
In the app, enter:
Email: Your Gmail address.
Password/Code: The Google App Password.



Troubleshooting



Issue
Solution



QR not scanning
Ensure proper lighting and camera clarity.


Custom message not appearing
Check message setup in Settings.


Batch file errors
Verify CSV format matches the template.


Email not sending
Confirm 2FA and App Password setup.


Support

Email: seanwiltonr@gmail.com
Phone: +63-966-987-7706
