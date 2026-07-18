import React, { useRef, useState } from 'react';
import { colors } from '../styles';
import { ImageCropper } from './ImageCropper';

interface ProfileImageProps {
  imageUrl: string | null;
  size?: number;
  fallback: string; // emoji fallback like 👤 or 🏢 or 🏠
  editable?: boolean;
  onImageChange?: (dataUrl: string | null) => void;
}

function loadFileAsDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsDataURL(file);
  });
}

export function ProfileImage({ imageUrl, size = 40, fallback, editable = false, onImageChange }: ProfileImageProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [cropSrc, setCropSrc] = useState<string | null>(null);

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !onImageChange) return;
    e.target.value = '';
    try {
      const dataUrl = await loadFileAsDataUrl(file);
      setCropSrc(dataUrl);
    } catch {
      // silently fail
    }
  };

  const containerStyle: React.CSSProperties = {
    width: size,
    height: size,
    borderRadius: '50%',
    overflow: 'hidden',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: colors.hover,
    border: `2px solid ${colors.border}`,
    flexShrink: 0,
    position: 'relative',
    cursor: editable ? 'pointer' : 'default',
  };

  const imgStyle: React.CSSProperties = {
    width: '100%',
    height: '100%',
    objectFit: 'cover',
  };

  return (
    <>
      <div
        style={containerStyle}
        onClick={editable ? () => inputRef.current?.click() : undefined}
        title={editable ? 'Click to change photo' : undefined}
      >
        {imageUrl ? (
          <img src={imageUrl} alt="Profile" style={imgStyle} />
        ) : (
          <span style={{ fontSize: size * 0.5, lineHeight: 1 }}>{fallback}</span>
        )}
        {editable && (
          <>
            <div style={{
              position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              opacity: 0, transition: 'opacity .15s',
            }}
              onMouseEnter={e => (e.currentTarget.style.opacity = '1')}
              onMouseLeave={e => (e.currentTarget.style.opacity = '0')}
            >
              <span style={{ color: '#fff', fontSize: size * 0.22, fontWeight: 700 }}>📷</span>
            </div>
            <input ref={inputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFile} />
          </>
        )}
        {editable && imageUrl && (
          <button
            onClick={e => { e.stopPropagation(); onImageChange?.(null); }}
            style={{
              position: 'absolute', top: -2, right: -2, width: 18, height: 18,
              borderRadius: '50%', background: colors.danger, color: '#fff',
              border: 'none', cursor: 'pointer', fontSize: 11, lineHeight: 1,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}
            title="Remove photo"
          >×</button>
        )}
      </div>
      {cropSrc && (
        <ImageCropper
          imageSrc={cropSrc}
          onConfirm={(cropped) => { onImageChange?.(cropped); setCropSrc(null); }}
          onCancel={() => setCropSrc(null)}
        />
      )}
    </>
  );
}

