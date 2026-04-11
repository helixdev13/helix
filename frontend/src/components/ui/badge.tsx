import type { HTMLAttributes } from 'react';

type BadgeVariant = 'default' | 'secondary' | 'outline';

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  variant?: BadgeVariant;
};

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-[#ff4f96]/15 text-[#ff8ab9] border border-[#ff4f96]/25',
  secondary: 'bg-[var(--bg-surface-2)] text-[var(--text-secondary)] border border-[var(--border-subtle)]',
  outline: 'bg-transparent text-[var(--text-secondary)] border border-[var(--border-subtle)]',
};

export function Badge({ className = '', variant = 'default', ...props }: BadgeProps) {
  return (
    <span
      className={[
        'inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium',
        variantClasses[variant],
        className,
      ].join(' ')}
      {...props}
    />
  );
}
