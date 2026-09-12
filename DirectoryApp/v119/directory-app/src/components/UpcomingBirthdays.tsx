import React from 'react';
import type { Person } from '../types';
import { colors } from '../styles';
import { ProfileImage } from './ProfileImage';

interface Props {
  persons: Person[];
  images: Record<string, string>;
  onSelect: (id: string) => void;
  daysAhead?: number;
}

function getUpcomingBirthday(birthday: string, daysAhead: number): { daysUntil: number; nextDate: Date } | null {
  if (!birthday) return null;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const birth = new Date(birthday);
  if (isNaN(birth.getTime())) return null;

  const thisYear = new Date(today.getFullYear(), birth.getMonth(), birth.getDate());
  const nextYear = new Date(today.getFullYear() + 1, birth.getMonth(), birth.getDate());

  let nextDate = thisYear;
  if (thisYear < today) nextDate = nextYear;

  const diff = Math.round((nextDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  if (diff > daysAhead) return null;
  return { daysUntil: diff, nextDate };
}

export function UpcomingBirthdays({ persons, images, onSelect, daysAhead = 30 }: Props) {
  const upcoming = persons
    .filter(p => (p.status || 'active') === 'active' && p.birthday)
    .map(p => {
      const info = getUpcomingBirthday(p.birthday, daysAhead);
      return info ? { person: p, ...info } : null;
    })
    .filter(Boolean)
    .sort((a, b) => a!.daysUntil - b!.daysUntil) as { person: Person; daysUntil: number; nextDate: Date }[];

  if (upcoming.length === 0) return null;

  return (
    <div style={{
      background: colors.card, borderRadius: 10, padding: 16, marginBottom: 16,
      border: `1px solid ${colors.border}`, boxShadow: '0 1px 3px rgba(0,0,0,.08)',
    }}>
      <h3 style={{ margin: '0 0 12px', fontSize: 15, color: colors.primary }}>🎂 Upcoming Birthdays (next {daysAhead} days)</h3>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10 }}>
        {upcoming.slice(0, 8).map(({ person, daysUntil, nextDate }) => (
          <div key={person.id} onClick={() => onSelect(person.id)} style={{
            display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px',
            borderRadius: 8, background: daysUntil === 0 ? '#fff8e1' : colors.accent,
            border: `1px solid ${daysUntil === 0 ? '#ffe082' : colors.border}`,
            cursor: 'pointer', fontSize: 13, transition: 'box-shadow .15s',
          }}>
            <ProfileImage imageUrl={images[person.id] || null} size={28} fallback="👤" />
            <div>
              <div style={{ fontWeight: 600 }}>{person.firstName} {person.lastName}</div>
              <div style={{ color: colors.textSec, fontSize: 11 }}>
                {daysUntil === 0 ? '🎉 Today!' : daysUntil === 1 ? 'Tomorrow' : `in ${daysUntil} days`}
                {' · '}{nextDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

