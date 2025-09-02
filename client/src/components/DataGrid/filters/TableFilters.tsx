import React from 'react';
import styles from './TableFilters.module.css';

interface FilterProps {
  value: any;
  onChange: (value: any) => void;
  placeholder?: string;
}

export const TextFilter: React.FC<FilterProps & { placeholder?: string }> = ({
  value,
  onChange,
  placeholder = 'Filter...',
}) => (
  <input
    type="text"
    value={value || ''}
    onChange={(e) => onChange(e.target.value)}
    placeholder={placeholder}
    className={styles.textFilter}
  />
);

export const NumberRangeFilter: React.FC<{
  value: [number?, number?];
  onChange: (value: [number?, number?]) => void;
  placeholder?: [string, string];
}> = ({
  value,
  onChange,
  placeholder = ['Min', 'Max'],
}) => (
  <div className={styles.rangeFilter}>
    <input
      type="number"
      value={value[0] || ''}
      onChange={(e) => onChange([e.target.value ? Number(e.target.value) : undefined, value[1]])}
      placeholder={placeholder[0]}
      className={styles.rangeInput}
    />
    <span className={styles.rangeSeparator}>-</span>
    <input
      type="number"
      value={value[1] || ''}
      onChange={(e) => onChange([value[0], e.target.value ? Number(e.target.value) : undefined])}
      placeholder={placeholder[1]}
      className={styles.rangeInput}
    />
  </div>
);

export const SelectFilter: React.FC<{
  value: string;
  onChange: (value: string) => void;
  options: { label: string; value: string }[];
  placeholder?: string;
}> = ({
  value,
  onChange,
  options,
  placeholder = 'All',
}) => (
  <select
    value={value}
    onChange={(e) => onChange(e.target.value)}
    className={styles.selectFilter}
  >
    <option value="">{placeholder}</option>
    {options.map((option) => (
      <option key={option.value} value={option.value}>
        {option.label}
      </option>
    ))}
  </select>
);

export const PercentageFilter: React.FC<{
  value: 'all' | 'gainers' | 'losers' | 'movers';
  onChange: (value: 'all' | 'gainers' | 'losers' | 'movers') => void;
}> = ({
  value,
  onChange,
}) => (
  <div className={styles.buttonGroup}>
    <button
      className={`${styles.filterButton} ${value === 'all' ? styles.active : ''}`}
      onClick={() => onChange('all')}
    >
      All
    </button>
    <button
      className={`${styles.filterButton} ${value === 'gainers' ? styles.active : ''}`}
      onClick={() => onChange('gainers')}
    >
      📈 Gainers
    </button>
    <button
      className={`${styles.filterButton} ${value === 'losers' ? styles.active : ''}`}
      onClick={() => onChange('losers')}
    >
      📉 Losers
    </button>
    <button
      className={`${styles.filterButton} ${value === 'movers' ? styles.active : ''}`}
      onClick={() => onChange('movers')}
    >
      🚀 Big Movers
    </button>
  </div>
);

interface WatchlistFiltersProps {
  filters: {
    search: string;
    priceRange: [number?, number?];
    changeFilter: 'all' | 'gainers' | 'losers' | 'movers';
    assetClass: string;
  };
  onChange: (filters: WatchlistFiltersProps['filters']) => void;
  className?: string;
}

export const WatchlistFilters: React.FC<WatchlistFiltersProps> = ({
  filters,
  onChange,
  className = '',
}) => {
  const updateFilter = (key: keyof typeof filters, value: any) => {
    onChange({
      ...filters,
      [key]: value,
    });
  };

  const clearFilters = () => {
    onChange({
      search: '',
      priceRange: [undefined, undefined],
      changeFilter: 'all',
      assetClass: '',
    });
  };

  const hasActiveFilters = 
    filters.search || 
    filters.priceRange[0] !== undefined || 
    filters.priceRange[1] !== undefined ||
    filters.changeFilter !== 'all' ||
    filters.assetClass;

  return (
    <div className={`${styles.filtersContainer} ${className}`}>
      <div className={styles.filtersRow}>
        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Search</label>
          <TextFilter
            value={filters.search}
            onChange={(value) => updateFilter('search', value)}
            placeholder="Symbol or company name..."
          />
        </div>

        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Price Range</label>
          <NumberRangeFilter
            value={filters.priceRange}
            onChange={(value) => updateFilter('priceRange', value)}
            placeholder={['$0', '$1000']}
          />
        </div>

        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Asset Class</label>
          <SelectFilter
            value={filters.assetClass}
            onChange={(value) => updateFilter('assetClass', value)}
            options={[
              { label: 'Stocks', value: 'us_equity' },
              { label: 'Crypto', value: 'crypto' },
              { label: 'ETFs', value: 'etf' },
            ]}
            placeholder="All Assets"
          />
        </div>

        {hasActiveFilters && (
          <button
            onClick={clearFilters}
            className={styles.clearButton}
            title="Clear all filters"
          >
            ✕ Clear
          </button>
        )}
      </div>

      <div className={styles.filtersRow}>
        <div className={styles.filterGroup}>
          <label className={styles.filterLabel}>Performance</label>
          <PercentageFilter
            value={filters.changeFilter}
            onChange={(value) => updateFilter('changeFilter', value)}
          />
        </div>
      </div>
    </div>
  );
};

export default WatchlistFilters;