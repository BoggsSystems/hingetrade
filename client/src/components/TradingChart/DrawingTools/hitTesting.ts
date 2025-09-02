import type { Drawing, CanvasPoint, TrendlineDrawing, HorizontalLineDrawing, VerticalLineDrawing, RectangleDrawing, TextDrawing } from './types';
import { CoordinateConverter } from './coordinateUtils';

/**
 * Hit testing utilities for finding which drawing was clicked
 */

export function findDrawingAtPoint(
  drawings: Drawing[], 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter,
  tolerance: number = 8
): Drawing | null {
  console.log('🔍 findDrawingAtPoint called:', { drawings: drawings.length, canvasPoint, tolerance });
  
  // Search in reverse order so top-most drawings are selected first
  for (let i = drawings.length - 1; i >= 0; i--) {
    const drawing = drawings[i];
    console.log(`🔍 Testing drawing ${i}:`, drawing.type, drawing.id);
    
    if (isDrawingHit(drawing, canvasPoint, converter, tolerance)) {
      console.log('✅ HIT on drawing:', drawing.id);
      return drawing;
    }
  }
  
  console.log('❌ No drawing hit');
  return null;
}

function isDrawingHit(
  drawing: Drawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  switch (drawing.type) {
    case 'trendline':
      return isTrendlineHit(drawing as TrendlineDrawing, canvasPoint, converter, tolerance);
    
    case 'horizontal-line':
      return isHorizontalLineHit(drawing as HorizontalLineDrawing, canvasPoint, converter, tolerance);
    
    case 'vertical-line':
      return isVerticalLineHit(drawing as VerticalLineDrawing, canvasPoint, converter, tolerance);
    
    case 'rectangle':
      return isRectangleHit(drawing as RectangleDrawing, canvasPoint, converter, tolerance);
    
    case 'text':
      return isTextHit(drawing as TextDrawing, canvasPoint, converter, tolerance);
    
    default:
      return false;
  }
}

function isTrendlineHit(
  drawing: TrendlineDrawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  if (drawing.points.length < 2) return false;
  
  const start = converter.chartToCanvas(drawing.points[0]);
  const end = converter.chartToCanvas(drawing.points[1]);
  
  return converter.isPointNearLine(canvasPoint, start, end, tolerance);
}

function isHorizontalLineHit(
  drawing: HorizontalLineDrawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  if (drawing.points.length < 1) return false;
  
  const point = converter.chartToCanvas(drawing.points[0]);
  return converter.isPointNearHorizontalLine(canvasPoint, point.y, tolerance);
}

function isVerticalLineHit(
  drawing: VerticalLineDrawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  if (drawing.points.length < 1) return false;
  
  const point = converter.chartToCanvas(drawing.points[0]);
  return converter.isPointNearVerticalLine(canvasPoint, point.x, tolerance);
}

function isRectangleHit(
  drawing: RectangleDrawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  if (drawing.points.length < 2) return false;
  
  const start = converter.chartToCanvas(drawing.points[0]);
  const end = converter.chartToCanvas(drawing.points[1]);
  
  const x = Math.min(start.x, end.x);
  const y = Math.min(start.y, end.y);
  const width = Math.abs(end.x - start.x);
  const height = Math.abs(end.y - start.y);
  
  // Check if point is inside rectangle or near the border
  const rect = { x: x - tolerance, y: y - tolerance, width: width + 2 * tolerance, height: height + 2 * tolerance };
  const isInside = converter.isPointInRectangle(canvasPoint, rect);
  
  // Also check if point is near the border lines for thin rectangles
  const topLeft = { x, y };
  const topRight = { x: x + width, y };
  const bottomLeft = { x, y: y + height };
  const bottomRight = { x: x + width, y: y + height };
  
  return isInside || 
         converter.isPointNearLine(canvasPoint, topLeft, topRight, tolerance) ||
         converter.isPointNearLine(canvasPoint, topRight, bottomRight, tolerance) ||
         converter.isPointNearLine(canvasPoint, bottomRight, bottomLeft, tolerance) ||
         converter.isPointNearLine(canvasPoint, bottomLeft, topLeft, tolerance);
}

function isTextHit(
  drawing: TextDrawing, 
  canvasPoint: CanvasPoint, 
  converter: CoordinateConverter, 
  tolerance: number
): boolean {
  if (drawing.points.length < 1 || !drawing.text) return false;
  
  const position = converter.chartToCanvas(drawing.points[0]);
  const fontSize = drawing.style?.fontSize || 12;
  
  return converter.isPointNearText(canvasPoint, position, drawing.text, fontSize, tolerance);
}