import type { Chart as ChartJS, Plugin } from 'chart.js';
import type { Drawing, DrawingStyle, TrendlineDrawing, HorizontalLineDrawing, VerticalLineDrawing, RectangleDrawing, TextDrawing } from './types';
import { CoordinateConverter } from './coordinateUtils';
import { DEFAULT_DRAWING_STYLES } from './types';

export interface DrawingPluginOptions {
  drawings: Drawing[];
  onDrawingClick?: (drawing: Drawing) => void;
}

export const drawingPlugin: Plugin<'line' | 'bar', DrawingPluginOptions> = {
  id: 'drawingTools',
  
  afterDraw(chart: ChartJS, _args: any, options: DrawingPluginOptions) {
    if (!options.drawings || options.drawings.length === 0) return;

    const ctx = chart.ctx;
    const converter = new CoordinateConverter(chart);
    
    ctx.save();
    
    // Set default canvas properties
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    
    // Draw each drawing
    options.drawings.forEach(drawing => {
      try {
        drawDrawing(ctx, converter, drawing);
        
        // Draw selection handles for selected drawings
        if (drawing.selected) {
          drawSelectionHandles(ctx, converter, drawing);
        }
      } catch (error) {
        console.warn('Failed to draw drawing:', drawing.id, error);
      }
    });
    
    ctx.restore();
  }
};

