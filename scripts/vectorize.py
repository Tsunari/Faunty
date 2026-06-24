import cv2
import numpy as np
import os

def find_corners(points, k=5, threshold_cos=0.94):
    N = len(points)
    is_corner = np.zeros(N, dtype=bool)
    for i in range(N):
        p0 = points[(i - k) % N]
        p1 = points[i]
        p2 = points[(i + k) % N]
        
        v1 = p1 - p0
        v2 = p2 - p1
        
        len1 = np.linalg.norm(v1)
        len2 = np.linalg.norm(v2)
        
        if len1 < 1e-5 or len2 < 1e-5:
            continue
            
        cos_theta = np.dot(v1, v2) / (len1 * len2)
        if cos_theta < threshold_cos:
            is_corner[i] = True
            
    return is_corner

def smooth_contour_feature_preserving(points, window_size=15, k=5, threshold_cos=0.94):
    N = len(points)
    if N < window_size:
        return points
        
    is_corner = find_corners(points, k=k, threshold_cos=threshold_cos)
    
    # 1. Moving average of coordinates
    temp_smooth = np.zeros_like(points, dtype=np.float32)
    for i in range(N):
        window = []
        for w in range(-window_size//2, window_size//2 + 1):
            window.append(points[(i + w) % N])
        temp_smooth[i] = np.mean(window, axis=0)
        
    # 2. Distance to nearest corner index
    corner_indices = np.where(is_corner)[0]
    if len(corner_indices) == 0:
        return temp_smooth
        
    dist_to_corner = np.zeros(N, dtype=int)
    for i in range(N):
        diffs = np.abs(corner_indices - i)
        circular_diffs = np.minimum(diffs, N - diffs)
        dist_to_corner[i] = np.min(circular_diffs)
        
    # 3. Blend based on distance (0 = corner, 1 = slight smooth, 3+ = full smooth)
    smoothed = np.zeros_like(points, dtype=np.float32)
    for i in range(N):
        d = dist_to_corner[i]
        if d == 0:
            smoothed[i] = points[i]
        elif d == 1:
            smoothed[i] = 0.7 * points[i] + 0.3 * temp_smooth[i]
        elif d == 2:
            smoothed[i] = 0.4 * points[i] + 0.6 * temp_smooth[i]
        else:
            smoothed[i] = temp_smooth[i]
            
    return smoothed

def main():
    img_path = 'assets/Logo_old.png'
    if not os.path.exists(img_path):
        print("Error: assets/Logo_old.png not found.")
        return

    # Load image with alpha channel
    img = cv2.imread(img_path, cv2.IMREAD_UNCHANGED)
    h, w, c = img.shape
    print(f"Loaded image: {w}x{h} with {c} channels")

    # Extract mask from alpha channel
    if c == 4:
        mask = img[:, :, 3]
    else:
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        _, mask = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)

    # Find contours
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    
    # Filter out very small contours to prevent noise
    contours = [c for c in contours if cv2.contourArea(c) > 50]
    print(f"Found {len(contours)} contours.")

    # Smooth each contour using our feature-preserving filter
    smoothed_contours = []
    for c in contours:
        pts = c[:, 0]
        # Clean duplicates or close points first
        cleaned_pts = [pts[0]]
        for pt in pts[1:]:
            if np.linalg.norm(pt - cleaned_pts[-1]) > 0.5:
                cleaned_pts.append(pt)
        cleaned_pts = np.array(cleaned_pts)
        
        # Apply smoothing with larger window size to wash out wide pixel steps
        smoothed_pts = smooth_contour_feature_preserving(cleaned_pts, window_size=55, k=22, threshold_cos=0.92)
        smoothed_contours.append(smoothed_pts)

    # Calculate bounding box of all selected contours
    all_points = np.vstack(smoothed_contours)
    min_x, min_y = np.min(all_points, axis=0)
    max_x, max_y = np.max(all_points, axis=0)
    
    src_w = max_x - min_x
    src_h = max_y - min_y
    print(f"Source size: {src_w}x{src_h}")

    # Scale to fit inside 512x512 with minimal safe padding (20px)
    # Target size: width max 472, height max 452
    scale_w = 472.0 / src_w
    scale_h = 452.0 / src_h
    scale = min(scale_w, scale_h)

    # Calculate center offsets
    target_center_x = 256.0
    target_center_y = 256.0
    src_center_x = min_x + src_w / 2.0
    src_center_y = min_y + src_h / 2.0

    # Build SVG path data
    path_d = ""
    for contour in smoothed_contours:
        for i, pt in enumerate(contour):
            # Translate and scale point
            tx = target_center_x + (pt[0] - src_center_x) * scale
            ty = target_center_y + (pt[1] - src_center_y) * scale
            
            tx_str = f"{tx:.2f}"
            ty_str = f"{ty:.2f}"
            
            if i == 0:
                path_d += f"M {tx_str},{ty_str} "
            else:
                path_d += f"L {tx_str},{ty_str} "
        path_d += "Z "

    # SVG template
    svg_template = f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <defs>
    <!-- Background Gradient for PWA and Launcher Cards -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#021c17" />
      <stop offset="100%" stop-color="#010d0a" />
    </linearGradient>

    <!-- Vibrant Premium Neon Gradient for Dark Theme / Inverse Logo -->
    <linearGradient id="mosqueGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#10B981" />
      <stop offset="100%" stop-color="#00B4D8" />
    </linearGradient>

    <!-- Deep Forest Green/Charcoal Gradient for Light Theme Logo -->
    <linearGradient id="mosqueGradLight" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#047857" />
      <stop offset="100%" stop-color="#0077b6" />
    </linearGradient>
  </defs>

  <!-- Base Squircle Card (for PWA and native launcher icons) -->
  <rect id="bgCard" x="8" y="8" width="496" height="496" rx="124" fill="url(#bgGrad)" />

  <!-- High-Fidelity Vector Mosque Silhouette -->
  <path id="mosquePath" d="{path_d.strip()}" fill="url(#mosqueGrad)" fill-rule="evenodd" />
</svg>"""

    with open('assets/logo.svg', 'w', encoding='utf-8') as f:
        f.write(svg_template)
    
    print("OK: Vectorized and smoothed old logo successfully to assets/logo.svg!")

if __name__ == '__main__':
    main()
