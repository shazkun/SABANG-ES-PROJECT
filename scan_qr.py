import cv2
from pyzbar.pyzbar import decode
import json
import time
import tkinter as tk
from tkinter import ttk


def get_available_cameras(max_index=10):
    """Detect available camera indices."""
    available_cameras = []
    for i in range(max_index):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            available_cameras.append(i)
            cap.release()
    return available_cameras


def on_camera_select(event):
    """Callback for dropdown selection."""
    global current_camera_index, camera_needs_update
    selected = int(camera_var.get())
    if selected in available_cameras and selected != current_camera_index:
        current_camera_index = selected
        camera_needs_update = True


def create_dropdown():
    """Create tkinter window with camera dropdown."""
    root = tk.Tk()
    root.title("Camera Selection")
    root.geometry("200x100")

    global camera_var
    camera_var = tk.StringVar(root)
    camera_var.set(str(current_camera_index))  # Default to first camera

    label = tk.Label(root, text="Select Camera:")
    label.pack(pady=10)

    dropdown = ttk.OptionMenu(
        root,
        camera_var,
        str(current_camera_index),
        *[str(i) for i in available_cameras],
        command=on_camera_select,
    )
    dropdown.pack(pady=10)

    return root


def main():
    global cap, current_camera_index, camera_needs_update, available_cameras

    # Detect available cameras
    available_cameras = get_available_cameras()
    if not available_cameras:
        print(json.dumps({"error": "No cameras available"}))
        return
    print(json.dumps({"info": f"Available camera indices: {available_cameras}"}))

    # Initialize video capture with the first available camera
    current_camera_index = available_cameras[0]
    cap = cv2.VideoCapture(current_camera_index)
    camera_needs_update = False

    if not cap.isOpened():
        print(json.dumps({"error": f"Failed to open camera {current_camera_index}"}))
        return

    # Create tkinter dropdown
    root = create_dropdown()

    last_data = None
    last_time = 0
    cooldown_time = 20  # Cooldown in seconds

    window_name = "Continuous QR Scanner - Press Q to quit"
    cv2.namedWindow(window_name)

    while True:
        # Update tkinter events
        root.update()

        # Check if camera needs to be updated
        if camera_needs_update:
            cap.release()
            cap = cv2.VideoCapture(current_camera_index)
            if not cap.isOpened():
                print(
                    json.dumps(
                        {"error": f"Failed to open camera {current_camera_index}"}
                    )
                )
                cap = cv2.VideoCapture(available_cameras[0])  # Fallback to first camera
                current_camera_index = available_cameras[0]
                camera_var.set(str(current_camera_index))
            camera_needs_update = False

        ret, frame = cap.read()
        if not ret:
            print(
                json.dumps(
                    {
                        "error": f"Failed to read frame from camera {current_camera_index}"
                    }
                )
            )
            time.sleep(0.1)  # Prevent CPU overload
            continue

        # Decode QR codes in the frame
        barcodes = decode(frame)

        current_time = time.time()
        for barcode in barcodes:
            qr_data = barcode.data.decode("utf-8")

            # Check if enough time has passed since the last detected QR code
            if qr_data != last_data or current_time - last_time >= cooldown_time:
                last_data = qr_data
                last_time = current_time
                print(json.dumps({"result": qr_data}), flush=True)
            else:
                # Display cooldown timer
                remaining_time = cooldown_time - (current_time - last_time)
                if remaining_time > 0:
                    timer_text = f"Cooldown: {remaining_time:.1f}s"
                    cv2.putText(
                        frame,
                        timer_text,
                        (frame.shape[1] - 150, 30),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (0, 0, 255),
                        2,
                    )

        # Display the frame
        cv2.imshow(window_name, frame)

        # Check for 'q' key to quit
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()
    root.destroy()


if __name__ == "__main__":
    main()