function drawSelectionHandles(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: Drawing) {
  ctx.save();
  
  // Handle style
  const handleSize = 6;
  const handleColor = '#ff6b35';
  const handleBorderColor = '#fff';
  
  ctx.fillStyle = handleColor;
  ctx.strokeStyle = handleBorderColor;
  ctx.lineWidth = 2;
  
  // Draw handles at key points
  drawing.points.forEach(point => {
    const canvasPoint = converter.chartToCanvas(point);
    
    // Draw handle (small circle)
    ctx.beginPath();
    ctx.arc(canvasPoint.x, canvasPoint.y, handleSize, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
  });
  
  // For rectangles, also draw handles at corners if we have two points
  if (drawing.type === 'rectangle' && drawing.points.length === 2) {
    const topLeft = drawing.points[0];
    const bottomRight = drawing.points[1];
    
    const topRight = { x: bottomRight.x, y: topLeft.y };
    const bottomLeft = { x: topLeft.x, y: bottomRight.y };
    
    [topRight, bottomLeft].forEach(point => {
      const canvasPoint = converter.chartToCanvas(point);
      ctx.beginPath();
      ctx.arc(canvasPoint.x, canvasPoint.y, handleSize, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    });
  }
  
  ctx.restore();
}

function drawDrawing(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: Drawing) {
  const style = { ...DEFAULT_DRAWING_STYLES[drawing.type], ...drawing.style };
  
  // Apply selection styling for selected drawings
  const isSelected = drawing.selected;
  const selectionColor = '#ff6b35'; // Orange selection color
  
  // Apply common styles with selection modifications
  ctx.strokeStyle = isSelected ? selectionColor : (style.color || '#2196F3');
  ctx.lineWidth = (style.width || 1) + (isSelected ? 2 : 0); // Thicker when selected
  ctx.globalAlpha = style.opacity || 1;
  
  if (style.lineDash && !isSelected) {
    ctx.setLineDash(style.lineDash);
  } else {
    ctx.setLineDash(isSelected ? [8, 4] : []); // Dashed when selected, or solid
  }

  // Add selection glow effect
  if (isSelected) {
    ctx.shadowColor = selectionColor;
    ctx.shadowBlur = 6;
  }

  switch (drawing.type) {
    case 'trendline':
      drawTrendline(ctx, converter, drawing as TrendlineDrawing);
      break;
    case 'horizontal-line':
      drawHorizontalLine(ctx, converter, drawing as HorizontalLineDrawing);
      break;
    case 'vertical-line':
      drawVerticalLine(ctx, converter, drawing as VerticalLineDrawing);
      break;
    case 'rectangle':
      drawRectangle(ctx, converter, drawing as RectangleDrawing);
      break;
    case 'text':
      drawText(ctx, converter, drawing as TextDrawing, style);
      break;
  }

  // Reset shadow
  ctx.shadowBlur = 0;
}

function drawTrendline(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: TrendlineDrawing) {
  if (drawing.points.length < 2) return;
  
  const start = converter.chartToCanvas(drawing.points[0]);
  const end = converter.chartToCanvas(drawing.points[1]);
  
  ctx.beginPath();
  ctx.moveTo(start.x, start.y);
  ctx.lineTo(end.x, end.y);
  ctx.stroke();
  
  // Draw control points with selection state
  drawControlPoint(ctx, start, drawing.selected);
  drawControlPoint(ctx, end, drawing.selected);
}

function drawHorizontalLine(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: HorizontalLineDrawing) {
  if (drawing.points.length < 1) return;
  
  const point = converter.chartToCanvas(drawing.points[0]);
  const chartArea = converter.chart.chartArea;
  
  ctx.beginPath();
  ctx.moveTo(chartArea.left, point.y);
  ctx.lineTo(chartArea.right, point.y);
  ctx.stroke();
  
  // Draw price label
  drawPriceLabel(ctx, { x: chartArea.right - 5, y: point.y }, drawing.points[0].y);
}

function drawVerticalLine(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: VerticalLineDrawing) {
  if (drawing.points.length < 1) return;
  
  const point = converter.chartToCanvas(drawing.points[0]);
  const chartArea = converter.chart.chartArea;
  
  ctx.beginPath();
  ctx.moveTo(point.x, chartArea.top);
  ctx.lineTo(point.x, chartArea.bottom);
  ctx.stroke();
  
  // Draw time label
  drawTimeLabel(ctx, { x: point.x, y: chartArea.bottom + 5 }, drawing.points[0].x);
}

function drawRectangle(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: RectangleDrawing) {
  if (drawing.points.length < 2) return;
  
  const start = converter.chartToCanvas(drawing.points[0]);
  const end = converter.chartToCanvas(drawing.points[1]);
  
  const x = Math.min(start.x, end.x);
  const y = Math.min(start.y, end.y);
  const width = Math.abs(end.x - start.x);
  const height = Math.abs(end.y - start.y);
  
  // Draw rectangle outline
  ctx.beginPath();
  ctx.rect(x, y, width, height);
  ctx.stroke();
  
  // Draw filled rectangle with low opacity
  const fillStyle = ctx.strokeStyle;
  ctx.fillStyle = fillStyle;
  ctx.globalAlpha = 0.1;
  ctx.fill();
  ctx.globalAlpha = drawing.style?.opacity || 1;
  
  // Draw control points with selection state
  drawControlPoint(ctx, start, drawing.selected);
  drawControlPoint(ctx, end, drawing.selected);
  
  // Draw corner handles for selected rectangles
  if (drawing.selected) {
    const topLeft = { x, y };
    const topRight = { x: x + width, y };
    const bottomLeft = { x, y: y + height };
    const bottomRight = { x: x + width, y: y + height };
    
    drawControlPoint(ctx, topLeft, true);
    drawControlPoint(ctx, topRight, true);
    drawControlPoint(ctx, bottomLeft, true);
    drawControlPoint(ctx, bottomRight, true);
  }
}

function drawText(ctx: CanvasRenderingContext2D, converter: CoordinateConverter, drawing: TextDrawing, style: Partial<DrawingStyle>) {
  if (drawing.points.length < 1) return;
  
  const point = converter.chartToCanvas(drawing.points[0]);
  const text = drawing.text || '';
  const formatting = drawing.formatting;
  
  // Use formatting if available, otherwise fall back to style defaults
  const fontSize = formatting?.fontSize || style.fontSize || 14;
  const fontFamily = formatting?.fontFamily || 'Arial';
  const fontWeight = formatting?.bold ? 'bold' : 'normal';
  const fontStyle = formatting?.italic ? 'italic' : 'normal';
  const textColor = drawing.selected ? '#ff6b35' : (formatting?.color || style.textColor || style.color || '#ffffff');
  const textAlign = formatting?.textAlign || 'center';
  
  // Set font properties
  ctx.font = `${fontStyle} ${fontWeight} ${fontSize}px ${fontFamily}`;
  ctx.textAlign = textAlign;
  ctx.textBaseline = 'bottom';
  
  // If there's text to display
  if (text) {
    // Draw text background if specified
    if (formatting?.backgroundColor && formatting.backgroundColor !== 'transparent') {
      const textMetrics = ctx.measureText(text);
      const textWidth = textMetrics.width;
      const textHeight = fontSize;
      
      let bgX = point.x;
      if (textAlign === 'left') bgX = point.x;
      else if (textAlign === 'center') bgX = point.x - textWidth / 2;
      else if (textAlign === 'right') bgX = point.x - textWidth;
      
      ctx.fillStyle = formatting.backgroundColor;
      ctx.fillRect(
        bgX - 4,
        point.y - textHeight - 4,
        textWidth + 8,
        textHeight + 8
      );
    } else if (!formatting?.backgroundColor || formatting.backgroundColor === 'transparent') {
      // Default semi-transparent background for readability
      const textMetrics = ctx.measureText(text);
      const textWidth = textMetrics.width;
      const textHeight = fontSize;
      
      let bgX = point.x;
      if (textAlign === 'left') bgX = point.x;
      else if (textAlign === 'center') bgX = point.x - textWidth / 2;
      else if (textAlign === 'right') bgX = point.x - textWidth;
      
      const bgColor = drawing.selected ? 'rgba(255, 107, 53, 0.2)' : 'rgba(0, 0, 0, 0.7)';
      ctx.fillStyle = bgColor;
      ctx.fillRect(
        bgX - 4,
        point.y - textHeight - 4,
        textWidth + 8,
        textHeight + 8
      );
    }
    
    // Draw border if specified
    if (formatting?.hasBorder) {
      const textMetrics = ctx.measureText(text);
      const textWidth = textMetrics.width;
      const textHeight = fontSize;
      
      let borderX = point.x;
      if (textAlign === 'left') borderX = point.x;
      else if (textAlign === 'center') borderX = point.x - textWidth / 2;
      else if (textAlign === 'right') borderX = point.x - textWidth;
      
      ctx.strokeStyle = textColor;
      ctx.lineWidth = 1;
      ctx.setLineDash([]);
      ctx.strokeRect(
        borderX - 4,
        point.y - textHeight - 4,
        textWidth + 8,
        textHeight + 8
      );
    }
    
    // Draw text
    ctx.fillStyle = textColor;
    ctx.fillText(text, point.x, point.y - 4);
  } else if (drawing.selected) {
    // For empty text drawings, show a placeholder outline when selected
    ctx.strokeStyle = '#ff6b35';
    ctx.setLineDash([4, 4]);
    ctx.lineWidth = 1;
    ctx.strokeRect(
      point.x - 30,
      point.y - 16,
      60,
      16
    );
    ctx.setLineDash([]);
    
    // Draw placeholder text
    ctx.fillStyle = 'rgba(255, 107, 53, 0.6)';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'bottom';
    ctx.font = `${fontSize}px ${fontFamily}`;
    ctx.fillText('Text', point.x, point.y - 4);
  }
  
  // Draw control point with selection state
  drawControlPoint(ctx, point, drawing.selected);
}

function drawControlPoint(ctx: CanvasRenderingContext2D, point: { x: number; y: number }, isSelected: boolean = false) {
  ctx.save();
  
  if (isSelected) {
    // Selected control points are larger and orange
    ctx.fillStyle = '#ffffff';
    ctx.strokeStyle = '#ff6b35';
    ctx.lineWidth = 3;
    ctx.setLineDash([]);
    
    // Draw selection handle as a square
    ctx.beginPath();
    ctx.rect(point.x - 5, point.y - 5, 10, 10);
    ctx.fill();
    ctx.stroke();
    
    // Add inner dot
    ctx.fillStyle = '#ff6b35';
    ctx.beginPath();
    ctx.arc(point.x, point.y, 2, 0, 2 * Math.PI);
    ctx.fill();
  } else {
    // Normal control points
    ctx.fillStyle = '#ffffff';
    ctx.strokeStyle = '#2196F3';
    ctx.lineWidth = 2;
    ctx.setLineDash([]);
    
    ctx.beginPath();
    ctx.arc(point.x, point.y, 4, 0, 2 * Math.PI);
    ctx.fill();
    ctx.stroke();
  }
  
  ctx.restore();
}

function drawPriceLabel(ctx: CanvasRenderingContext2D, point: { x: number; y: number }, price: number) {
  const text = `$${price.toFixed(2)}`;
  
  ctx.save();
  ctx.font = '11px Arial';
  ctx.textAlign = 'right';
  ctx.textBaseline = 'middle';
  
  const textMetrics = ctx.measureText(text);
  const textWidth = textMetrics.width;
  const textHeight = 11;
  
  // Draw background
  ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
  ctx.fillRect(point.x - textWidth - 8, point.y - textHeight / 2 - 2, textWidth + 6, textHeight + 4);
  
  // Draw text
  ctx.fillStyle = '#ffffff';
  ctx.fillText(text, point.x - 4, point.y);
  
  ctx.restore();
}

function drawTimeLabel(ctx: CanvasRenderingContext2D, point: { x: number; y: number }, timestamp: number) {
  const date = new Date(timestamp);
  const text = date.toLocaleDateString();
  
  ctx.save();
  ctx.font = '11px Arial';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  
  const textMetrics = ctx.measureText(text);
  const textWidth = textMetrics.width;
  const textHeight = 11;
  
  // Draw background
  ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
  ctx.fillRect(point.x - textWidth / 2 - 3, point.y, textWidth + 6, textHeight + 4);
  
  // Draw text
  ctx.fillStyle = '#ffffff';
  ctx.fillText(text, point.x, point.y + 2);
  
  ctx.restore();
}