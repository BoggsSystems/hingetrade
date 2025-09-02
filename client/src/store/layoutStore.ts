import { create } from 'zustand';
import type { Layout, Panel, LinkGroup, GridConfig } from '../types/layout';
import { layoutService } from '../services/layoutService';

interface LayoutStore {
  // State
  layouts: Layout[];
  activeLayoutId: string | null;
  unsavedChanges: boolean;
  isLoading: boolean;
  error: string | null;

  // Layout CRUD actions
  loadLayouts: () => Promise<void>;
  createLayout: (name: string) => Promise<string>;
  updateLayout: (layoutId: string, updates: Partial<Layout>) => Promise<void>;
  deleteLayout: (layoutId: string) => Promise<void>;
  setActiveLayout: (layoutId: string) => void;
  saveLayout: () => Promise<void>;
  saveLayoutAs: (name: string) => Promise<string>;
  setDefaultLayout: (layoutId: string) => Promise<void>;

  // Panel actions
  addPanel: (panel: Panel) => void;
  updatePanel: (panelId: string, updates: Partial<Panel>) => void;
  removePanel: (panelId: string) => void;
  updatePanelPositions: (positions: Array<{ i: string; x: number; y: number; w: number; h: number }>) => void;

  // Link group actions
  createLinkGroup: (name: string, color: string) => string;
  updateLinkGroup: (groupId: string, updates: Partial<LinkGroup>) => void;
  deleteLinkGroup: (groupId: string) => void;
  assignPanelToLinkGroup: (panelId: string, groupId: string | null) => void;
  propagateSymbol: (groupId: string, symbol: string) => void;

  // Grid config actions
  updateGridConfig: (config: Partial<GridConfig>) => void;

  // Utility actions
  setUnsavedChanges: (hasChanges: boolean) => void;
  resetStore: () => void;
}


// Panel title normalization mapping
const normalizedPanelTitles: Record<string, string> = {
  'watchlist': 'Watchlist',
  'chart': 'Chart',
  'quote': 'Quote',
  'trade': 'Trade',
  'orders': 'Orders',
  'positions': 'Positions',
  'account': 'Accounts',
  'news': 'News',
  'portfolio': 'Portfolio',
  'market-overview': 'Market Overview',
  'recent-activity': 'Recent Activity',
  'video': 'Video Feed'
};

// Convert backend panel format to frontend format
const convertPanelFromApi = (panel: any): Panel => {
  console.log('=== convertPanelFromApi START ===');
  console.log('Input panel:', panel);
  
  const id = panel.id || panel.Id;
  if (!id) {
    console.warn('Panel missing ID:', panel);
  }
  
  // Log all position-related properties
  console.log('Position property checks:');
  console.log('  panel.Position:', panel.Position);
  console.log('  panel.position:', panel.position);
  console.log('  panel.x:', panel.x);
  console.log('  panel.y:', panel.y);
  console.log('  panel.X:', panel.X);
  console.log('  panel.Y:', panel.Y);
  if (panel.Position) {
    console.log('  panel.Position.X:', panel.Position.X);
    console.log('  panel.Position.Y:', panel.Position.Y);
    console.log('  panel.Position.x:', panel.Position.x);
    console.log('  panel.Position.y:', panel.Position.y);
  }
  
  // Step-by-step position extraction
  const x_step1 = panel.Position?.X;
  const x_step2 = x_step1 ?? panel.Position?.x;
  const x_step3 = x_step2 ?? panel.position?.x;
  const x_final = x_step3 ?? 0;
  console.log(`  X calculation: Position.X(${panel.Position?.X}) ?? Position.x(${panel.Position?.x}) ?? position.x(${panel.position?.x}) ?? 0 = ${x_final}`);
  
  const y_step1 = panel.Position?.Y;
  const y_step2 = y_step1 ?? panel.Position?.y;
  const y_step3 = y_step2 ?? panel.position?.y;
  const y_final = y_step3 ?? 0;
  console.log(`  Y calculation: Position.Y(${panel.Position?.Y}) ?? Position.y(${panel.Position?.y}) ?? position.y(${panel.position?.y}) ?? 0 = ${y_final}`);
  
  const position = {
    x: panel.Position?.X ?? panel.Position?.x ?? panel.position?.x ?? panel.position?.X ?? 0,
    y: panel.Position?.Y ?? panel.Position?.y ?? panel.position?.y ?? panel.position?.Y ?? 0,
    w: panel.Position?.W ?? panel.Position?.w ?? panel.position?.w ?? panel.position?.W ?? 4,
    h: panel.Position?.H ?? panel.Position?.h ?? panel.position?.h ?? panel.position?.H ?? 4,
    minW: panel.Position?.MinW ?? panel.Position?.minW ?? panel.position?.minW ?? panel.position?.MinW ?? 1,
    minH: panel.Position?.MinH ?? panel.Position?.minH ?? panel.position?.minH ?? panel.position?.MinH ?? 1,
  };
  
  console.log('Final position object:', position);
  console.log(`=== convertPanelFromApi END for panel ${id} ===`);
  
  const panelType = panel.Type ?? panel.type;
  const originalTitle = panel.Title ?? panel.title;
  
  // Normalize the title if it's a known panel type
  const normalizedTitle = normalizedPanelTitles[panelType] || originalTitle || panelType;
  
  return {
    id: id,
    position: position,
    config: {
      type: panelType,
      title: normalizedTitle,
      ...(panel.Config ?? panel.config ?? {}),
      linkGroup: panel.LinkGroupId ?? panel.linkGroupId,
    },
  };
};

