import type { HTMLAttributes } from 'react';

type BadgeVariant = 'default' | 'secondary' | 'outline';

type BadgeProps = HTMLAttributes<HTMLSpanElement> & {
  variant?: BadgeVariant;
};

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-[#E8A0B8]/15 text-[#B85C7D] border border-[#E8A0B8]/30',
  secondary: 'bg-[#FFF8F6] text-[#666666] border border-[#F0E8E8]',
  outline: 'bg-white text-[#666666] border border-[#F0E8E8]',
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
