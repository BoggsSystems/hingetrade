import React, { useCallback, useMemo, useState, useEffect } from 'react';
import GridLayout from 'react-grid-layout';
import type { Layout as GridLayoutItem } from 'react-grid-layout';
import useLayoutStore, { useActiveLayout } from '../../store/layoutStore';
import PanelWrapper from './PanelWrapper';
import type { Panel } from '../../types/layout';
import 'react-grid-layout/css/styles.css';
import './LayoutContainer.css';

const LayoutContainer: React.FC = () => {
  const [containerWidth, setContainerWidth] = useState(1200);
  const containerRef = React.useRef<HTMLDivElement>(null);

  useEffect(() => {
    const updateWidth = () => {
      if (containerRef.current) {
        setContainerWidth(containerRef.current.offsetWidth);
      }
    };

    updateWidth();
    window.addEventListener('resize', updateWidth);
    return () => window.removeEventListener('resize', updateWidth);
  }, []);
  const { updatePanelPositions } = useLayoutStore();
  const activeLayout = useActiveLayout();

  const gridLayouts: GridLayoutItem[] = useMemo(() => {
    if (!activeLayout) return [];
    
    return activeLayout.panels.map(panel => ({
      i: panel.id,
      x: panel.position.x,
      y: panel.position.y,
      w: panel.position.w,
      h: panel.position.h,
      minW: panel.position.minW,
      minH: panel.position.minH,
      maxW: panel.position.maxW,
      maxH: panel.position.maxH,
      static: panel.position.static,
    }));
  }, [activeLayout]);

  const handleLayoutChange = useCallback((layout: GridLayoutItem[]) => {
    const positions = layout.map(item => ({
      i: item.i,
      x: item.x,
      y: item.y,
      w: item.w,
      h: item.h,
    }));
    updatePanelPositions(positions);
  }, [updatePanelPositions]);

  if (!activeLayout) {
    return (
      <div className="layout-container-empty">
        <h2>No Layout Selected</h2>
        <p>Create a new layout to get started</p>
      </div>
    );
  }

  const { cols, rowHeight, margin, containerPadding, compactType } = activeLayout.gridConfig;

  return (
    <div className="layout-container" ref={containerRef}>
      <GridLayout
        className="grid-layout"
        layout={gridLayouts}
        cols={cols}
        rowHeight={rowHeight}
        width={containerWidth}
        margin={margin}
        containerPadding={containerPadding}
        compactType={compactType}
        isDraggable={true}
        isResizable={true}
        onLayoutChange={handleLayoutChange}
        draggableHandle=".panel-drag-handle"
        resizeHandles={['s', 'e', 'se']}
      >
        {activeLayout.panels.map((panel: Panel) => (
          <div key={panel.id} className="grid-item">
            <PanelWrapper panel={panel} />
          </div>
        ))}
      </GridLayout>
    </div>
  );
};

export default LayoutContainer;