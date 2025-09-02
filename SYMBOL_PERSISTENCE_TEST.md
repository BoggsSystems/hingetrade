# Symbol Persistence Test Plan

## Implementation Summary

Symbol persistence for Quote panels has been implemented with the following components:

### Frontend Changes
1. **QuotePanel.tsx**: Enhanced symbol initialization and persistence
   - Initializes from `config.symbol` on mount
   - Saves symbol changes via `onConfigChange({ symbol: newSymbol })`
   - Properly syncs with saved configuration

2. **Layout System**: Already supports panel config persistence
   - `PanelConfig` type includes `symbol?: string` field
   - `LayoutStore` handles config updates and triggers backend saves
   - `PanelWrapper` passes `onConfigChange` to panels

### Backend Support
1. **Database Model**: `Panel.ConfigJson` stores symbol data
2. **LayoutsService**: Serializes/deserializes panel configs including symbol
3. **API Endpoints**: Handle panel config updates through layout saves

## Testing Steps

### Manual Test Scenario:
1. Start the application
2. Create or open a layout
3. Add a Quote panel
4. Set symbol to "AAPL" and verify quote data loads
5. Save the layout (should auto-save when symbol changes)
6. Close the application
7. Restart the application
8. Open the same layout
9. ✅ **Expected Result**: Quote panel should show "AAPL" symbol and load data automatically

### Integration Points:
- ✅ `QuotePanel` initializes from `config.symbol`
- ✅ `QuotePanel` calls `onConfigChange` when symbol changes  
- ✅ `PanelWrapper` handles config changes and updates layout store
- ✅ `LayoutStore` triggers backend saves with panel configs
- ✅ Backend stores configs in `Panel.ConfigJson` database field
- ✅ Backend returns configs when layouts are loaded
- ✅ Frontend restores panels with saved configurations

## Key Implementation Details:

### Symbol Priority Order:
```typescript
const symbol = propSymbol || localSymbol || config.symbol;
```

### Configuration Save Flow:
```
User enters symbol → handleSymbolSubmit → onConfigChange({ symbol }) → 
PanelWrapper.handleConfigChange → LayoutStore.updatePanel → 
Backend API → Database Panel.ConfigJson
```

### Configuration Load Flow:  
```
App startup → Load layout → Panel configs with symbols → 
QuotePanel initialization → useEffect syncs config.symbol → 
Symbol displayed and market data subscribed
```

The implementation leverages the existing robust layout persistence system and requires no database schema changes.