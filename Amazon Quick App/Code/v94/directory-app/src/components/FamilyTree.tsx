import React, { useState, useMemo, useCallback } from 'react';
import type { Person } from '../types';
import { colors } from '../styles';
import { getEntryName } from '../utils';

interface FamilyTreeProps {
  person: Person;
  allPersons: Person[];
  images: Record<string, string>;
  onSelectPerson: (id: string) => void;
}

type NodeRole = 'self' | 'spouse' | 'parent' | 'child' | 'sibling' | 'grandparent' | 'grandchild';

interface TreeNode {
  id: string;
  name: string;
  imageUrl: string | null;
  role: NodeRole;
  expandable: boolean; // has further parents or children to show
  expanded: boolean;
}

const NODE_W = 100;
const NODE_H = 72;
const H_GAP = 16;
const V_GAP = 44;

const ROLE_COLORS: Record<NodeRole, { border: string; bg: string }> = {
  self: { border: colors.primary, bg: '#e3f2fd' },
  spouse: { border: '#e91e63', bg: '#fce4ec' },
  parent: { border: '#6a1b9a', bg: '#f3e5f5' },
  child: { border: '#2e7d32', bg: '#e8f5e9' },
  sibling: { border: colors.textSec, bg: '#f5f5f5' },
  grandparent: { border: '#4a148c', bg: '#ede7f6' },
  grandchild: { border: '#1b5e20', bg: '#c8e6c9' },
};

function PersonNode({ node, x, y, onSelect, onToggleExpand }: {
  node: TreeNode; x: number; y: number;
  onSelect: () => void; onToggleExpand: () => void;
}) {
  const { border: borderColor, bg: bgColor } = ROLE_COLORS[node.role];

  return (
    <g>
      <g style={{ cursor: node.role === 'self' ? 'default' : 'pointer' }} onClick={node.role !== 'self' ? onSelect : undefined}>
        <rect x={x} y={y} width={NODE_W} height={NODE_H} rx={8} ry={8}
          fill={bgColor} stroke={borderColor} strokeWidth={node.role === 'self' ? 2.5 : 1.5} />
        {node.imageUrl ? (
          <>
            <defs><clipPath id={`clip-${node.id}-${node.role}`}><circle cx={x + NODE_W / 2} cy={y + 22} r={14} /></clipPath></defs>
            <image href={node.imageUrl} x={x + NODE_W / 2 - 14} y={y + 8} width={28} height={28} clipPath={`url(#clip-${node.id}-${node.role})`} />
          </>
        ) : (
          <text x={x + NODE_W / 2} y={y + 26} textAnchor="middle" fontSize={16}>👤</text>
        )}
        <text x={x + NODE_W / 2} y={y + 50} textAnchor="middle" fontSize={10} fontWeight={node.role === 'self' ? 700 : 500}
          fill={colors.text}>
          {node.name.length > 14 ? node.name.slice(0, 13) + '…' : node.name}
        </text>
        <text x={x + NODE_W / 2} y={y + 63} textAnchor="middle" fontSize={8} fill={borderColor} fontWeight={600}>
          {node.role === 'self' ? '★ SELF' : node.role === 'grandparent' ? 'GRANDPARENT' : node.role === 'grandchild' ? 'GRANDCHILD' : node.role.toUpperCase()}
        </text>
      </g>
      {node.expandable && (
        <g style={{ cursor: 'pointer' }} onClick={e => { e.stopPropagation(); onToggleExpand(); }}>
          <circle
            cx={x + NODE_W / 2}
            cy={node.role === 'child' || node.role === 'grandchild' ? y + NODE_H + 10 : y - 10}
            r={9} fill="#fff" stroke={borderColor} strokeWidth={1.5} />
          <text
            x={x + NODE_W / 2}
            y={(node.role === 'child' || node.role === 'grandchild' ? y + NODE_H + 10 : y - 10) + 4}
            textAnchor="middle" fontSize={12} fontWeight={700} fill={borderColor}>
            {node.expanded ? '−' : '+'}
          </text>
        </g>
      )}
    </g>
  );
}

