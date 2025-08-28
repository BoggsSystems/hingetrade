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


// Convert backend panel format to frontend format
const convertPanelFromApi = (panel: any): Panel => ({
  id: panel.id,
  position: {
    x: panel.position.x,
    y: panel.position.y,
    w: panel.position.w,
    h: panel.position.h,
    minW: panel.position.minW,
    minH: panel.position.minH,
  },
  config: {
    type: panel.type,
    title: panel.title,
    ...panel.config,
    linkGroup: panel.linkGroupId,
  },
});

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
  id: layout.id,
  name: layout.name,
  panels: layout.panels.map(convertPanelFromApi),
  gridConfig: {
    cols: layout.gridConfig.columns,
    rowHeight: layout.gridConfig.rowHeight,
    margin: [10, 10],
    containerPadding: [10, 10],
    compactType: layout.gridConfig.compactType || 'vertical',
    preventCollision: false,
  },
  linkGroups: layout.linkGroups.map((group: any) => ({
    id: group.id,
    name: group.name,
    color: group.color,
    symbol: group.symbol,
  })),
  createdAt: new Date(layout.createdAt),
  updatedAt: new Date(layout.updatedAt),
  isDefault: layout.isDefault,
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
    set({ isLoading: true, error: null });
    try {
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

    await get().updateLayout(activeLayout.id, activeLayout);
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