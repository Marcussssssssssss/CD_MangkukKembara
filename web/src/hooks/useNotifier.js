import { useCallback, useEffect, useRef, useState } from 'react';

const SUCCESS_DURATION_MS = 5000;

export function useNotifier() {
  const [notifications, setNotifications] = useState([]);
  const nextId = useRef(1);
  const timers = useRef(new Map());

  const dismiss = useCallback((id) => {
    const timer = timers.current.get(id);
    if (timer) {
      window.clearTimeout(timer);
      timers.current.delete(id);
    }

    setNotifications((current) => current.filter((notification) => notification.id !== id));
  }, []);

  const notify = useCallback((message, type = 'success') => {
    const id = nextId.current;
    nextId.current += 1;

    setNotifications((current) => [
      ...current.slice(-2),
      { id, message, type },
    ]);

    // Success messages disappear after users have had time to read them.
    // Error messages remain until dismissed so recovery guidance is not lost.
    if (type === 'success') {
      const timer = window.setTimeout(() => {
        timers.current.delete(id);
        setNotifications((current) => current.filter((notification) => notification.id !== id));
      }, SUCCESS_DURATION_MS);
      timers.current.set(id, timer);
    }

    return id;
  }, []);

  const success = useCallback((message) => notify(message, 'success'), [notify]);
  const failure = useCallback((message) => notify(message, 'error'), [notify]);

  useEffect(() => () => {
    timers.current.forEach((timer) => window.clearTimeout(timer));
    timers.current.clear();
  }, []);

  return { notifications, success, failure, dismiss };
}