export function FamilyTree({ person, allPersons, images, onSelectPerson }: FamilyTreeProps) {
  // Track expanded nodes: set of person IDs that have been expanded
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());

  const toggleExpand = useCallback((id: string) => {
    setExpandedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const getParents = useCallback((id: string) => allPersons.filter(p => p.childIds.includes(id)), [allPersons]);
  const getChildren = useCallback((id: string) => {
    const p = allPersons.find(x => x.id === id);
    return p ? allPersons.filter(c => p.childIds.includes(c.id)) : [];
  }, [allPersons]);

  const tree = useMemo(() => {
    // Build rows dynamically based on expansions
    // Structure: ancestor rows (top) ... parent row ... self row ... child row ... descendant rows (bottom)
    type RowItem = { person: Person; role: NodeRole; expandable: boolean; expanded: boolean; parentLinkIds?: string[] };
    type Row = RowItem[];

    const rows: Row[] = [];
    const lines: { fromRow: number; fromIdx: number; toRow: number; toIdx: number; color: string; dashed?: boolean }[] = [];

    // === Build ancestor rows (upward from parents) ===
    const ancestorRows: Row[] = [];

    // Start with direct parents
    const parents = getParents(person.id);
    if (parents.length > 0) {
      const parentRow: Row = parents.map(p => {
        const hasGrandparents = getParents(p.id).length > 0;
        return { person: p, role: 'parent' as NodeRole, expandable: hasGrandparents, expanded: expandedIds.has(p.id) };
      });
      ancestorRows.push(parentRow);

      // Recursively expand upward
      let currentRow = parentRow;
      while (true) {
        const nextRow: Row = [];
        for (const item of currentRow) {
          if (item.expanded) {
            const gps = getParents(item.person.id);
            gps.forEach(gp => {
              const hasMore = getParents(gp.id).length > 0;
              nextRow.push({ person: gp, role: 'grandparent', expandable: hasMore, expanded: expandedIds.has(gp.id), parentLinkIds: [item.person.id] });
            });
          }
        }
        if (nextRow.length === 0) break;
        ancestorRows.push(nextRow);
        currentRow = nextRow;
      }
    }

    // Reverse ancestor rows so oldest generation is at top
    ancestorRows.reverse();

    // === Build self row (self + spouse + siblings) ===
    const spouse = person.spouseId ? allPersons.find(p => p.id === person.spouseId) : null;
    const siblingIds = new Set<string>();
    parents.forEach(p => p.childIds.forEach(cid => { if (cid !== person.id) siblingIds.add(cid); }));
    const siblings = allPersons.filter(p => siblingIds.has(p.id));

    // === Build descendant rows (downward from children) ===
    const descendantRows: Row[] = [];
    const children = getChildren(person.id);
    if (children.length > 0) {
      const childRow: Row = children.map(c => {
        const hasGrandchildren = c.childIds.length > 0;
        return { person: c, role: 'child' as NodeRole, expandable: hasGrandchildren, expanded: expandedIds.has(c.id) };
      });
      descendantRows.push(childRow);

      // Recursively expand downward
      let currentRow = childRow;
      while (true) {
        const nextRow: Row = [];
        for (const item of currentRow) {
          if (item.expanded) {
            const gcs = getChildren(item.person.id);
            gcs.forEach(gc => {
              const hasMore = gc.childIds.length > 0;
              nextRow.push({ person: gc, role: 'grandchild', expandable: hasMore, expanded: expandedIds.has(gc.id), parentLinkIds: [item.person.id] });
            });
          }
        }
        if (nextRow.length === 0) break;
        descendantRows.push(nextRow);
        currentRow = nextRow;
      }
    }

    // === Compute layout ===
    // All rows in order: ancestorRows... selfRow... descendantRows
    const selfRowItems: RowItem[] = [
      { person, role: 'self', expandable: false, expanded: false },
      ...(spouse ? [{ person: spouse, role: 'spouse' as NodeRole, expandable: false, expanded: false }] : []),
      ...siblings.map(s => ({ person: s, role: 'sibling' as NodeRole, expandable: false, expanded: false })),
    ];

    const allRows: Row[] = [...ancestorRows, selfRowItems, ...descendantRows];
    const selfRowIndex = ancestorRows.length;

    // Compute widths
    const rowWidths = allRows.map(r => r.length * NODE_W + (r.length > 0 ? (r.length - 1) * H_GAP : 0));
    const totalWidth = Math.max(...rowWidths, 300);
    const padX = 20;
    const padY = 24;
    const svgWidth = totalWidth + padX * 2;

    // Position nodes
    type PositionedNode = TreeNode & { x: number; y: number; rowIdx: number; colIdx: number };
    const positioned: PositionedNode[] = [];

    allRows.forEach((row, rowIdx) => {
      const rowWidth = rowWidths[rowIdx];
      const startX = padX + (totalWidth - rowWidth) / 2;
      const y = padY + rowIdx * (NODE_H + V_GAP);
      row.forEach((item, colIdx) => {
        const x = startX + colIdx * (NODE_W + H_GAP);
        positioned.push({
          id: item.person.id,
          name: getEntryName(item.person),
          imageUrl: images[item.person.id] || null,
          role: item.role,
          expandable: item.expandable,
          expanded: item.expanded,
          x, y, rowIdx, colIdx,
        });
      });
    });

    // Build connection lines
    const svgLines: { x1: number; y1: number; x2: number; y2: number; color: string; dashed?: boolean }[] = [];

    // Helper to find positioned node by id and role preference
    const findNode = (id: string, preferRole?: NodeRole) => {
      if (preferRole) {
        const n = positioned.find(n => n.id === id && n.role === preferRole);
        if (n) return n;
      }
      return positioned.find(n => n.id === id);
    };

    // Parent row -> self
    if (parents.length > 0) {
      const selfNode = findNode(person.id, 'self');
      if (selfNode) {
        parents.forEach(p => {
          const pNode = findNode(p.id, 'parent');
          if (pNode) {
            svgLines.push({ x1: pNode.x + NODE_W / 2, y1: pNode.y + NODE_H, x2: selfNode.x + NODE_W / 2, y2: selfNode.y, color: '#6a1b9a' });
          }
        });
        // Parents -> siblings
        siblings.forEach(s => {
          const sNode = findNode(s.id, 'sibling');
          if (sNode) {
            parents.forEach(p => {
              const pNode = findNode(p.id, 'parent');
              if (pNode) svgLines.push({ x1: pNode.x + NODE_W / 2, y1: pNode.y + NODE_H, x2: sNode.x + NODE_W / 2, y2: sNode.y, color: '#9e9e9e', dashed: true });
            });
          }
        });
      }
    }

    // Self -> spouse line
    if (spouse) {
      const selfNode = findNode(person.id, 'self');
      const spouseNode = findNode(spouse.id, 'spouse');
      if (selfNode && spouseNode) {
        svgLines.push({ x1: selfNode.x + NODE_W, y1: selfNode.y + NODE_H / 2, x2: spouseNode.x, y2: spouseNode.y + NODE_H / 2, color: '#e91e63' });
      }
    }

    // Self -> children
    if (children.length > 0) {
      const selfNode = findNode(person.id, 'self');
      const spouseNode = spouse ? findNode(spouse.id, 'spouse') : null;
      if (selfNode) {
        children.forEach(c => {
          const cNode = findNode(c.id, 'child');
          if (cNode) {
            svgLines.push({ x1: selfNode.x + NODE_W / 2, y1: selfNode.y + NODE_H, x2: cNode.x + NODE_W / 2, y2: cNode.y, color: '#2e7d32' });
            if (spouseNode) svgLines.push({ x1: spouseNode.x + NODE_W / 2, y1: spouseNode.y + NODE_H, x2: cNode.x + NODE_W / 2, y2: cNode.y, color: '#e91e63', dashed: true });
          }
        });
      }
    }

    // Expanded ancestor lines (grandparents -> parents)
    for (let i = 0; i < ancestorRows.length - 1; i++) {
      const upperRow = ancestorRows[i];
      const lowerRow = ancestorRows[i + 1];
      lowerRow.forEach(lowerItem => {
        const lowerNode = findNode(lowerItem.person.id);
        if (!lowerNode) return;
        // Find which upper items are parents of this lower item
        upperRow.forEach(upperItem => {
          if (upperItem.parentLinkIds?.includes(lowerItem.person.id)) {
            // This upper is a parent of this lower? No — parentLinkIds on upper means upper's parent is...
            // Actually parentLinkIds on the ITEM means "this node's child link target"
          }
        });
      });
    }

    // Better approach for ancestor/descendant links: iterate expanded nodes
    // Ancestor links
    ancestorRows.forEach((row, aIdx) => {
      const actualRowIdx = aIdx; // in allRows
      row.forEach(item => {
        if (item.parentLinkIds) {
          item.parentLinkIds.forEach(childId => {
            const parentNode = positioned.find(n => n.id === item.person.id && n.rowIdx === actualRowIdx);
            const childNode = positioned.find(n => n.id === childId);
            if (parentNode && childNode) {
              svgLines.push({ x1: parentNode.x + NODE_W / 2, y1: parentNode.y + NODE_H, x2: childNode.x + NODE_W / 2, y2: childNode.y, color: '#4a148c', dashed: true });
            }
          });
        }
      });
    });

    // Descendant links
    descendantRows.forEach((row, dIdx) => {
      const actualRowIdx = selfRowIndex + 1 + dIdx;
      row.forEach(item => {
        if (item.parentLinkIds) {
          item.parentLinkIds.forEach(parentId => {
            const childNode = positioned.find(n => n.id === item.person.id && n.rowIdx === actualRowIdx);
            const parentNode = positioned.find(n => n.id === parentId);
            if (parentNode && childNode) {
              svgLines.push({ x1: parentNode.x + NODE_W / 2, y1: parentNode.y + NODE_H, x2: childNode.x + NODE_W / 2, y2: childNode.y, color: '#1b5e20', dashed: true });
            }
          });
        }
      });
    });

    const svgHeight = padY + allRows.length * (NODE_H + V_GAP) - V_GAP + padY;

    return { nodes: positioned, lines: svgLines, svgWidth, svgHeight };
  }, [person, allPersons, images, expandedIds, getParents, getChildren]);

  if (tree.nodes.length <= 1) {
    return <div style={{ fontSize: 13, color: colors.textSec, padding: '12px 0' }}>No family relationships to display.</div>;
  }

  return (
    <div style={{ overflowX: 'auto', marginTop: 8 }}>
      <svg width={tree.svgWidth} height={tree.svgHeight} style={{ display: 'block' }}>
        {tree.lines.map((l, i) => (
          <line key={i} x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2}
            stroke={l.color} strokeWidth={1.5}
            strokeDasharray={l.dashed ? '4,3' : undefined}
            opacity={0.7} />
        ))}
        {tree.nodes.map((n, i) => (
          <PersonNode key={`${n.id}-${n.role}-${i}`} node={n} x={n.x} y={n.y}
            onSelect={() => onSelectPerson(n.id)}
            onToggleExpand={() => toggleExpand(n.id)} />
        ))}
      </svg>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, marginTop: 8, fontSize: 11, color: colors.textSec }}>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#e3f2fd', border: `2px solid ${colors.primary}`, marginRight: 4 }}></span>Self</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#fce4ec', border: '2px solid #e91e63', marginRight: 4 }}></span>Spouse</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#f3e5f5', border: '2px solid #6a1b9a', marginRight: 4 }}></span>Parent</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#e8f5e9', border: '2px solid #2e7d32', marginRight: 4 }}></span>Child</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#f5f5f5', border: `2px solid ${colors.textSec}`, marginRight: 4 }}></span>Sibling</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#ede7f6', border: '2px solid #4a148c', marginRight: 4 }}></span>Grandparent+</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#c8e6c9', border: '2px solid #1b5e20', marginRight: 4 }}></span>Grandchild+</span>
      </div>
      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 6 }}>
        Click <strong>+</strong> on a node to expand further generations. Click a name to navigate.
      </div>
    </div>
  );
}

