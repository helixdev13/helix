'use client';

import { forwardRef } from 'react';
import type { ButtonHTMLAttributes } from 'react';

type GradientButtonProps = ButtonHTMLAttributes<HTMLButtonElement>;

export const GradientButton = forwardRef<HTMLButtonElement, GradientButtonProps>(
  function GradientButton({ className = '', type = 'button', ...props }, ref) {
    return (
      <button
        ref={ref}
        type={type}
        className={[
          'inline-flex h-11 items-center justify-center rounded-lg px-5 text-sm font-semibold text-white shadow-none',
          'bg-[#ff4f96] transition-[background-color,opacity] duration-200 hover:bg-[#ff5ca0] active:scale-[0.99]',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#ff4f96] focus-visible:ring-offset-2 focus-visible:ring-offset-[#0d0f16]',
          'disabled:cursor-not-allowed disabled:bg-[#ff4f96]/40 disabled:shadow-none disabled:hover:bg-[#ff4f96]/40',
          className,
        ].join(' ')}
        {...props}
      />
    );
  },
);

GradientButton.displayName = 'GradientButton';
