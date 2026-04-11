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
        'flex h-11 w-full rounded-xl border border-[#F0E8E8] bg-white px-4 py-2 text-sm text-[#333333] shadow-sm transition-colors',
        'placeholder:text-[#999999] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D4797F] focus-visible:ring-offset-2 focus-visible:ring-offset-white',
        'disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-[#FAFAFA]',
        className,
      ].join(' ')}
      {...props}
    />
  );
});

Input.displayName = 'Input';
