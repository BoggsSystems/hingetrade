import type { PanelConfig } from './layout';

export interface PanelSize {
  width: number;
  height: number;
}

export interface IPanelComponentProps {
  // Required props
  id: string;
  config: PanelConfig;

  // Symbol linking
  symbol?: string;
  onSymbolChange?: (symbol: string) => void;

  // Lifecycle
  onReady?: () => void;
  onError?: (error: Error) => void;
  onConfigChange?: (config: Partial<PanelConfig>) => void;

  // Layout events
  onResize?: (size: PanelSize) => void;
  onFocus?: () => void;
  onBlur?: () => void;
}

export interface IPanelComponent extends React.FC<IPanelComponentProps> {
  // Static properties for panel metadata
  panelType: string;
  displayName: string;
  defaultConfig?: Partial<PanelConfig>;
}

export const PanelState = {
  LOADING: 'loading',
  READY: 'ready',
  ERROR: 'error',
} as const;

export interface PanelLifecycleHooks {
  onMount?: () => void;
  onDestroy?: () => void;
  onResize?: (size: PanelSize) => void;
  onSymbolChange?: (symbol: string) => void;
  onConfigUpdate?: (config: Partial<PanelConfig>) => void;
}