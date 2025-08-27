export interface GridConfig {
  cols: number;
  rowHeight: number;
  margin: [number, number];
  containerPadding: [number, number];
  maxRows?: number;
  compactType?: 'vertical' | 'horizontal' | null;
  preventCollision?: boolean;
}

export interface PanelPosition {
  x: number;
  y: number;
  w: number;
  h: number;
  minW?: number;
  minH?: number;
  maxW?: number;
  maxH?: number;
  static?: boolean;
}

export interface PanelConfig {
  type: string;
  title?: string;
  settings?: Record<string, any>;
  linkGroup?: string;
}

export interface Panel {
  id: string;
  position: PanelPosition;
  config: PanelConfig;
}

export interface LinkGroup {
  id: string;
  name: string;
  color: string;
  symbol?: string;
}

export interface Layout {
  id: string;
  name: string;
  panels: Panel[];
  gridConfig: GridConfig;
  linkGroups: LinkGroup[];
  createdAt: Date;
  updatedAt: Date;
  isDefault?: boolean;
}

export interface LayoutState {
  layouts: Layout[];
  activeLayoutId: string | null;
  unsavedChanges: boolean;
}

export type PanelType = 
  | 'quote'
  | 'chart'
  | 'positions'
  | 'trade'
  | 'news'
  | 'watchlist'
  | 'depth'
  | 'time-sales'
  | 'options'
  | 'scanner';

export interface PanelRegistryEntry {
  type: PanelType;
  name: string;
  description: string;
  icon?: string;
  defaultConfig?: Partial<PanelConfig>;
  defaultPosition?: Partial<PanelPosition>;
}