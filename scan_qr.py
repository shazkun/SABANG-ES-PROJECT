import cv2
from pyzbar.pyzbar import decode
import json
import time
import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageTk


def get_available_cameras(max_index=10):
    """Detect available camera indices."""
    available_cameras = []
    for i in range(max_index):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            available_cameras.append(i)
            cap.release()
    return available_cameras


class QRScannerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("QR Scanner - Camera")
        self.root.geometry("800x700")
        self.root.configure(bg="#f5f5f5")

        style = ttk.Style()
        style.theme_use("clam")
        style.configure("TLabel", background="#f5f5f5", font=("Segoe UI", 11))
        style.configure("TButton", font=("Segoe UI", 10))
        style.configure("TMenubutton", font=("Segoe UI", 10))

        # Camera selection
        self.available_cameras = get_available_cameras()
        if not self.available_cameras:
            print(json.dumps({"error": "No cameras available"}))
            self.root.destroy()
            return

        self.current_camera_index = self.available_cameras[0]
        self.cap = cv2.VideoCapture(self.current_camera_index)

        self.camera_var = tk.StringVar(value=str(self.current_camera_index))
        ttk.Label(root, text="Select Camera:").pack(pady=5)
        self.camera_dropdown = ttk.OptionMenu(
            root,
            self.camera_var,
            str(self.current_camera_index),
            *[str(i) for i in self.available_cameras],
            command=self.on_camera_select,
        )
        self.camera_dropdown.pack(pady=5)

        # Video display area
        self.video_label = ttk.Label(root)
        self.video_label.pack(pady=10)

        # Info label
        self.info_label = ttk.Label(root, text="Scan a QR code...", foreground="#333")
        self.info_label.pack(pady=5)

        # Cooldown system
        self.last_data = None
        self.last_time = 0
        self.cooldown_time = 20  # seconds

        self.update_frame()

        self.root.protocol("WM_DELETE_WINDOW", self.on_close)

    def on_camera_select(self, event):
        selected = int(self.camera_var.get())
        if selected in self.available_cameras and selected != self.current_camera_index:
            self.cap.release()
            self.current_camera_index = selected
            self.cap = cv2.VideoCapture(self.current_camera_index)

    def update_frame(self):
        ret, frame = self.cap.read()
        if not ret:
            self.info_label.config(text=f"Failed to read from camera {self.current_camera_index}")
            self.root.after(100, self.update_frame)
            return

        barcodes = decode(frame)
        current_time = time.time()

        for barcode in barcodes:
            qr_data = barcode.data.decode("utf-8")
            if qr_data != self.last_data or current_time - self.last_time >= self.cooldown_time:
                self.last_data = qr_data
                self.last_time = current_time
                print(json.dumps({"result": qr_data}), flush=True)
                self.info_label.config(text=f"QR Code: {qr_data}", foreground="green")
            else:
                remaining_time = self.cooldown_time - (current_time - self.last_time)
                if remaining_time > 0:
                    self.info_label.config(text=f"Cooldown: {remaining_time:.1f}s", foreground="red")

        # Convert frame for Tkinter display
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img = Image.fromarray(frame_rgb)
        img = img.resize((640, 480))
        imgtk = ImageTk.PhotoImage(image=img)
        self.video_label.imgtk = imgtk
        self.video_label.config(image=imgtk)

        self.root.after(10, self.update_frame)

    def on_close(self):
        if self.cap.isOpened():
            self.cap.release()
        self.root.destroy()


if __name__ == "__main__":
    root = tk.Tk()
    app = QRScannerApp(root)
    root.mainloop()
