import React, { useState, useRef, useCallback, useEffect } from 'react';
import { colors } from '../styles';

interface ImageCropperProps {
  imageSrc: string;
  onConfirm: (croppedDataUrl: string) => void;
  onCancel: () => void;
}

const CROP_SIZE = 240;
const OUTPUT_SIZE = 200;
const MAX_BYTES = 300_000;
const MIN_ZOOM = 1;
const MAX_ZOOM = 4;

export function ImageCropper({ imageSrc, onConfirm, onCancel }: ImageCropperProps) {
  const [zoom, setZoom] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const [imgDims, setImgDims] = useState({ w: 0, h: 0 });
  const [dragging, setDragging] = useState(false);
  const dragStart = useRef({ x: 0, y: 0, ox: 0, oy: 0 });
  const containerRef = useRef<HTMLDivElement>(null);

  // Load image dimensions
  useEffect(() => {
    const img = new Image();
    img.onload = () => {
      setImgDims({ w: img.width, h: img.height });
      setOffset({ x: 0, y: 0 });
      setZoom(1);
    };
    img.src = imageSrc;
  }, [imageSrc]);

  // Compute the scaled image size to fill the crop area at zoom=1
  const getScaledSize = useCallback(() => {
    if (!imgDims.w || !imgDims.h) return { sw: CROP_SIZE, sh: CROP_SIZE };
    const ratio = Math.max(CROP_SIZE / imgDims.w, CROP_SIZE / imgDims.h);
    return { sw: imgDims.w * ratio * zoom, sh: imgDims.h * ratio * zoom };
  }, [imgDims, zoom]);

  const clampOffset = useCallback((ox: number, oy: number) => {
    const { sw, sh } = getScaledSize();
    const maxX = Math.max(0, (sw - CROP_SIZE) / 2);
    const maxY = Math.max(0, (sh - CROP_SIZE) / 2);
    return { x: Math.max(-maxX, Math.min(maxX, ox)), y: Math.max(-maxY, Math.min(maxY, oy)) };
  }, [getScaledSize]);

  // Mouse/touch handlers
  const handlePointerDown = (e: React.PointerEvent) => {
    e.preventDefault();
    setDragging(true);
    dragStart.current = { x: e.clientX, y: e.clientY, ox: offset.x, oy: offset.y };
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragging) return;
    const dx = e.clientX - dragStart.current.x;
    const dy = e.clientY - dragStart.current.y;
    setOffset(clampOffset(dragStart.current.ox + dx, dragStart.current.oy + dy));
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    setDragging(false);
    (e.target as HTMLElement).releasePointerCapture(e.pointerId);
  };

  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const newZoom = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, zoom - e.deltaY * 0.002));
    setZoom(newZoom);
    // Re-clamp offset for new zoom
    const { sw, sh } = (() => {
      if (!imgDims.w || !imgDims.h) return { sw: CROP_SIZE, sh: CROP_SIZE };
      const ratio = Math.max(CROP_SIZE / imgDims.w, CROP_SIZE / imgDims.h);
      return { sw: imgDims.w * ratio * newZoom, sh: imgDims.h * ratio * newZoom };
    })();
    const maxX = Math.max(0, (sw - CROP_SIZE) / 2);
    const maxY = Math.max(0, (sh - CROP_SIZE) / 2);
    setOffset({ x: Math.max(-maxX, Math.min(maxX, offset.x)), y: Math.max(-maxY, Math.min(maxY, offset.y)) });
  };

  const handleConfirm = () => {
    const img = new Image();
    img.onload = () => {
      const baseRatio = Math.max(CROP_SIZE / img.width, CROP_SIZE / img.height);
      const scaledW = img.width * baseRatio * zoom;
      const scaledH = img.height * baseRatio * zoom;

      // Where the image top-left is relative to the crop area center
      const imgLeft = (CROP_SIZE - scaledW) / 2 + offset.x;
      const imgTop = (CROP_SIZE - scaledH) / 2 + offset.y;

      // Source rectangle in the original image coordinates
      const sx = (-imgLeft) / (baseRatio * zoom);
      const sy = (-imgTop) / (baseRatio * zoom);
      const sSize = CROP_SIZE / (baseRatio * zoom);

      const canvas = document.createElement('canvas');
      canvas.width = OUTPUT_SIZE;
      canvas.height = OUTPUT_SIZE;
      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, sx, sy, sSize, sSize, 0, 0, OUTPUT_SIZE, OUTPUT_SIZE);

      let quality = 0.85;
      let dataUrl = canvas.toDataURL('image/jpeg', quality);
      while (dataUrl.length > MAX_BYTES && quality > 0.2) {
        quality -= 0.1;
        dataUrl = canvas.toDataURL('image/jpeg', quality);
      }
      onConfirm(dataUrl);
    };
    img.src = imageSrc;
  };

  const { sw, sh } = getScaledSize();

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,.6)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200,
    }} onClick={onCancel}>
      <div style={{
        background: '#fff', borderRadius: 12, padding: 24, maxWidth: 360, width: '90%',
        boxShadow: '0 8px 30px rgba(0,0,0,.25)',
      }} onClick={e => e.stopPropagation()}>
        <h3 style={{ margin: '0 0 12px', fontSize: 16, fontWeight: 700 }}>Crop Photo</h3>
        <p style={{ fontSize: 12, color: colors.textSec, margin: '0 0 12px' }}>
          Drag to reposition. Scroll or use slider to zoom.
        </p>

        {/* Crop area */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 14 }}>
          <div
            ref={containerRef}
            style={{
              width: CROP_SIZE, height: CROP_SIZE, borderRadius: '50%',
              overflow: 'hidden', position: 'relative', cursor: dragging ? 'grabbing' : 'grab',
              border: `3px solid ${colors.primary}`, background: '#000',
            }}
            onPointerDown={handlePointerDown}
            onPointerMove={handlePointerMove}
            onPointerUp={handlePointerUp}
            onWheel={handleWheel}
          >
            <img
              src={imageSrc}
              alt="Crop preview"
              draggable={false}
              style={{
                position: 'absolute',
                width: sw, height: sh,
                left: (CROP_SIZE - sw) / 2 + offset.x,
                top: (CROP_SIZE - sh) / 2 + offset.y,
                pointerEvents: 'none', userSelect: 'none',
              }}
            />
          </div>
        </div>

        {/* Zoom slider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
          <span style={{ fontSize: 12, color: colors.textSec }}>−</span>
          <input
            type="range" min={MIN_ZOOM} max={MAX_ZOOM} step={0.05} value={zoom}
            onChange={e => {
              const newZ = parseFloat(e.target.value);
              setZoom(newZ);
              // Re-clamp
              const ratio = Math.max(CROP_SIZE / imgDims.w, CROP_SIZE / imgDims.h);
              const nw = imgDims.w * ratio * newZ, nh = imgDims.h * ratio * newZ;
              const maxX = Math.max(0, (nw - CROP_SIZE) / 2);
              const maxY = Math.max(0, (nh - CROP_SIZE) / 2);
              setOffset(prev => ({ x: Math.max(-maxX, Math.min(maxX, prev.x)), y: Math.max(-maxY, Math.min(maxY, prev.y)) }));
            }}
            style={{ flex: 1 }}
          />
          <span style={{ fontSize: 12, color: colors.textSec }}>+</span>
        </div>

        {/* Actions */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <button onClick={onCancel} style={{
            padding: '8px 16px', borderRadius: 6, border: `1px solid ${colors.border}`,
            background: colors.hover, color: colors.text, fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>Cancel</button>
          <button onClick={handleConfirm} style={{
            padding: '8px 16px', borderRadius: 6, border: 'none',
            background: colors.primary, color: '#fff', fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>Confirm</button>
        </div>
      </div>
    </div>
  );
}

