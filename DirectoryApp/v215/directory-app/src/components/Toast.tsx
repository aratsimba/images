import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import { colors } from '../styles';

export type ToastType = 'success' | 'error' | 'info';

interface Toast {
  id: string;
  message: string;
  type: ToastType;
}

interface ToastContextValue {
  addToast: (message: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextValue>({ addToast: () => {} });
export const useToast = () => useContext(ToastContext);

let _nextId = 0;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const timers = useRef<Record<string, number>>({});

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
    delete timers.current[id];
  }, []);

  const addToast = useCallback((message: string, type: ToastType = 'success') => {
    const id = `toast-${++_nextId}`;
    setToasts(prev => [...prev, { id, message, type }]);
    if (type !== 'error') {
      timers.current[id] = window.setTimeout(() => removeToast(id), 4000);
    }
  }, [removeToast]);

  // Cleanup timers on unmount
  useEffect(() => {
    return () => { Object.values(timers.current).forEach(t => clearTimeout(t)); };
  }, []);

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      {toasts.length > 0 && (
        <div style={{
          position: 'fixed', top: 70, right: 20, zIndex: 200,
          display: 'flex', flexDirection: 'column', gap: 8, maxWidth: 380,
          pointerEvents: 'none',
        }}>
          {toasts.map(t => (
            <ToastItem key={t.id} toast={t} onDismiss={() => {
              if (timers.current[t.id]) clearTimeout(timers.current[t.id]);
              removeToast(t.id);
            }} />
          ))}
        </div>
      )}
    </ToastContext.Provider>
  );
}

function ToastItem({ toast, onDismiss }: { toast: Toast; onDismiss: () => void }) {
  const [visible, setVisible] = useState(false);
  useEffect(() => { requestAnimationFrame(() => setVisible(true)); }, []);

  const bgColor = toast.type === 'error' ? '#fce8e6' : toast.type === 'info' ? '#e8f0fe' : '#e6f4ea';
  const borderColor = toast.type === 'error' ? colors.danger : toast.type === 'info' ? colors.primary : '#1b7a15';
  const textColor = toast.type === 'error' ? colors.danger : toast.type === 'info' ? colors.primary : '#1b7a15';

  return (
    <div style={{
      pointerEvents: 'auto',
      background: bgColor, borderLeft: `4px solid ${borderColor}`,
      borderRadius: 8, padding: '10px 14px', boxShadow: '0 4px 16px rgba(0,0,0,.15)',
      display: 'flex', alignItems: 'flex-start', gap: 10,
      opacity: visible ? 1 : 0, transform: visible ? 'translateX(0)' : 'translateX(40px)',
      transition: 'opacity .25s ease, transform .25s ease',
    }}>
      <div style={{ flex: 1, fontSize: 13, lineHeight: 1.45, color: textColor, fontWeight: 500 }}>
        {toast.message}
      </div>
      <button onClick={onDismiss} style={{
        border: 'none', background: 'none', cursor: 'pointer', fontSize: 16,
        color: textColor, opacity: 0.6, padding: 0, lineHeight: 1, flexShrink: 0, marginTop: 1,
      }} title="Dismiss">×</button>
    </div>
  );
}

