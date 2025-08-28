import { api } from './api';

export interface GridConfig {
  columns: number;
  rowHeight: number;
  compactType?: string;
}

export interface Position {
  x: number;
  y: number;
  w: number;
  h: number;
  minW: number;
  minH: number;
}

export interface Panel {
  id: string;
  type: string;
  title?: string;
  position: Position;
  linkGroupId?: string;
  config?: any;
}

export interface LinkGroup {
  id: string;
  name: string;
  color: string;
  symbol?: string;
  panelIds: string[];
}

export interface Layout {
  id: string;
  name: string;
  isDefault: boolean;
  gridConfig: GridConfig;
  panels: Panel[];
  linkGroups: LinkGroup[];
  createdAt: string;
  updatedAt: string;
}

export interface CreateLayoutRequest {
  name: string;
  isDefault?: boolean;
  gridConfig?: GridConfig;
  panels?: Panel[];
  linkGroups?: LinkGroup[];
}

export interface UpdateLayoutRequest {
  name?: string;
  gridConfig?: GridConfig;
  panels?: Panel[];
  linkGroups?: LinkGroup[];
}

class LayoutService {
  async getLayouts(): Promise<Layout[]> {
    const response = await api.get('/layouts');
    return response.data;
  }

  async getLayout(layoutId: string): Promise<Layout> {
    const response = await api.get(`/layouts/${layoutId}`);
    return response.data;
  }

  async createLayout(request: CreateLayoutRequest): Promise<Layout> {
    const response = await api.post('/layouts', request);
    return response.data;
  }

  async updateLayout(layoutId: string, request: UpdateLayoutRequest): Promise<Layout> {
    const response = await api.put(`/layouts/${layoutId}`, request);
    return response.data;
  }

  async deleteLayout(layoutId: string): Promise<void> {
    await api.delete(`/layouts/${layoutId}`);
  }

  async setDefaultLayout(layoutId: string): Promise<Layout> {
    const response = await api.post(`/layouts/${layoutId}/set-default`);
    return response.data;
  }
}

export const layoutService = new LayoutService();