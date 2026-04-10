import type { HTMLAttributes } from 'react';

type BadgeVariant = 'default' | 'secondary' | 'outline';

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  variant?: BadgeVariant;
};

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-emerald-400/15 text-emerald-200 border border-emerald-400/20',
  secondary: 'bg-white/10 text-slate-100 border border-white/10',
  outline: 'bg-transparent text-slate-200 border border-white/15',
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
