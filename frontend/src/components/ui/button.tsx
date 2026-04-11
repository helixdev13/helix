import { forwardRef } from 'react';
import type { ButtonHTMLAttributes } from 'react';

type ButtonVariant = 'default' | 'outline' | 'ghost';

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
};

const variantClasses: Record<ButtonVariant, string> = {
  default:
    'border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] text-[var(--text-primary)] hover:bg-[#2a3040]',
  outline: 'border border-[var(--border-subtle)] bg-transparent text-[#ff8ab9] hover:bg-[#222936]',
  ghost: 'bg-transparent text-[var(--text-secondary)] hover:bg-[var(--bg-surface-2)]',
};

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { className = '', variant = 'default', type = 'button', ...props },
  ref
) {
  return (
    <button
      ref={ref}
      type={type}
      className={[
        'inline-flex h-11 items-center justify-center rounded-lg px-4 text-sm font-medium transition-[background-color,color,border-color] duration-200',
        'active:scale-[0.99]',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#ff4f96] focus-visible:ring-offset-2 focus-visible:ring-offset-[#0d0f16]',
        'disabled:pointer-events-none disabled:opacity-50',
        variantClasses[variant],
        className,
      ].join(' ')}
      {...props}
    />
  );
});

Button.displayName = 'Button';
