import React from 'react';
import type { DrawingTool } from './types';
import styles from './DrawingToolbar.module.css';

interface DrawingToolbarProps {
  activeTool: DrawingTool;
  onToolSelect: (tool: DrawingTool) => void;
  onClearAll: () => void;
  disabled?: boolean;
  drawingsCount?: number;
  selectedDrawingId?: string | null;
}

// SVG Icons for drawing tools
const TrendlineIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <path d="M2 12L14 4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
    <circle cx="2" cy="12" r="1.5" fill="currentColor"/>
    <circle cx="14" cy="4" r="1.5" fill="currentColor"/>
  </svg>
);

const HorizontalLineIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <path d="M2 8L14 8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
    <path d="M2 6L2 10" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
    <path d="M14 6L14 10" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
  </svg>
);

const VerticalLineIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <path d="M8 2L8 14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
    <path d="M6 2L10 2" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
    <path d="M6 14L10 14" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/>
  </svg>
);

const RectangleIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <rect x="3" y="5" width="10" height="6" stroke="currentColor" strokeWidth="1.5" fill="none"/>
    <circle cx="3" cy="5" r="1" fill="currentColor"/>
    <circle cx="13" cy="11" r="1" fill="currentColor"/>
  </svg>
);

const TextIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <path d="M4 3h8M8 3v10M6 13h4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
  </svg>
);

const ClearIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <path d="M12 4L4 12M4 4l8 8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/>
  </svg>
);

const CursorIcon: React.FC<{ size?: number }> = ({ size = 16 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none">
    <path d="M3 3L13 8L8 9L7 13L3 3Z" stroke="currentColor" strokeWidth="1.5" fill="currentColor" fillOpacity="0.1"/>
  </svg>
);

const DrawingToolbar: React.FC<DrawingToolbarProps> = ({
  activeTool,
  onToolSelect,
  onClearAll,
  disabled = false,
  drawingsCount = 0,
  selectedDrawingId = null
}) => {
  const tools = [
    { id: 'none' as DrawingTool, label: 'Select', Icon: CursorIcon },
    { id: 'trendline' as DrawingTool, label: 'Trendline', Icon: TrendlineIcon },
    { id: 'horizontal-line' as DrawingTool, label: 'Horizontal Line', Icon: HorizontalLineIcon },
    { id: 'vertical-line' as DrawingTool, label: 'Vertical Line', Icon: VerticalLineIcon },
    { id: 'rectangle' as DrawingTool, label: 'Rectangle', Icon: RectangleIcon },
    { id: 'text' as DrawingTool, label: 'Text', Icon: TextIcon },
  ];

  const activeToolLabel = tools.find(tool => tool.id === activeTool)?.label || 'Select';
  const isDrawingActive = activeTool !== 'none';
  const hasSelection = selectedDrawingId !== null;

  const getStatusMessage = () => {
    if (isDrawingActive) {
      return `${activeToolLabel} Mode - Click to draw, ESC to cancel`;
    }
    if (hasSelection) {
      return 'Drawing selected - Press Delete to remove, click elsewhere to deselect';
    }
    if (drawingsCount > 0) {
      return 'Select Mode - Click on drawings to select them';
    }
    return 'Select Mode - No drawings on chart';
  };

  const showStatus = isDrawingActive || hasSelection || drawingsCount > 0;

  return (
    <div className={styles.toolbar}>
      <div className={styles.drawingToolsContainer}>
        <select
          className={styles.drawingToolsSelect}
          value={activeTool}
          onChange={(e) => onToolSelect(e.target.value as DrawingTool)}
          disabled={disabled}
        >
          <optgroup label="Drawing Tools">
            {tools.map(({ id, label }) => (
              <option key={id} value={id}>
                {label}
              </option>
            ))}
          </optgroup>
        </select>
        
        {drawingsCount > 0 && (
          <span className={styles.drawingCount} title={`${drawingsCount} drawing${drawingsCount === 1 ? '' : 's'} on chart`}>
            {drawingsCount}
          </span>
        )}
        
        <button
          className={styles.clearButton}
          onClick={onClearAll}
          disabled={disabled || drawingsCount === 0}
          title={drawingsCount === 0 ? "No drawings to clear" : `Clear all ${drawingsCount} drawings`}
        >
          <ClearIcon size={16} />
          <span className={styles.clearLabel}>Clear</span>
        </button>
      </div>
      
      {showStatus && (
        <div className={`${styles.statusIndicator} ${hasSelection ? styles.selectionMode : ''} ${isDrawingActive ? styles.drawingMode : ''}`}>
          <span className={styles.statusText}>
            {getStatusMessage()}
          </span>
        </div>
      )}
    </div>
  );
};

export default DrawingToolbar;