import type { Drawing, CanvasPoint } from './types';
import { CoordinateConverter } from './coordinateUtils';

/**
 * Lightweight hit testing for cursor changes (without debug logging)
 */
export function findDrawingForCursor(
  drawings: Drawing[], 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter,
  tolerance: number = 8
): Drawing | null {
  // Search in reverse order so top-most drawings are detected first
  for (let i = drawings.length - 1; i >= 0; i--) {
    const drawing = drawings[i];
    
    if (isDrawingHitForCursor(drawing, canvasPoint, converter, tolerance)) {
      return drawing;
    }
  }
  
  return null;
}

function isDrawingHitForCursor(
  drawing: Drawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  switch (drawing.type) {
    case 'trendline':
      if (drawing.points.length < 2) return false;
      const start = converter.chartToCanvas(drawing.points[0]);
      const end = converter.chartToCanvas(drawing.points[1]);
      return isPointNearLineSimple(canvasPoint, start, end, tolerance);
    
    case 'horizontal-line':
      if (drawing.points.length < 1) return false;
      const hPoint = converter.chartToCanvas(drawing.points[0]);
      const chartArea = converter.chart.chartArea;
      return Math.abs(canvasPoint.y - hPoint.y) <= tolerance && 
             canvasPoint.x >= chartArea.left && 
             canvasPoint.x <= chartArea.right;
    
    case 'vertical-line':
      if (drawing.points.length < 1) return false;
      const vPoint = converter.chartToCanvas(drawing.points[0]);
      const chartAreaV = converter.chart.chartArea;
      return Math.abs(canvasPoint.x - vPoint.x) <= tolerance && 
             canvasPoint.y >= chartAreaV.top && 
             canvasPoint.y <= chartAreaV.bottom;
    
    case 'rectangle':
      if (drawing.points.length < 2) return false;
      const rectStart = converter.chartToCanvas(drawing.points[0]);
      const rectEnd = converter.chartToCanvas(drawing.points[1]);
      const x = Math.min(rectStart.x, rectEnd.x);
      const y = Math.min(rectStart.y, rectEnd.y);
      const width = Math.abs(rectEnd.x - rectStart.x);
      const height = Math.abs(rectEnd.y - rectStart.y);
      
      // Check if inside rectangle or near border
      const expandedRect = {
        x: x - tolerance,
        y: y - tolerance,
        width: width + 2 * tolerance,
        height: height + 2 * tolerance
      };
      
      return canvasPoint.x >= expandedRect.x && 
             canvasPoint.x <= expandedRect.x + expandedRect.width &&
             canvasPoint.y >= expandedRect.y && 
             canvasPoint.y <= expandedRect.y + expandedRect.height;
    
    case 'text':
      if (drawing.points.length < 1 || !drawing.text) return false;
      const textPos = converter.chartToCanvas(drawing.points[0]);
      const fontSize = drawing.style?.fontSize || 12;
      const textWidth = drawing.text.length * (fontSize * 0.6);
      const textHeight = fontSize + 8;
      
      return canvasPoint.x >= textPos.x - textWidth / 2 - 4 &&
             canvasPoint.x <= textPos.x + textWidth / 2 + 4 &&
             canvasPoint.y >= textPos.y - textHeight - 4 &&
             canvasPoint.y <= textPos.y + 4;
    
    default:
      return false;
  }
}

function isPointNearLineSimple(point: CanvasPoint, lineStart: CanvasPoint, lineEnd: CanvasPoint, tolerance: number): boolean {
  const dx = lineEnd.x - lineStart.x;
  const dy = lineEnd.y - lineStart.y;
  const length = Math.sqrt(dx * dx + dy * dy);
  
  if (length === 0) {
    const distance = Math.sqrt((point.x - lineStart.x) ** 2 + (point.y - lineStart.y) ** 2);
    return distance <= tolerance;
  }
  
  const t = Math.max(0, Math.min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (length * length)));
  const projection = {
    x: lineStart.x + t * dx,
    y: lineStart.y + t * dy
  };
  
  const distance = Math.sqrt((point.x - projection.x) ** 2 + (point.y - projection.y) ** 2);
  return distance <= tolerance;
}