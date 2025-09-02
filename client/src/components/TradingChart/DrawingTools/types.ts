// Drawing tool types
export type DrawingTool = 'none' | 'trendline' | 'horizontal-line' | 'vertical-line' | 'rectangle' | 'text';

// Point in chart coordinates (timestamp, price)
export interface ChartPoint {
  x: number; // timestamp
  y: number; // price value
}

// Point in canvas coordinates (pixels)
export interface CanvasPoint {
  x: number; // pixel x
  y: number; // pixel y
}

// Base drawing interface
export interface BaseDrawing {
  id: string;
  type: DrawingTool;
  points: ChartPoint[];
  style?: DrawingStyle;
  selected?: boolean;
}

// Drawing style configuration
export interface DrawingStyle {
  color: string;
  width: number;
  opacity: number;
  lineDash?: number[];
  fontSize?: number;
  textColor?: string;
}

// Specific drawing types
export interface TrendlineDrawing extends BaseDrawing {
  type: 'trendline';
  points: [ChartPoint, ChartPoint]; // start and end points
}

export interface HorizontalLineDrawing extends BaseDrawing {
  type: 'horizontal-line';
  points: [ChartPoint]; // price level
}

export interface VerticalLineDrawing extends BaseDrawing {
  type: 'vertical-line';
  points: [ChartPoint]; // timestamp
}

export interface RectangleDrawing extends BaseDrawing {
  type: 'rectangle';
  points: [ChartPoint, ChartPoint]; // top-left and bottom-right corners
}

export interface TextDrawing extends BaseDrawing {
  type: 'text';
  points: [ChartPoint]; // position
  text: string;
  formatting?: {
    fontSize: number;
    fontFamily: string;
    color: string;
    backgroundColor: string;
    bold: boolean;
    italic: boolean;
    textAlign: 'left' | 'center' | 'right';
    hasBorder: boolean;
  };
}

// Union type for all drawings
export type Drawing = TrendlineDrawing | HorizontalLineDrawing | VerticalLineDrawing | RectangleDrawing | TextDrawing;

// Drawing state management
export interface DrawingState {
  activeTool: DrawingTool;
  drawings: Drawing[];
  selectedDrawingId: string | null;
  isDrawing: boolean;
  isDragging: boolean;
  dragStartPoint: ChartPoint | null;
  dragOffset: ChartPoint | null;
  currentDrawing: {
    id?: string;
    type: DrawingTool;
    points: ChartPoint[];
    style?: DrawingStyle;
    selected?: boolean;
    text?: string;
  } | null;
}

// Drawing interaction events
export interface DrawingInteractionEvent {
  canvasPoint: CanvasPoint;
  chartPoint: ChartPoint;
  event: MouseEvent;
}

// Default drawing styles
export const DEFAULT_DRAWING_STYLES: Record<DrawingTool, Partial<DrawingStyle>> = {
  'none': {},
  'trendline': {
    color: '#2196F3',
    width: 2,
    opacity: 1,
    lineDash: []
  },
  'horizontal-line': {
    color: '#FF9800',
    width: 1,
    opacity: 0.8,
    lineDash: [5, 5]
  },
  'vertical-line': {
    color: '#FF9800',
    width: 1,
    opacity: 0.8,
    lineDash: [5, 5]
  },
  'rectangle': {
    color: '#9C27B0',
    width: 1,
    opacity: 0.3,
    lineDash: []
  },
  'text': {
    color: '#4CAF50',
    width: 1,
    opacity: 1,
    fontSize: 12,
    textColor: '#4CAF50'
  }
};

// Helper functions for moving drawings
export function moveDrawing(drawing: Drawing, offset: ChartPoint): Drawing {
  const newPoints = drawing.points.map(point => ({
    x: point.x + offset.x,
    y: point.y + offset.y
  }));
  
  return {
    ...drawing,
    points: newPoints
  };
}

export function calculateDragOffset(clickPoint: ChartPoint, drawing: Drawing): ChartPoint {
  // Calculate offset from the first point of the drawing
  const firstPoint = drawing.points[0];
  return {
    x: firstPoint.x - clickPoint.x,
    y: firstPoint.y - clickPoint.y
  };
}