import React, { useState, useEffect, useCallback } from 'react';
import { putPrivateItem, getPrivateItem, PageStorageError } from '@amzn/quick-pages-runtime-lib';
import { S, colors } from '../styles';

const PREFS_TABLE = 'user-preferences';
const PREFS_KEY = 'detail-collapsed-sections';

// Global cache to avoid re-fetching on every mount
let cachedCollapsed: Set<string> | null = null;
let loadPromise: Promise<Set<string>> | null = null;

async function loadCollapsedSections(): Promise<Set<string>> {
  if (cachedCollapsed) return cachedCollapsed;
  if (loadPromise) return loadPromise;
  loadPromise = (async () => {
    try {
      const r = await getPrivateItem({ tableName: PREFS_TABLE, key: PREFS_KEY });
      if (r) {
        cachedCollapsed = new Set(JSON.parse(r.item.value));
      } else {
        cachedCollapsed = new Set();
      }
    } catch {
      cachedCollapsed = new Set();
    }
    return cachedCollapsed!;
  })();
  return loadPromise;
}

async function saveCollapsedSections(sections: Set<string>) {
  cachedCollapsed = sections;
  try {
    await putPrivateItem({ tableName: PREFS_TABLE, key: PREFS_KEY, value: JSON.stringify([...sections]) });
  } catch {
    // silently fail
  }
}

export function useCollapsedSections() {
  const [collapsed, setCollapsed] = useState<Set<string>>(cachedCollapsed || new Set());
  const [loaded, setLoaded] = useState(!!cachedCollapsed);

  useEffect(() => {
    if (!cachedCollapsed) {
      loadCollapsedSections().then(s => { setCollapsed(new Set(s)); setLoaded(true); });
    } else {
      setLoaded(true);
    }
  }, []);

  const toggle = useCallback((sectionId: string) => {
    setCollapsed(prev => {
      const next = new Set(prev);
      if (next.has(sectionId)) next.delete(sectionId);
      else next.add(sectionId);
      saveCollapsedSections(next);
      return next;
    });
  }, []);

  return { collapsed, toggle, loaded };
}

interface CollapsibleSectionProps {
  id: string;
  title: string;
  collapsed: boolean;
  onToggle: () => void;
  children: React.ReactNode;
}

export function CollapsibleSection({ id, title, collapsed, onToggle, children }: CollapsibleSectionProps) {
  return (
    <div>
      <div
        style={{ ...S.section, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'space-between', userSelect: 'none' }}
        onClick={onToggle}
      >
        <span>{title}</span>
        <span style={{ fontSize: 12, color: colors.textSec, fontWeight: 400 }}>
          {collapsed ? '▶' : '▼'}
        </span>
      </div>
      {!collapsed && children}
    </div>
  );
}

