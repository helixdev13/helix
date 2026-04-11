import { forwardRef } from 'react';
import type { InputHTMLAttributes } from 'react';

type InputProps = InputHTMLAttributes<HTMLInputElement>;

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { className = '', ...props },
  ref,
) {
  return (
    <input
      ref={ref}
      className={[
        'flex h-11 w-full rounded-lg border border-[var(--border-subtle)] bg-[var(--bg-surface-2)] px-4 py-2 text-sm text-[var(--text-primary)] shadow-none transition-[border-color,background-color,transform] duration-200',
        'placeholder:text-[var(--text-muted)] hover:border-[rgba(255,255,255,0.09)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#ff4f96] focus-visible:ring-offset-2 focus-visible:ring-offset-[#0d0f16]',
        'disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-[var(--bg-surface)]',
        className,
      ].join(' ')}
      {...props}
    />
  );
});

Input.displayName = 'Input';
