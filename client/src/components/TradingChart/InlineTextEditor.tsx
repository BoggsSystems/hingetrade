import React, { useState, useEffect, useRef, useCallback } from 'react';
import styles from './InlineTextEditor.module.css';
import TextFormattingToolbar, { type TextFormatting } from './TextFormattingToolbar';

interface InlineTextEditorProps {
  position: { x: number; y: number };
  initialText: string;
  initialFormatting?: Partial<TextFormatting>;
  onSave: (text: string, formatting: TextFormatting) => void;
  onCancel: () => void;
}

const InlineTextEditor: React.FC<InlineTextEditorProps> = ({
  position,
  initialText,
  initialFormatting,
  onSave,
  onCancel
}) => {
  const [text, setText] = useState(initialText);
  const inputRef = useRef<HTMLInputElement>(null);

  // Default formatting options
  const defaultFormatting: TextFormatting = {
    fontSize: 14,
    fontFamily: 'Arial',
    color: '#ffffff',
    backgroundColor: 'transparent',
    bold: false,
    italic: false,
    textAlign: 'center',
    hasBorder: false,
    ...initialFormatting
  };

  const [formatting, setFormatting] = useState<TextFormatting>(defaultFormatting);

  // Auto-focus the input when component mounts
  useEffect(() => {
    // Use a small delay to ensure the component is fully rendered
    const focusTimeout = setTimeout(() => {
      if (inputRef.current) {
        inputRef.current.focus();
        if (initialText) {
          inputRef.current.select(); // Select all text if editing existing text
        }
      }
    }, 50); // Small delay to ensure DOM is ready

    return () => clearTimeout(focusTimeout);
  }, [initialText]);

  // Handle keyboard events
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      onSave(text, formatting);
    } else if (e.key === 'Escape') {
      e.preventDefault();
      onCancel();
    }
  }, [text, formatting, onSave, onCancel]);

  // Track if this is a new text element (to prevent immediate blur removal)
  const isNewText = initialText === '';
  const [hasUserInteracted, setHasUserInteracted] = useState(false);

  // Handle input change
  const handleChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setText(e.target.value);
    if (!hasUserInteracted) {
      setHasUserInteracted(true);
    }
  }, [hasUserInteracted]);

  // Handle clicks outside the editor to close it
  useEffect(() => {
    const handleDocumentClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      
      // Check if click is inside text input
      if (inputRef.current?.contains(target)) {
        return; // Don't close if clicking in input
      }
      
      // Check if click is inside toolbar
      const toolbar = document.querySelector('.text-formatting-toolbar');
      if (toolbar?.contains(target)) {
        return; // Don't close if clicking in toolbar
      }
      
      // Check if click is on dropdown-related elements
      if (target.tagName === 'OPTION' || 
          target.tagName === 'SELECT' || 
          target.closest('select') ||
          // Color picker inputs
          target.type === 'color') {
        return; // Don't close if interacting with form controls
      }
      
      // Clicked outside - close the editor
      if (isNewText && !hasUserInteracted) {
        onCancel(); // Cancel instead of saving empty text
      } else {
        onSave(text, formatting);
      }
    };

    // Add event listener
    document.addEventListener('mousedown', handleDocumentClick);
    
    return () => {
      document.removeEventListener('mousedown', handleDocumentClick);
    };
  }, [text, formatting, onSave, onCancel, isNewText, hasUserInteracted]);

  // Simplified blur handler - no longer needed for closing logic
  const handleBlur = useCallback(() => {
    // Just prevent default blur behavior, closing is handled by document click
  }, []);

  // Prevent mouse events from bubbling to the canvas
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
  }, []);

  // Handle toolbar apply button
  const handleToolbarApply = useCallback(() => {
    onSave(text, formatting);
  }, [text, formatting, onSave]);

  // Handle toolbar cancel button
  const handleToolbarCancel = useCallback(() => {
    onCancel();
  }, [onCancel]);

  // Calculate input style based on formatting
  const inputStyle = {
    fontSize: `${formatting.fontSize}px`,
    fontFamily: formatting.fontFamily,
    color: formatting.color,
    backgroundColor: formatting.backgroundColor === 'transparent' ? 'rgba(0, 0, 0, 0.9)' : formatting.backgroundColor,
    fontWeight: formatting.bold ? 'bold' : 'normal',
    fontStyle: formatting.italic ? 'italic' : 'normal',
    textAlign: formatting.textAlign,
    border: formatting.hasBorder ? `2px solid ${formatting.color}` : '2px solid #ff6b35',
  };

  return (
    <>
      {/* Text Formatting Toolbar */}
      <TextFormattingToolbar
        formatting={formatting}
        onChange={setFormatting}
        onApply={handleToolbarApply}
        onCancel={handleToolbarCancel}
        position={position}
      />

      {/* Text Input */}
      <div
        className={styles.textEditor}
        style={{
          position: 'absolute',
          left: position.x - 60, // Center the input around the click point
          top: position.y - 15, // Position slightly above the click point
          zIndex: 1000,
        }}
        onMouseDown={handleMouseDown}
      >
        <input
          ref={inputRef}
          type="text"
          value={text}
          onChange={handleChange}
          onKeyDown={handleKeyDown}
          onBlur={handleBlur}
          className={styles.textInput}
          style={inputStyle}
          placeholder="Enter text..."
          maxLength={100} // Reasonable limit for chart annotations
        />
      </div>
    </>
  );
};

export default InlineTextEditor;