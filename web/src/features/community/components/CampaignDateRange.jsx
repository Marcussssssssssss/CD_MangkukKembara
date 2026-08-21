import { useState } from 'react';

const parseDate = (value) => {
  const date = new Date(/^\d{4}-\d{2}-\d{2}$/.test(value || '') ? `${value}T00:00:00` : value);
  date.setHours(0, 0, 0, 0);
  return date;
};

const formatDate = (value) => new Intl.DateTimeFormat('en-GB', {
  day: '2-digit', month: '2-digit', year: 'numeric',
}).format(value);

const monthKey = (date) => `${date.getFullYear()}-${date.getMonth()}`;
const nextDateValue = (value) => {
  const date = parseDate(value);
  date.setDate(date.getDate() + 1);
  const pad = number => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
};

function CalendarMonth({ month, rangeStart, rangeEnd, onSelect, minimumDate }) {
  const year = month.getFullYear();
  const monthIndex = month.getMonth();
  const firstWeekday = new Date(year, monthIndex, 1).getDay();
  const daysInMonth = new Date(year, monthIndex + 1, 0).getDate();
  const cells = [
    ...Array.from({ length: firstWeekday }, () => null),
    ...Array.from({ length: daysInMonth }, (_, index) => index + 1),
  ];

  return (
    <div className="min-w-0 flex-1 rounded-xl border border-surface-200 bg-white p-4 shadow-sm">
      <h5 className="text-center text-sm font-bold text-surface-900">
        {new Intl.DateTimeFormat('en-GB', { month: 'long', year: 'numeric' }).format(month)}
      </h5>
      <div className="mt-4 grid grid-cols-7 text-center text-[10px] font-bold uppercase tracking-wide text-surface-400">
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => <span key={day}>{day}</span>)}
      </div>
      <div className="mt-2 grid grid-cols-7 gap-y-1 text-center text-xs">
        {cells.map((day, index) => {
          if (!day) return <span key={`empty-${index}`} className="h-8" />;
          const date = new Date(year, monthIndex, day);
          const isStart = date.getTime() === rangeStart.getTime();
          const isEnd = date.getTime() === rangeEnd.getTime();
          const isInRange = date >= rangeStart && date <= rangeEnd;
          const isDisabled = minimumDate && date < minimumDate;
          const dayClass = `flex h-8 items-center justify-center font-medium ${isStart || isEnd ? 'rounded-full bg-primary-600 text-white shadow-sm' : isInRange ? 'bg-primary-50 text-primary-700' : 'text-surface-500'}`;
          if (onSelect) return (
            <button key={day} type="button" disabled={isDisabled} onClick={() => onSelect(date)} className={`${dayClass} hover:ring-2 hover:ring-primary-300 disabled:cursor-not-allowed disabled:opacity-30`}>
              {day}
            </button>
          );
          return (
            <span
              key={day}
              aria-label={`${formatDate(date)}${isStart ? ', submission start' : ''}${isEnd ? ', submission end' : ''}`}
              className={`flex h-8 items-center justify-center font-medium ${isStart || isEnd ? 'rounded-full bg-primary-600 text-white shadow-sm' : isInRange ? 'bg-primary-50 text-primary-700' : 'text-surface-500'}`}
            >
              {day}
            </span>
          );
        })}
      </div>
    </div>
  );
}

function DateSelectionCalendar({ label, value, onChange, minimumDate }) {
  const selectedDate = parseDate(value);
  const minimum = minimumDate ? parseDate(minimumDate) : null;
  const [viewMonth, setViewMonth] = useState(() => new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1));
  const toInputDate = (date) => {
    const pad = number => String(number).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
  };
  const goToday = () => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    setViewMonth(new Date(today.getFullYear(), today.getMonth(), 1));
    if (!minimum || today >= minimum) onChange(toInputDate(today));
  };
  return (
    <div className="min-w-0 flex-1 rounded-xl border border-surface-200 bg-surface-50 p-4">
      <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
        <div><h4 className="text-sm font-bold text-surface-900">{label}</h4><p className="text-xs text-primary-600">Selected: {formatDate(selectedDate)}</p></div>
        <div className="flex gap-1">
          <button type="button" onClick={() => setViewMonth(current => new Date(current.getFullYear(), current.getMonth() - 1, 1))} className="rounded border border-surface-200 bg-white px-2 py-1 text-xs font-medium">← Previous</button>
          <button type="button" onClick={goToday} className="rounded border border-surface-200 bg-white px-2 py-1 text-xs font-medium">Today</button>
          <button type="button" onClick={() => setViewMonth(current => new Date(current.getFullYear(), current.getMonth() + 1, 1))} className="rounded border border-surface-200 bg-white px-2 py-1 text-xs font-medium">Next →</button>
        </div>
      </div>
      <CalendarMonth month={viewMonth} rangeStart={selectedDate} rangeEnd={selectedDate} onSelect={date => onChange(toInputDate(date))} minimumDate={minimum} />
    </div>
  );
}

export default function CampaignDateRange({ startAt, endAt, title = 'Submission Period', onStartChange, onEndChange, minimumDate }) {
  const rangeStart = parseDate(startAt);
  const rangeEnd = parseDate(endAt);
  const editable = Boolean(onStartChange || onEndChange);
  if (!startAt || !endAt || Number.isNaN(rangeStart.getTime()) || Number.isNaN(rangeEnd.getTime())) return null;

  if (editable) return (
    <div>
      {title && <h4 className="mb-3 text-xs font-bold uppercase tracking-wider text-surface-500">{title}</h4>}
      <div className="flex flex-col gap-4 lg:flex-row">
        {onStartChange && <DateSelectionCalendar label="Submission Start Date" value={startAt} onChange={onStartChange} minimumDate={minimumDate} />}
        {onEndChange && <DateSelectionCalendar label="Submission End Date" value={endAt} onChange={onEndChange} minimumDate={onStartChange ? nextDateValue(startAt) : minimumDate} />}
      </div>
    </div>
  );

  if (rangeEnd < rangeStart) return null;
  const sameMonth = monthKey(rangeStart) === monthKey(rangeEnd);

  return (
    <div className="rounded-xl border border-surface-200 bg-surface-50 p-4 sm:p-5">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-surface-500">{title}</h4>
          <p className="mt-1 text-sm font-semibold text-surface-900">{formatDate(rangeStart)} <span className="mx-1 text-surface-400">→</span> {formatDate(rangeEnd)}</p>
        </div>
        <div className="flex items-center gap-3 text-xs text-surface-600">
          <span className="flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full bg-primary-600" /> Start / End</span>
          <span className="flex items-center gap-1.5"><span className="h-2.5 w-2.5 bg-primary-50 ring-1 ring-primary-100" /> Selected range</span>
        </div>
      </div>
      <div className="flex flex-col gap-4 lg:flex-row">
        <CalendarMonth month={rangeStart} rangeStart={rangeStart} rangeEnd={rangeEnd} />
        {!sameMonth && <><div className="hidden items-center text-surface-300 lg:flex">•••</div><CalendarMonth month={rangeEnd} rangeStart={rangeStart} rangeEnd={rangeEnd} /></>}
      </div>
    </div>
  );
}
