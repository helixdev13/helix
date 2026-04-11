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
          'inline-flex h-11 items-center justify-center rounded-[12px] px-5 text-sm font-semibold text-white transition duration-200',
          'bg-[linear-gradient(135deg,#E8A0B8,#D4797F)] shadow-[0_12px_24px_rgba(212,121,127,0.22)] hover:brightness-105',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D4797F] focus-visible:ring-offset-2 focus-visible:ring-offset-white',
          'disabled:cursor-not-allowed disabled:bg-[#E8A0B8]/55 disabled:shadow-none disabled:brightness-100',
          className,
        ].join(' ')}
        {...props}
      />
    );
  },
);

GradientButton.displayName = 'GradientButton';