// Convert frontend panel format to backend format
const convertPanelToApi = (panel: Panel) => {
  const linkGroupId = panel.config?.linkGroup;
  return {
    id: panel.id,
    type: panel.config.type,
    title: panel.config.title,
    position: {
      x: panel.position.x,
      y: panel.position.y,
      w: panel.position.w,
      h: panel.position.h,
      minW: panel.position.minW || 2,
      minH: panel.position.minH || 3,
    },
    linkGroupId,
    config: {
      ...panel.config,
      type: undefined,
      title: undefined,
      linkGroup: undefined,
    },
  };
};

// Convert backend layout format to frontend format
const convertLayoutFromApi = (layout: any): Layout => ({
  id: layout.id || layout.Id,
  name: layout.name || layout.Name,
  panels: (layout.panels || layout.Panels || []).map(convertPanelFromApi),
  gridConfig: (layout.gridConfig || layout.GridConfig) ? {
    cols: (layout.gridConfig || layout.GridConfig).columns || (layout.gridConfig || layout.GridConfig).Columns || 24,
    rowHeight: (layout.gridConfig || layout.GridConfig).rowHeight || (layout.gridConfig || layout.GridConfig).RowHeight || 30,
    margin: [10, 10],
    containerPadding: [10, 10],
    compactType: (layout.gridConfig || layout.GridConfig).compactType || (layout.gridConfig || layout.GridConfig).CompactType || 'vertical',
    preventCollision: false,
  } : {
    cols: 24,
    rowHeight: 30,
    margin: [10, 10],
    containerPadding: [10, 10],
    compactType: 'vertical',
    preventCollision: false,
  },
  linkGroups: (layout.linkGroups || layout.LinkGroups || []).map((group: any) => ({
    id: group.id || group.Id,
    name: group.name || group.Name,
    color: group.color || group.Color,
    symbol: group.symbol || group.Symbol,
  })),
  createdAt: new Date(layout.createdAt || layout.CreatedAt),
  updatedAt: new Date(layout.updatedAt || layout.UpdatedAt),
  isDefault: layout.isDefault || layout.IsDefault || false,
});

