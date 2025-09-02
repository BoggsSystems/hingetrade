import React, { useState, useCallback } from 'react';
import styles from './TextFormattingToolbar.module.css';

export interface TextFormatting {
  fontSize: number;
  fontFamily: string;
  color: string;
  backgroundColor: string;
  bold: boolean;
  italic: boolean;
  textAlign: 'left' | 'center' | 'right';
  hasBorder: boolean;
}

interface TextFormattingToolbarProps {
  formatting: TextFormatting;
  onChange: (formatting: TextFormatting) => void;
  onApply: () => void;
  onCancel: () => void;
  position: { x: number; y: number };
}

const FONT_SIZES = [10, 12, 14, 16, 18, 20, 24, 28, 32];
const FONT_FAMILIES = [
  'Arial',
  'Helvetica',
  'Times New Roman',
  'Courier New',
  'Georgia',
  'Verdana'
];

const PRESET_COLORS = [
  '#ffffff', '#000000', '#ff6b35', '#4CAF50', '#2196F3', 
  '#FFC107', '#9C27B0', '#FF5722', '#607D8B', '#795548'
];

const TextFormattingToolbar: React.FC<TextFormattingToolbarProps> = ({
  formatting,
  onChange,
  onApply,
  onCancel,
  position
}) => {
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [showBgColorPicker, setShowBgColorPicker] = useState(false);

  // Calculate smart positioning to avoid blocking text
  const getSmartPosition = () => {
    const toolbarWidth = 320;
    const toolbarHeight = 85;
    const margin = 30;
    const inputOffset = 100; // Distance from text input

    // Default: try to position above and centered
    let left = position.x - toolbarWidth / 2;
    let top = position.y - toolbarHeight - margin;
    let placement = 'above';

    // Check if toolbar would go off screen edges
    const wouldGoOffTop = top < 20;
    const wouldGoOffLeft = left < 20;
    const wouldGoOffRight = left + toolbarWidth > window.innerWidth - 20;
    const wouldGoOffBottom = top + toolbarHeight > window.innerHeight - 20;

    // If can't fit above, try positioning to the side
    if (wouldGoOffTop || wouldGoOffBottom) {
      // Try right side first
      if (position.x + inputOffset + toolbarWidth < window.innerWidth - 20) {
        left = position.x + inputOffset;
        top = position.y - toolbarHeight / 2;
        placement = 'right';
      }
      // If right doesn't work, try left side
      else if (position.x - inputOffset - toolbarWidth > 20) {
        left = position.x - inputOffset - toolbarWidth;
        top = position.y - toolbarHeight / 2;
        placement = 'left';
      }
      // If neither side works, position below
      else {
        left = position.x - toolbarWidth / 2;
        top = position.y + 40; // Below the text input
        placement = 'below';
      }
    }

    // Final bounds checking
    if (left < 20) left = 20;
    if (left + toolbarWidth > window.innerWidth - 20) {
      left = window.innerWidth - toolbarWidth - 20;
    }
    if (top < 20) top = 20;
    if (top + toolbarHeight > window.innerHeight - 20) {
      top = window.innerHeight - toolbarHeight - 20;
    }

    return { left, top, placement };
  };

  const smartPosition = getSmartPosition();

  const updateFormatting = useCallback((updates: Partial<TextFormatting>) => {
    onChange({ ...formatting, ...updates });
  }, [formatting, onChange]);

  const handleColorSelect = useCallback((color: string) => {
    updateFormatting({ color });
    // Small delay to ensure the click event finishes processing
    setTimeout(() => setShowColorPicker(false), 0);
  }, [updateFormatting]);

  const handleBgColorSelect = useCallback((backgroundColor: string) => {
    updateFormatting({ backgroundColor });
    // Small delay to ensure the click event finishes processing
    setTimeout(() => setShowBgColorPicker(false), 0);
  }, [updateFormatting]);

  // Prevent toolbar clicks from bubbling to canvas (except for select elements)
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    // Don't stop propagation for select elements - they need their events
    if (e.target instanceof HTMLSelectElement) {
      return;
    }
    e.stopPropagation();
  }, []);

  return (
    <div
      className={`${styles.toolbar} text-formatting-toolbar`}
      style={{
        position: 'absolute',
        left: smartPosition.left,
        top: smartPosition.top,
        zIndex: 1002
      }}
      onMouseDown={handleMouseDown}
    >
      <div className={styles.toolbarRow}>
        {/* Font Family */}
        <select
          className={styles.fontSelect}
          value={formatting.fontFamily}
          onChange={(e) => updateFormatting({ fontFamily: e.target.value })}
        >
          {FONT_FAMILIES.map(font => (
            <option key={font} value={font}>{font}</option>
          ))}
        </select>

        {/* Font Size */}
        <select
          className={styles.sizeSelect}
          value={formatting.fontSize}
          onChange={(e) => updateFormatting({ fontSize: parseInt(e.target.value) })}
        >
          {FONT_SIZES.map(size => (
            <option key={size} value={size}>{size}px</option>
          ))}
        </select>

        {/* Bold */}
        <button
          className={`${styles.formatButton} ${formatting.bold ? styles.active : ''}`}
          onClick={() => updateFormatting({ bold: !formatting.bold })}
          title="Bold"
        >
          <strong>B</strong>
        </button>

        {/* Italic */}
        <button
          className={`${styles.formatButton} ${formatting.italic ? styles.active : ''}`}
          onClick={() => updateFormatting({ italic: !formatting.italic })}
          title="Italic"
        >
          <em>I</em>
        </button>

        {/* Text Color */}
        <div className={styles.colorPickerContainer}>
          <button
            className={styles.colorButton}
            onClick={() => setShowColorPicker(!showColorPicker)}
            title="Text Color"
          >
            <span className={styles.colorPreview} style={{ backgroundColor: formatting.color }}>A</span>
          </button>
          {showColorPicker && (
            <div className={styles.colorPalette}>
              {PRESET_COLORS.map(color => (
                <button
                  key={color}
                  className={styles.colorSwatch}
                  style={{ backgroundColor: color }}
                  onClick={() => handleColorSelect(color)}
                />
              ))}
              <input
                type="color"
                value={formatting.color}
                onChange={(e) => handleColorSelect(e.target.value)}
                className={styles.customColorPicker}
              />
            </div>
          )}
        </div>

        {/* Background Color */}
        <div className={styles.colorPickerContainer}>
          <button
            className={styles.colorButton}
            onClick={() => setShowBgColorPicker(!showBgColorPicker)}
            title="Background Color"
          >
            <span className={styles.colorPreview} style={{ backgroundColor: formatting.backgroundColor || 'transparent' }}>■</span>
          </button>
          {showBgColorPicker && (
            <div className={styles.colorPalette}>
              <button
                className={styles.colorSwatch}
                style={{ backgroundColor: 'transparent', border: '1px solid #ccc' }}
                onClick={() => handleBgColorSelect('transparent')}
                title="Transparent"
              >
                ∅
              </button>
              {PRESET_COLORS.map(color => (
                <button
                  key={color}
                  className={styles.colorSwatch}
                  style={{ backgroundColor: color }}
                  onClick={() => handleBgColorSelect(color)}
                />
              ))}
              <input
                type="color"
                value={formatting.backgroundColor === 'transparent' ? '#000000' : formatting.backgroundColor}
                onChange={(e) => handleBgColorSelect(e.target.value)}
                className={styles.customColorPicker}
              />
            </div>
          )}
        </div>

        {/* Text Alignment */}
        <div className={styles.alignmentGroup}>
          {['left', 'center', 'right'].map((align) => (
            <button
              key={align}
              className={`${styles.formatButton} ${formatting.textAlign === align ? styles.active : ''}`}
              onClick={() => updateFormatting({ textAlign: align as 'left' | 'center' | 'right' })}
              title={`Align ${align}`}
            >
              {align === 'left' && '◀'}
              {align === 'center' && '▣'}
              {align === 'right' && '▶'}
            </button>
          ))}
        </div>

        {/* Border Toggle */}
        <button
          className={`${styles.formatButton} ${formatting.hasBorder ? styles.active : ''}`}
          onClick={() => updateFormatting({ hasBorder: !formatting.hasBorder })}
          title="Border"
        >
          ◯
        </button>
      </div>

      <div className={styles.actionRow}>
        {/* Apply Button */}
        <button className={`${styles.actionButton} ${styles.applyButton}`} onClick={onApply}>
          ✓ Apply
        </button>

        {/* Cancel Button */}
        <button className={`${styles.actionButton} ${styles.cancelButton}`} onClick={onCancel}>
          ✕ Cancel
        </button>
      </div>
    </div>
  );
};

export default TextFormattingToolbar;