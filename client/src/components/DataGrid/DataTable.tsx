import React from 'react';
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  flexRender,
  type ColumnDef,
  type SortingState,
  type ColumnFiltersState,
  type VisibilityState,
  type RowSelectionState,
} from '@tanstack/react-table';
import styles from './DataTable.module.css';

interface DataTableProps<TData> {
  data: TData[];
  columns: ColumnDef<TData>[];
  isLoading?: boolean;
  enableSorting?: boolean;
  enableFiltering?: boolean;
  enableColumnVisibility?: boolean;
  enableRowSelection?: boolean;
  enablePagination?: boolean;
  pageSize?: number;
  className?: string;
  onRowClick?: (row: TData) => void;
  onRowSelectionChange?: (selection: Record<string, boolean>) => void;
  density?: 'compact' | 'normal' | 'comfortable';
}

function DataTable<TData>({
  data,
  columns,
  isLoading = false,
  enableSorting = true,
  enableFiltering = false,
  enableRowSelection = false,
  enablePagination = false,
  pageSize = 10,
  className = '',
  onRowClick,
  onRowSelectionChange,
  density = 'normal',
}: DataTableProps<TData>) {
  const [sorting, setSorting] = React.useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([]);
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({});
  const [rowSelection, setRowSelection] = React.useState<RowSelectionState>({});

  const table = useReactTable({
    data,
    columns,
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onColumnVisibilityChange: setColumnVisibility,
    onRowSelectionChange: (selection) => {
      setRowSelection(selection);
      if (onRowSelectionChange && typeof selection === 'function') {
        const newSelection = selection(rowSelection);
        onRowSelectionChange(newSelection);
      } else if (onRowSelectionChange && typeof selection !== 'function') {
        onRowSelectionChange(selection);
      }
    },
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: enableSorting ? getSortedRowModel() : undefined,
    getFilteredRowModel: enableFiltering ? getFilteredRowModel() : undefined,
    getPaginationRowModel: enablePagination ? getPaginationRowModel() : undefined,
    initialState: {
      pagination: {
        pageSize,
      },
    },
    state: {
      sorting,
      columnFilters,
      columnVisibility,
      rowSelection,
    },
    enableRowSelection,
    enableSorting,
    enableColumnFilters: enableFiltering,
  });

  if (isLoading) {
    return (
      <div className={`${styles.dataTable} ${styles[density]} ${className}`}>
        <div className={styles.loadingState}>
          {Array.from({ length: pageSize }).map((_, index) => (
            <div key={index} className={styles.skeletonRow} />
          ))}
        </div>
      </div>
    );
  }

  if (data.length === 0) {
    return (
      <div className={`${styles.dataTable} ${styles[density]} ${className}`}>
        <div className={styles.emptyState}>
          <p>No data available</p>
        </div>
      </div>
    );
  }

  return (
    <div className={`${styles.dataTable} ${styles[density]} ${className}`}>
      <div className={styles.tableContainer}>
        <table className={styles.table}>
          <thead className={styles.tableHeader}>
            {table.getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id} className={styles.headerRow}>
                {headerGroup.headers.map((header) => (
                  <th
                    key={header.id}
                    className={`${styles.headerCell} ${
                      header.column.getCanSort() ? styles.sortable : ''
                    }`}
                    onClick={header.column.getToggleSortingHandler()}
                    style={{ width: header.getSize() }}
                  >
                    <div className={styles.headerContent}>
                      {header.isPlaceholder
                        ? null
                        : flexRender(header.column.columnDef.header, header.getContext())}
                      {header.column.getCanSort() && (
                        <span className={styles.sortIcon}>
                          {header.column.getIsSorted() === 'asc' && '↑'}
                          {header.column.getIsSorted() === 'desc' && '↓'}
                          {!header.column.getIsSorted() && '↕'}
                        </span>
                      )}
                    </div>
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className={styles.tableBody}>
            {table.getRowModel().rows.map((row) => (
              <tr
                key={row.id}
                className={`${styles.bodyRow} ${
                  row.getIsSelected() ? styles.selectedRow : ''
                } ${onRowClick ? styles.clickableRow : ''}`}
                onClick={() => onRowClick?.(row.original)}
              >
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className={styles.bodyCell}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {enablePagination && (
        <div className={styles.pagination}>
          <div className={styles.paginationInfo}>
            <span>
              {table.getState().pagination.pageIndex * table.getState().pagination.pageSize + 1} -{' '}
              {Math.min(
                (table.getState().pagination.pageIndex + 1) * table.getState().pagination.pageSize,
                table.getFilteredRowModel().rows.length
              )}{' '}
              of {table.getFilteredRowModel().rows.length}
            </span>
          </div>
          <div className={styles.paginationControls}>
            <button
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
              className={styles.paginationButton}
            >
              ←
            </button>
            <span className={styles.pageInfo}>
              Page {table.getState().pagination.pageIndex + 1} of {table.getPageCount()}
            </span>
            <button
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
              className={styles.paginationButton}
            >
              →
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default DataTable;