const useLayoutStore = create<LayoutStore>((set, get) => ({
  // Initial state
  layouts: [],
  activeLayoutId: null,
  unsavedChanges: false,
  isLoading: false,
  error: null,

  // Layout CRUD actions
  loadLayouts: async () => {
    console.log('layoutStore: loadLayouts called');
    const state = get();
    
    // Prevent concurrent requests
    if (state.isLoading) {
      console.log('layoutStore: already loading, skipping');
      return;
    }
    
    set({ isLoading: true, error: null });
    try {
      console.log('layoutStore: calling layoutService.getLayouts()');
      const layouts = await layoutService.getLayouts();
      const convertedLayouts = layouts.map(convertLayoutFromApi);
      
      // Set the default layout as active if no active layout
      const defaultLayout = convertedLayouts.find(l => l.isDefault);
      const activeLayoutId = get().activeLayoutId || defaultLayout?.id || convertedLayouts[0]?.id || null;
      
      set({
        layouts: convertedLayouts,
        activeLayoutId,
        isLoading: false,
      });
    } catch (error) {
      console.error('Failed to load layouts:', error);
      set({ error: 'Failed to load layouts', isLoading: false });
    }
  },

  createLayout: async (name: string) => {
    set({ isLoading: true, error: null });
    try {
      const layout = await layoutService.createLayout({ name });
      const convertedLayout = convertLayoutFromApi(layout);
      
      set(state => ({
        layouts: [...state.layouts, convertedLayout],
        activeLayoutId: convertedLayout.id,
        unsavedChanges: false,
        isLoading: false,
      }));
      
      return convertedLayout.id;
    } catch (error) {
      console.error('Failed to create layout:', error);
      set({ error: 'Failed to create layout', isLoading: false });
      throw error;
    }
  },

  updateLayout: async (layoutId: string, updates: Partial<Layout>) => {
    const state = get();
    const layout = state.layouts.find(l => l.id === layoutId);
    if (!layout) return;

    set({ isLoading: true, error: null });
    try {
      // Prepare the update request
      const request: any = {};
      
      if (updates.name !== undefined) {
        request.name = updates.name;
      }
      
      if (updates.panels !== undefined) {
        console.log('updateLayout: Converting panels to API format. Panel count:', updates.panels.length);
        console.log('updateLayout: Panel IDs:', updates.panels.map(p => p.id));
        request.panels = updates.panels.map(p => convertPanelToApi(p));
      }
      
      if (updates.linkGroups !== undefined) {
        request.linkGroups = updates.linkGroups.map(group => ({
          id: group.id,
          name: group.name,
          color: group.color,
          symbol: group.symbol,
          panelIds: updates.panels
            ?.filter(p => p.config?.linkGroup === group.id)
            .map(p => p.id) || [],
        }));
      }
      
      if (updates.gridConfig !== undefined) {
        request.gridConfig = {
          columns: updates.gridConfig.cols,
          rowHeight: updates.gridConfig.rowHeight,
          compactType: updates.gridConfig.compactType || undefined,
        };
      }

      console.log('Sending update layout request:', JSON.stringify(request, null, 2));
      const updatedLayout = await layoutService.updateLayout(layoutId, request);
      const convertedLayout = convertLayoutFromApi(updatedLayout);
      
      set(state => ({
        layouts: state.layouts.map(l => l.id === layoutId ? convertedLayout : l),
        unsavedChanges: false,
        isLoading: false,
      }));
    } catch (error) {
      console.error('Failed to update layout:', error);
      set({ error: 'Failed to update layout', isLoading: false });
      throw error;
    }
  },

  deleteLayout: async (layoutId: string) => {
    set({ isLoading: true, error: null });
    try {
      await layoutService.deleteLayout(layoutId);
      
      set(state => {
        const remainingLayouts = state.layouts.filter(l => l.id !== layoutId);
        const newActiveId = state.activeLayoutId === layoutId
          ? remainingLayouts.find(l => l.isDefault)?.id || remainingLayouts[0]?.id || null
          : state.activeLayoutId;
        
        return {
          layouts: remainingLayouts,
          activeLayoutId: newActiveId,
          unsavedChanges: false,
          isLoading: false,
        };
      });
    } catch (error) {
      console.error('Failed to delete layout:', error);
      set({ error: 'Failed to delete layout', isLoading: false });
      throw error;
    }
  },

  setActiveLayout: (layoutId: string) => {
    set({ activeLayoutId: layoutId });
  },

  saveLayout: async () => {
    const state = get();
    const activeLayout = state.layouts.find(l => l.id === state.activeLayoutId);
    if (!activeLayout) return;

    console.log('saveLayout: activeLayout panels:', activeLayout.panels);
    console.log('saveLayout: activeLayout linkGroups:', activeLayout.linkGroups);
    
    // Pass only the fields that updateLayout expects
    await get().updateLayout(activeLayout.id, {
      panels: activeLayout.panels,
      linkGroups: activeLayout.linkGroups,
      gridConfig: activeLayout.gridConfig,
    });
  },

  saveLayoutAs: async (name: string) => {
    const state = get();
    const activeLayout = state.layouts.find(l => l.id === state.activeLayoutId);
    if (!activeLayout) throw new Error('No active layout');

    set({ isLoading: true, error: null });
    try {
      const request = {
        name,
        gridConfig: {
          columns: activeLayout.gridConfig.cols,
          rowHeight: activeLayout.gridConfig.rowHeight,
          compactType: activeLayout.gridConfig.compactType || undefined,
        },
        panels: activeLayout.panels.map(p => convertPanelToApi(p)),
        linkGroups: activeLayout.linkGroups.map(group => ({
          id: group.id,
          name: group.name,
          color: group.color,
          symbol: group.symbol,
          panelIds: activeLayout.panels
            .filter(p => p.config?.linkGroup === group.id)
            .map(p => p.id),
        })),
      };

      const layout = await layoutService.createLayout(request);
      const convertedLayout = convertLayoutFromApi(layout);
      
      set(state => ({
        layouts: [...state.layouts, convertedLayout],
        activeLayoutId: convertedLayout.id,
        unsavedChanges: false,
        isLoading: false,
      }));
      
      return convertedLayout.id;
    } catch (error) {
      console.error('Failed to save layout as:', error);
      set({ error: 'Failed to save layout as new', isLoading: false });
      throw error;
    }
  },

  setDefaultLayout: async (layoutId: string) => {
    set({ isLoading: true, error: null });
    try {
      await layoutService.setDefaultLayout(layoutId);
      
      set(state => ({
        layouts: state.layouts.map(l => ({
          ...l,
          isDefault: l.id === layoutId,
        })),
        isLoading: false,
      }));
    } catch (error) {
      console.error('Failed to set default layout:', error);
      set({ error: 'Failed to set default layout', isLoading: false });
      throw error;
    }
  },

  // Panel actions (local only - will trigger save)
  addPanel: (panel: Panel) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              panels: [...layout.panels, panel],
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  updatePanel: (panelId: string, updates: Partial<Panel>) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              panels: layout.panels.map(panel =>
                panel.id === panelId
                  ? { ...panel, ...updates }
                  : panel
              ),
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  removePanel: (panelId: string) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              panels: layout.panels.filter(p => p.id !== panelId),
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  updatePanelPositions: (positions) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              panels: layout.panels.map(panel => {
                const newPos = positions.find(p => p.i === panel.id);
                return newPos
                  ? {
                      ...panel,
                      position: {
                        ...panel.position,
                        x: newPos.x,
                        y: newPos.y,
                        w: newPos.w,
                        h: newPos.h,
                      },
                    }
                  : panel;
              }),
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  // Link group actions (local only - will trigger save)
  createLinkGroup: (name: string, color: string) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return '';

    const groupId = `group-${Date.now()}`;
    const newGroup: LinkGroup = { id: groupId, name, color };

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              linkGroups: [...layout.linkGroups, newGroup],
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));

    return groupId;
  },

  updateLinkGroup: (groupId: string, updates: Partial<LinkGroup>) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              linkGroups: layout.linkGroups.map(group =>
                group.id === groupId
                  ? { ...group, ...updates }
                  : group
              ),
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  deleteLinkGroup: (groupId: string) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              linkGroups: layout.linkGroups.filter(g => g.id !== groupId),
              panels: layout.panels.map(panel => ({
                ...panel,
                config: {
                  ...panel.config,
                  linkGroup: panel.config.linkGroup === groupId ? undefined : panel.config.linkGroup,
                },
              })),
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  assignPanelToLinkGroup: (panelId: string, groupId: string | null) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              panels: layout.panels.map(panel =>
                panel.id === panelId
                  ? {
                      ...panel,
                      config: {
                        ...panel.config,
                        linkGroup: groupId || undefined,
                      },
                    }
                  : panel
              ),
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  propagateSymbol: (groupId: string, symbol: string) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              linkGroups: layout.linkGroups.map(group =>
                group.id === groupId
                  ? { ...group, symbol }
                  : group
              ),
              updatedAt: new Date(),
            }
          : layout
      ),
    }));
  },

  // Grid config actions (local only - will trigger save)
  updateGridConfig: (config: Partial<GridConfig>) => {
    const { activeLayoutId } = get();
    if (!activeLayoutId) return;

    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === activeLayoutId
          ? {
              ...layout,
              gridConfig: { ...layout.gridConfig, ...config },
              updatedAt: new Date(),
            }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  // Utility actions
  setUnsavedChanges: (hasChanges: boolean) => {
    set({ unsavedChanges: hasChanges });
  },

  resetStore: () => {
    console.log('layoutStore: resetStore called - clearing all layout data');
    set({
      layouts: [],
      activeLayoutId: null,
      unsavedChanges: false,
      isLoading: false,
      error: null,
    });
  },
}));

// Selector to get active layout
export const useActiveLayout = () => {
  const layouts = useLayoutStore(state => state.layouts);
  const activeLayoutId = useLayoutStore(state => state.activeLayoutId);
  return layouts.find(l => l.id === activeLayoutId) || null;
};

export default useLayoutStore;