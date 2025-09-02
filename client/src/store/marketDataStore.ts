import React from 'react';
import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';
// import { marketDataService, type Quote, type ConnectionStatus } from '../services/marketDataService';

// Temporary types until we implement the real service
interface Quote {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  timestamp: Date;
}

interface ConnectionStatus {
  connected: boolean;
  error?: string;
}

interface MarketDataState {
  // Quote data
  quotes: Map<string, Quote>;
  
  // Connection status
  connectionStatus: ConnectionStatus;
  
  // Subscription tracking
  subscriptions: Map<string, number>; // symbol -> reference count
  
  // Actions
  subscribe: (symbol: string) => void;
  unsubscribe: (symbol: string) => void;
  updateQuote: (quote: Quote) => void;
  setConnectionStatus: (status: ConnectionStatus) => void;
  
  // Selectors
  getQuote: (symbol: string) => Quote | undefined;
  isSubscribed: (symbol: string) => boolean;
}

const useMarketDataStore = create<MarketDataState>()(
  subscribeWithSelector((set, get) => ({
    quotes: new Map(),
    connectionStatus: { connected: false },
    subscriptions: new Map(),

    subscribe: (symbol: string) => {
      symbol = symbol.toUpperCase();
      const { subscriptions } = get();
      const currentCount = subscriptions.get(symbol) || 0;
      
      // Increment reference count
      set(state => ({
        subscriptions: new Map(state.subscriptions).set(symbol, currentCount + 1)
      }));
      
      // If this is the first subscription, subscribe to the service
      if (currentCount === 0) {
        // TODO: Implement real market data service
        console.log(`Would subscribe to ${symbol}`);
        // marketDataService.subscribe(symbol, (quote) => {
        //   get().updateQuote(quote);
        // }).catch(error => {
        //   console.error(`Failed to subscribe to ${symbol}:`, error);
        //   // Revert subscription count on error
        //   set(state => {
        //     const newSubs = new Map(state.subscriptions);
        //     const count = newSubs.get(symbol) || 0;
        //     if (count <= 1) {
        //       newSubs.delete(symbol);
        //     } else {
        //       newSubs.set(symbol, count - 1);
        //     }
        //     return { subscriptions: newSubs };
        //   });
        // });
      }
    },

    unsubscribe: (symbol: string) => {
      symbol = symbol.toUpperCase();
      const { subscriptions } = get();
      const currentCount = subscriptions.get(symbol) || 0;
      
      if (currentCount <= 0) return;
      
      const newCount = currentCount - 1;
      
      // Update reference count
      set(state => {
        const newSubs = new Map(state.subscriptions);
        if (newCount <= 0) {
          newSubs.delete(symbol);
        } else {
          newSubs.set(symbol, newCount);
        }
        return { subscriptions: newSubs };
      });
      
      // If no more subscriptions, unsubscribe from the service
      if (newCount <= 0) {
        // TODO: Implement real market data service
        console.log(`Would unsubscribe from ${symbol}`);
        // marketDataService.unsubscribe(symbol, () => {}).catch(error => {
        //   console.error(`Failed to unsubscribe from ${symbol}:`, error);
        // });
      }
    },

    updateQuote: (quote: Quote) => {
      set(state => ({
        quotes: new Map(state.quotes).set(quote.symbol, quote)
      }));
    },

    setConnectionStatus: (status: ConnectionStatus) => {
      set({ connectionStatus: status });
    },

    getQuote: (symbol: string) => {
      return get().quotes.get(symbol.toUpperCase());
    },

    isSubscribed: (symbol: string) => {
      return get().subscriptions.has(symbol.toUpperCase());
    },
  }))
);

// Set up connection status listener
// TODO: Implement real market data service
// marketDataService.onConnectionStatusChange((status) => {
//   useMarketDataStore.getState().setConnectionStatus(status);
// });

// Custom hook for subscribing to a single quote
export const useQuote = (symbol: string | null | undefined) => {
  const subscribe = useMarketDataStore(state => state.subscribe);
  const unsubscribe = useMarketDataStore(state => state.unsubscribe);
  const quote = useMarketDataStore(state => symbol ? state.quotes.get(symbol.toUpperCase()) : undefined);

  // Effect for subscription management
  React.useEffect(() => {
    if (!symbol) return;

    subscribe(symbol);
    
    return () => {
      unsubscribe(symbol);
    };
  }, [symbol, subscribe, unsubscribe]);

  return quote;
};

// Custom hook for subscribing to multiple quotes
export const useQuotes = (symbols: string[]) => {
  const subscribe = useMarketDataStore(state => state.subscribe);
  const unsubscribe = useMarketDataStore(state => state.unsubscribe);
  const quotes = useMarketDataStore(state => {
    const result: Record<string, Quote> = {};
    symbols.forEach(symbol => {
      const quote = state.quotes.get(symbol.toUpperCase());
      if (quote) {
        result[symbol.toUpperCase()] = quote;
      }
    });
    return result;
  });

  // Effect for subscription management
  React.useEffect(() => {
    symbols.forEach(symbol => subscribe(symbol));
    
    return () => {
      symbols.forEach(symbol => unsubscribe(symbol));
    };
  }, [symbols.join(','), subscribe, unsubscribe]); // Use joined string as dependency

  return quotes;
};

// Custom hook for connection status
export const useMarketDataConnection = () => {
  return useMarketDataStore(state => state.connectionStatus);
};

export default useMarketDataStore;