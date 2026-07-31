import { useCallback, useEffect, useRef, useState } from "react";

import type { Result, ServiceError } from "@/services/result";

type AsyncState<T> = {
  data: T | null;
  error: ServiceError | null;
  isLoading: boolean;
};

export function useAsync<T>(fetcher: () => Promise<Result<T>>, deps: unknown[]) {
  const [state, setState] = useState<AsyncState<T>>({
    data: null,
    error: null,
    isLoading: true,
  });
  const [reloadToken, setReloadToken] = useState(0);
  const fetcherRef = useRef(fetcher);
  fetcherRef.current = fetcher;

  useEffect(() => {
    let cancelled = false;
    setState((previous) => ({ ...previous, isLoading: true, error: null }));

    fetcherRef.current().then((result) => {
      if (cancelled) return;
      if (result.ok) {
        setState({ data: result.data, error: null, isLoading: false });
      } else {
        setState({ data: null, error: result.error, isLoading: false });
      }
    });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, reloadToken]);

  const reload = useCallback(() => setReloadToken((token) => token + 1), []);

  return { ...state, reload };
}
