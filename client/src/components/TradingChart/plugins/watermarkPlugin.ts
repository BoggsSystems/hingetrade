import type { Chart, Plugin } from 'chart.js';

export interface WatermarkOptions {
  text: string;
  fontSize?: number;
  fontFamily?: string;
  color?: string;
  opacity?: number;
}

export const watermarkPlugin: Plugin<'line' | 'bar', WatermarkOptions> = {
  id: 'watermark',
  
  beforeDraw(chart: Chart, args: any, options: any) {
    // Options might be nested under the plugin namespace
    const watermarkOptions = options as WatermarkOptions;
    if (!watermarkOptions?.text) return;
    
    const { ctx, chartArea } = chart;
    if (!chartArea) return;
    
    const { left, right, top, bottom } = chartArea;
    const centerX = (left + right) / 2;
    const centerY = (top + bottom) / 2;
    
    ctx.save();
    
    // Set watermark style
    const fontSize = watermarkOptions.fontSize || Math.min(chartArea.width, chartArea.height) * 0.15;
    const fontFamily = watermarkOptions.fontFamily || 'Arial, sans-serif';
    const color = watermarkOptions.color || '#ffffff';
    const opacity = watermarkOptions.opacity || 0.08;
    
    ctx.font = `bold ${fontSize}px ${fontFamily}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = color;
    ctx.globalAlpha = opacity;
    
    // Draw the watermark text
    ctx.fillText(watermarkOptions.text.toUpperCase(), centerX, centerY);
    
    ctx.restore();
  }
};