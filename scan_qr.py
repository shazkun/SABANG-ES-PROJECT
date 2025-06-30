# scan_qr.py
import cv2
from pyzbar.pyzbar import decode
import json
import time

def main():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print(json.dumps({"error": "Camera not available"}))
        return

    last_data = None

    while True:
        ret, frame = cap.read()
        if not ret:
            continue

        # Decode QR codes in the frame
        barcodes = decode(frame)

        for barcode in barcodes:
            qr_data = barcode.data.decode('utf-8')

            # Avoid repeating the same code
            if qr_data != last_data:
                last_data = qr_data
                print(json.dumps({"result": qr_data}), flush=True)

        cv2.imshow('Continuous QR Scanner - Press Q to quit', frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    main()
