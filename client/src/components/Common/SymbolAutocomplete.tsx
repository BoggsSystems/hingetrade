import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useDebounce } from '../../hooks/useDebounce';
import { useAuth } from '../../contexts/AuthContext';
import styles from './SymbolAutocomplete.module.css';

interface SymbolSuggestion {
  symbol: string;
  name: string;
  type: string;
  currency: string;
}

interface SymbolAutocompleteProps {
  onSymbolSelect: (symbol: string) => void;
  placeholder?: string;
  className?: string;
  autoFocus?: boolean;
  mode?: 'immediate' | 'populate'; // 'immediate' = old behavior, 'populate' = new behavior
  value?: string; // Optional external value to display
}

const SymbolAutocomplete: React.FC<SymbolAutocompleteProps> = ({
  onSymbolSelect,
  placeholder = 'Add symbol...',
  className = '',
  autoFocus = false,
  mode = 'immediate',
  value = '',
}) => {
  const [inputValue, setInputValue] = useState(value);
  const [suggestions, setSuggestions] = useState<SymbolSuggestion[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  
  const { getAccessToken } = useAuth();
  const inputRef = useRef<HTMLInputElement>(null);
  const suggestionsRef = useRef<HTMLDivElement>(null);
  const debouncedSearchTerm = useDebounce(inputValue, 300);

  // Update internal input value when external value prop changes
  useEffect(() => {
    if (value !== inputValue) {
      setInputValue(value || '');
    }
  }, [value]);

  // Fetch suggestions from API
  const fetchSuggestions = useCallback(async (query: string) => {
    if (query.length < 2) {
      setSuggestions([]);
      return;
    }

    setIsLoading(true);
    
    try {
      const apiBaseUrl = import.meta.env.VITE_API_URL || 'http://localhost:5001/api';
      const token = await getAccessToken();
      
      if (!token) {
        console.error('No access token available for symbol search');
        setSuggestions([]);
        return;
      }
      
      const url = `${apiBaseUrl}/symbols/search?query=${encodeURIComponent(query)}`;
      
      const response = await fetch(url, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        
        if (data.symbols && Array.isArray(data.symbols)) {
          setSuggestions(data.symbols);
        } else {
          setSuggestions([]);
        }
      } else {
        console.error('Symbol search failed:', response.status, response.statusText);
        setSuggestions([]);
      }
    } catch (error) {
      console.error('Error fetching symbol suggestions:', error);
      setSuggestions([]);
    } finally {
      setIsLoading(false);
    }
  }, [getAccessToken]);

  // Effect to fetch suggestions when debounced search term changes
  useEffect(() => {
    if (debouncedSearchTerm) {
      fetchSuggestions(debouncedSearchTerm);
    } else {
      setSuggestions([]);
    }
  }, [debouncedSearchTerm, fetchSuggestions]);

  // Handle click outside to close suggestions
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        suggestionsRef.current &&
        !suggestionsRef.current.contains(event.target as Node) &&
        inputRef.current &&
        !inputRef.current.contains(event.target as Node)
      ) {
        setShowSuggestions(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.toUpperCase();
    console.log('📝 [SymbolAutocomplete] Input changed:', value, 'length:', value.length);
    setInputValue(value);
    setShowSuggestions(true);
    setSelectedIndex(-1);
  };

  const handleSelectSymbol = (symbol: string) => {
    console.log('🎯 [SymbolAutocomplete] handleSelectSymbol called with symbol:', symbol, 'mode:', mode);
    
    if (mode === 'populate') {
      // Populate mode: just fill the input field, don't trigger callback yet
      console.log('🎯 [SymbolAutocomplete] Populate mode: filling input with symbol');
      setInputValue(symbol);
      setSuggestions([]);
      setShowSuggestions(false);
      setSelectedIndex(-1);
      inputRef.current?.focus();
      console.log('🎯 [SymbolAutocomplete] Input populated, waiting for user to press Enter');
    } else {
      // Immediate mode: trigger callback immediately (old behavior)
      console.log('🎯 [SymbolAutocomplete] Immediate mode: triggering callback');
      console.log('🎯 [SymbolAutocomplete] onSymbolSelect callback type:', typeof onSymbolSelect);
      
      try {
        console.log('🎯 [SymbolAutocomplete] Calling onSymbolSelect callback...');
        onSymbolSelect(symbol);
        console.log('🎯 [SymbolAutocomplete] onSymbolSelect callback completed successfully');
      } catch (error) {
        console.error('❌ [SymbolAutocomplete] Error in onSymbolSelect callback:', error);
      }
      
      console.log('🎯 [SymbolAutocomplete] Clearing input and suggestions...');
      setInputValue('');
      setSuggestions([]);
      setShowSuggestions(false);
      setSelectedIndex(-1);
      inputRef.current?.focus();
      console.log('🎯 [SymbolAutocomplete] Symbol selection flow completed');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    console.log('⌨️ [SymbolAutocomplete] Key pressed:', e.key, 'inputValue:', inputValue, 'showSuggestions:', showSuggestions, 'suggestions.length:', suggestions.length);
    
    if (!showSuggestions || suggestions.length === 0) {
      if (e.key === 'Enter' && inputValue.trim()) {
        console.log('🎯 [SymbolAutocomplete] ✅ ENTER DETECTED with no suggestions, inputValue:', inputValue.trim());
        console.log('🎯 [SymbolAutocomplete] Mode:', mode, 'onSymbolSelect type:', typeof onSymbolSelect);
        
        if (mode === 'populate') {
          // In populate mode, Enter always triggers the callback
          console.log('🎯 [SymbolAutocomplete] 📍 POPULATE MODE: Enter pressed, calling onSymbolSelect with:', inputValue.trim());
          try {
            console.log('🎯 [SymbolAutocomplete] 🚀 CALLING onSymbolSelect callback...');
            onSymbolSelect(inputValue.trim());
            console.log('🎯 [SymbolAutocomplete] ✅ onSymbolSelect callback completed successfully, clearing input');
            setInputValue('');
          } catch (error) {
            console.error('❌ [SymbolAutocomplete] Error in onSymbolSelect callback:', error);
          }
        } else {
          // Immediate mode: treat as direct symbol entry
          console.log('🎯 [SymbolAutocomplete] IMMEDIATE MODE: calling handleSelectSymbol');
          handleSelectSymbol(inputValue.trim());
        }
      } else {
        console.log('🎯 [SymbolAutocomplete] Enter not processed - key:', e.key, 'inputValue.trim():', inputValue.trim(), 'length:', inputValue.trim().length);
      }
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex((prev) => 
          prev < suggestions.length - 1 ? prev + 1 : 0
        );
        break;
        
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex((prev) => 
          prev > 0 ? prev - 1 : suggestions.length - 1
        );
        break;
        
      case 'Enter':
        e.preventDefault();
        console.log('🎯 [SymbolAutocomplete] ✅ ENTER DETECTED with suggestions, selectedIndex:', selectedIndex);
        console.log('🎯 [SymbolAutocomplete] Available suggestions:', suggestions.map(s => s.symbol));
        
        if (selectedIndex >= 0 && selectedIndex < suggestions.length) {
          console.log('🎯 [SymbolAutocomplete] 📍 Using selected suggestion:', suggestions[selectedIndex].symbol);
          handleSelectSymbol(suggestions[selectedIndex].symbol);
        } else if (inputValue.trim()) {
          console.log('🎯 [SymbolAutocomplete] 📍 No suggestion selected, using input value:', inputValue.trim());
          console.log('🎯 [SymbolAutocomplete] Mode:', mode);
          
          if (mode === 'populate') {
            // In populate mode, Enter always triggers the callback
            console.log('🎯 [SymbolAutocomplete] 🚀 POPULATE MODE: calling onSymbolSelect directly with input value');
            try {
              onSymbolSelect(inputValue.trim());
              console.log('🎯 [SymbolAutocomplete] ✅ onSymbolSelect completed, clearing UI state');
              setInputValue('');
              setSuggestions([]);
              setShowSuggestions(false);
              setSelectedIndex(-1);
            } catch (error) {
              console.error('❌ [SymbolAutocomplete] Error in onSymbolSelect callback:', error);
            }
          } else {
            console.log('🎯 [SymbolAutocomplete] IMMEDIATE MODE: calling handleSelectSymbol');
            handleSelectSymbol(inputValue.trim());
          }
        } else {
          console.log('🎯 [SymbolAutocomplete] ⚠️ Enter pressed but no input value to process');
        }
        break;
        
      case 'Escape':
        setShowSuggestions(false);
        setSelectedIndex(-1);
        break;
    }
  };

  const handleFocus = () => {
    if (inputValue && suggestions.length > 0) {
      setShowSuggestions(true);
    }
  };

  const getAssetTypeBadge = (type: string) => {
    const badges: Record<string, { label: string; className: string }> = {
      'Stock': { label: 'Stock', className: styles.stockBadge },
      'ETF': { label: 'ETF', className: styles.etfBadge },
      'Crypto': { label: 'Crypto', className: styles.cryptoBadge },
    };
    
    return badges[type] || { label: type, className: styles.defaultBadge };
  };

  return (
    <div className={`${styles.autocompleteContainer} ${className}`}>
      <input
        ref={inputRef}
        type="text"
        value={inputValue}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onFocus={handleFocus}
        placeholder={placeholder}
        className={styles.input}
        autoFocus={autoFocus}
        spellCheck={false}
        autoComplete="off"
      />
      
      {showSuggestions && (inputValue.length >= 2 || suggestions.length > 0) && (
        <div ref={suggestionsRef} className={styles.suggestionsDropdown}>
          {isLoading ? (
            <div className={styles.loadingState}>
              <div className={styles.spinner} />
              <span>Searching...</span>
            </div>
          ) : suggestions.length > 0 ? (
            <div className={styles.suggestionsList}>
              {suggestions.map((suggestion, index) => {
                const badge = getAssetTypeBadge(suggestion.type);
                return (
                  <div
                    key={suggestion.symbol}
                    className={`${styles.suggestionItem} ${
                      index === selectedIndex ? styles.selected : ''
                    }`}
                    onClick={() => handleSelectSymbol(suggestion.symbol)}
                    onMouseEnter={() => setSelectedIndex(index)}
                  >
                    <div className={styles.symbolInfo}>
                      <span className={styles.symbol}>{suggestion.symbol}</span>
                      <span className={`${styles.badge} ${badge.className}`}>
                        {badge.label}
                      </span>
                    </div>
                    <div className={styles.companyName}>{suggestion.name}</div>
                  </div>
                );
              })}
            </div>
          ) : inputValue.length >= 2 ? (
            <div className={styles.noResults}>
              No symbols found for "{inputValue}"
              <div className={styles.directAdd}>
                Press Enter to add "{inputValue}" anyway
              </div>
            </div>
          ) : null}
        </div>
      )}
    </div>
  );
};

export default SymbolAutocomplete;