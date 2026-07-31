import { createContext, useCallback, useContext, type ReactNode } from "react";

import { useAsync } from "@/hooks/use-async";
import type { ServiceError, Result } from "@/services/result";
import { fetchTickets, purchaseTicket, type PurchaseInput } from "@/services/tickets";
import type { Ticket } from "@/types/ticket";

type TicketsContextValue = {
  tickets: Ticket[];
  isLoading: boolean;
  error: ServiceError | null;
  reload: () => void;
  purchase: (input: PurchaseInput) => Promise<Result<Ticket>>;
};

const TicketsContext = createContext<TicketsContextValue | null>(null);

export function TicketsProvider({ children }: { children: ReactNode }) {
  const { data, error, isLoading, reload } = useAsync(fetchTickets, []);

  const purchase = useCallback(
    async (input: PurchaseInput) => {
      const result = await purchaseTicket(input);
      if (result.ok) {
        reload();
      }
      return result;
    },
    [reload],
  );

  return (
    <TicketsContext.Provider value={{ tickets: data ?? [], isLoading, error, reload, purchase }}>
      {children}
    </TicketsContext.Provider>
  );
}

export function useTickets(): TicketsContextValue {
  const context = useContext(TicketsContext);
  if (!context) {
    throw new Error("useTickets must be used within a TicketsProvider");
  }
  return context;
}
