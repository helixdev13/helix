'use client';

import {
  createContext,
  useContext,
  useMemo,
  useState,
  type HTMLAttributes,
} from 'react';

type TabsContextValue = {
  value: string;
  setValue: (value: string) => void;
};

const TabsContext = createContext<TabsContextValue | null>(null);

type TabsProps = HTMLAttributes<HTMLDivElement> & {
  defaultValue: string;
  value?: string;
  onValueChange?: (value: string) => void;
};

export function Tabs({
  defaultValue,
  value,
  onValueChange,
  className = '',
  children,
  ...props
}: TabsProps) {
  const [internalValue, setInternalValue] = useState(defaultValue);
  const currentValue = value ?? internalValue;

  const contextValue = useMemo<TabsContextValue>(
    () => ({
      value: currentValue,
      setValue: onValueChange ?? setInternalValue,
    }),
    [currentValue, onValueChange],
  );

  return (
    <TabsContext.Provider value={contextValue}>
      <div className={className} {...props}>
        {children}
      </div>
    </TabsContext.Provider>
  );
}

type TabsListProps = HTMLAttributes<HTMLDivElement>;

export function TabsList({ className = '', ...props }: TabsListProps) {
  return (
    <div
      role="tablist"
      className={['inline-flex items-center gap-8 border-b border-[var(--border-subtle)] bg-transparent p-0', className].join(' ')}
      {...props}
    />
  );
}

type TabsTriggerProps = HTMLAttributes<HTMLButtonElement> & {
  value: string;
};

export function TabsTrigger({ value, className = '', children, ...props }: TabsTriggerProps) {
  const context = useContext(TabsContext);

  if (!context) {
    throw new Error('TabsTrigger must be used within Tabs');
  }

  const active = context.value === value;

  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      tabIndex={active ? 0 : -1}
      onClick={() => context.setValue(value)}
      className={[
        'border-b-2 border-transparent px-1 py-3 text-sm font-medium transition-colors',
        active ? 'border-[#ff4f96] text-[#ff4f96]' : 'text-[var(--text-muted)] hover:text-[var(--text-secondary)]',
        className,
      ].join(' ')}
      {...props}
    >
      {children}
    </button>
  );
}

type TabsContentProps = HTMLAttributes<HTMLDivElement> & {
  value: string;
};

export function TabsContent({ value, className = '', children, ...props }: TabsContentProps) {
  const context = useContext(TabsContext);

  if (!context) {
    throw new Error('TabsContent must be used within Tabs');
  }

  if (context.value !== value) {
    return null;
  }

  return (
    <div className={className} {...props}>
      {children}
    </div>
  );
}
