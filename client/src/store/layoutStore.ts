import { create } from 'zustand';
import type { Layout, Panel, LinkGroup, GridConfig } from '../types/layout';

interface LayoutStore {
  // State
  layouts: Layout[];
  activeLayoutId: string | null;
  unsavedChanges: boolean;

  // Getters
  activeLayout: Layout | null;

  // Layout CRUD actions
  createLayout: (name: string) => string;
  updateLayout: (layoutId: string, updates: Partial<Layout>) => void;
  deleteLayout: (layoutId: string) => void;
  setActiveLayout: (layoutId: string) => void;
  saveLayout: () => void;
  saveLayoutAs: (name: string) => string;

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

const defaultGridConfig: GridConfig = {
  cols: 12,
  rowHeight: 50,
  margin: [10, 10],
  containerPadding: [10, 10],
  compactType: 'vertical',
  preventCollision: false,
};

const createDefaultLayout = (name: string): Layout => ({
  id: `layout-${Date.now()}`,
  name,
  panels: [],
  gridConfig: defaultGridConfig,
  linkGroups: [],
  createdAt: new Date(),
  updatedAt: new Date(),
  isDefault: false,
});

const useLayoutStore = create<LayoutStore>((set, get) => ({
  // Initial state
  layouts: [],
  activeLayoutId: null,
  unsavedChanges: false,

  // Computed getter
  get activeLayout() {
    const { layouts, activeLayoutId } = get();
    return layouts.find(l => l.id === activeLayoutId) || null;
  },

  // Layout CRUD actions
  createLayout: (name: string) => {
    const newLayout = createDefaultLayout(name);
    set(state => ({
      layouts: [...state.layouts, newLayout],
      activeLayoutId: newLayout.id,
      unsavedChanges: false,
    }));
    return newLayout.id;
  },

  updateLayout: (layoutId: string, updates: Partial<Layout>) => {
    set(state => ({
      layouts: state.layouts.map(layout =>
        layout.id === layoutId
          ? { ...layout, ...updates, updatedAt: new Date() }
          : layout
      ),
      unsavedChanges: true,
    }));
  },

  deleteLayout: (layoutId: string) => {
    set(state => {
      const remainingLayouts = state.layouts.filter(l => l.id !== layoutId);
      const newActiveId = state.activeLayoutId === layoutId
        ? remainingLayouts[0]?.id || null
        : state.activeLayoutId;
      
      return {
        layouts: remainingLayouts,
        activeLayoutId: newActiveId,
        unsavedChanges: false,
      };
    });
  },

  setActiveLayout: (layoutId: string) => {
    set({ activeLayoutId: layoutId });
  },

  saveLayout: () => {
    const { activeLayout } = get();
    if (activeLayout) {
      // In a real app, this would save to backend
      set({ unsavedChanges: false });
    }
  },

  saveLayoutAs: (name: string) => {
    const { activeLayout } = get();
    if (!activeLayout) return '';

    const newLayout: Layout = {
      ...activeLayout,
      id: `layout-${Date.now()}`,
      name,
      createdAt: new Date(),
      updatedAt: new Date(),
      isDefault: false,
    };

    set(state => ({
      layouts: [...state.layouts, newLayout],
      activeLayoutId: newLayout.id,
      unsavedChanges: false,
    }));

    return newLayout.id;
  },

  // Panel actions
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

  // Link group actions
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

  // Grid config actions
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
    });
  },
}));

export default useLayoutStore;