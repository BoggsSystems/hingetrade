import type { Watchlist } from '../types';

const STORAGE_KEY = 'hingetrade_watchlists';
const DEFAULT_WATCHLIST_KEY = 'hingetrade_default_watchlist';

export class WatchlistService {
  // Save watchlists to localStorage
  private saveToStorage(watchlists: Watchlist[]): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(watchlists));
      
      // Also save the default watchlist separately for quick access
      const defaultWatchlist = watchlists.find(w => w.name === 'Default') || watchlists[0];
      if (defaultWatchlist) {
        localStorage.setItem(DEFAULT_WATCHLIST_KEY, JSON.stringify(defaultWatchlist));
      }
      
      console.log('💾 [WatchlistService] Saved watchlists to localStorage:', watchlists);
    } catch (error) {
      console.error('❌ [WatchlistService] Failed to save to localStorage:', error);
    }
  }

  // Load watchlists from localStorage
  private loadFromStorage(): Watchlist[] {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const watchlists = JSON.parse(saved);
        console.log('💾 [WatchlistService] Loaded watchlists from localStorage:', watchlists);
        return watchlists;
      }
    } catch (error) {
      console.error('❌ [WatchlistService] Failed to load from localStorage:', error);
    }
    
    return [];
  }

  // Get all watchlists (with localStorage fallback)
  async getWatchlists(): Promise<Watchlist[]> {
    console.log('🔍 [WatchlistService] Getting watchlists...');
    
    // Try localStorage first for immediate response
    const savedWatchlists = this.loadFromStorage();
    if (savedWatchlists.length > 0) {
      console.log('💾 [WatchlistService] Returning saved watchlists');
      return savedWatchlists;
    }
    
    // If no saved data, create a default watchlist
    const defaultWatchlist: Watchlist = {
      id: `watchlist-${Date.now()}`,
      accountId: 'default-account',
      name: 'Default',
      items: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    
    const newWatchlists = [defaultWatchlist];
    this.saveToStorage(newWatchlists);
    
    console.log('🔧 [WatchlistService] Created new default watchlist:', defaultWatchlist);
    return newWatchlists;
  }

  // Create a new watchlist
  async createWatchlist(name: string): Promise<Watchlist> {
    console.log(`🔧 [WatchlistService] Creating watchlist: ${name}`);
    
    const newWatchlist: Watchlist = {
      id: `watchlist-${Date.now()}`,
      accountId: 'default-account',
      name,
      items: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };
    
    const currentWatchlists = await this.getWatchlists();
    const updatedWatchlists = [...currentWatchlists, newWatchlist];
    this.saveToStorage(updatedWatchlists);
    
    console.log('✅ [WatchlistService] Created watchlist:', newWatchlist);
    return newWatchlist;
  }

  // Add symbol to watchlist
  async addToWatchlist(watchlistId: string, symbol: string): Promise<{ success: boolean }> {
    console.log(`➕ [WatchlistService] Adding ${symbol} to watchlist ${watchlistId}`);
    
    const watchlists = await this.getWatchlists();
    const updatedWatchlists = watchlists.map(w => {
      if (w.id === watchlistId) {
        const newItems = w.items.includes(symbol) ? w.items : [...w.items, symbol];
        return {
          ...w,
          items: newItems,
          updatedAt: new Date().toISOString(),
        };
      }
      return w;
    });
    
    this.saveToStorage(updatedWatchlists);
    console.log(`✅ [WatchlistService] Added ${symbol} to watchlist`);
    
    return { success: true };
  }

  // Remove symbol from watchlist
  async removeFromWatchlist(watchlistId: string, symbol: string): Promise<{ success: boolean }> {
    console.log(`🗑️ [WatchlistService] Removing ${symbol} from watchlist ${watchlistId}`);
    
    const watchlists = await this.getWatchlists();
    const updatedWatchlists = watchlists.map(w => {
      if (w.id === watchlistId) {
        const newItems = w.items.filter(item => item !== symbol);
        return {
          ...w,
          items: newItems,
          updatedAt: new Date().toISOString(),
        };
      }
      return w;
    });
    
    this.saveToStorage(updatedWatchlists);
    console.log(`✅ [WatchlistService] Removed ${symbol} from watchlist`);
    
    return { success: true };
  }

  // Delete entire watchlist
  async deleteWatchlist(watchlistId: string): Promise<{ success: boolean }> {
    console.log(`🗑️ [WatchlistService] Deleting watchlist ${watchlistId}`);
    
    const watchlists = await this.getWatchlists();
    const updatedWatchlists = watchlists.filter(w => w.id !== watchlistId);
    this.saveToStorage(updatedWatchlists);
    
    console.log(`✅ [WatchlistService] Deleted watchlist`);
    return { success: true };
  }

  // Get default watchlist
  async getDefaultWatchlist(): Promise<Watchlist> {
    const watchlists = await this.getWatchlists();
    let defaultWatchlist = watchlists.find(w => w.name === 'Default') || watchlists[0];
    
    if (!defaultWatchlist) {
      defaultWatchlist = await this.createWatchlist('Default');
    }
    
    return defaultWatchlist;
  }

  // Clear all data (for testing/reset)
  clearStorage(): void {
    localStorage.removeItem(STORAGE_KEY);
    localStorage.removeItem(DEFAULT_WATCHLIST_KEY);
    console.log('🧹 [WatchlistService] Cleared all watchlist storage');
  }
}

export const watchlistService = new WatchlistService();
export default watchlistService;