import { forwardRef } from 'react';
import type { ButtonHTMLAttributes } from 'react';

type ButtonVariant = 'default' | 'outline' | 'ghost';

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
};

const variantClasses: Record<ButtonVariant, string> = {
  default:
    'border border-[#F0E8E8] bg-white text-[#333333] hover:bg-[#FFF8F6]',
  outline: 'border border-[#E8A0B8]/35 bg-[#FFF8F6] text-[#D4797F] hover:bg-[#FFF1F5]',
  ghost: 'bg-transparent text-[#666666] hover:bg-[#FFF4F7]',
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
        'inline-flex h-11 items-center justify-center rounded-xl px-4 text-sm font-medium transition-colors duration-200',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#D4797F] focus-visible:ring-offset-2 focus-visible:ring-offset-white',
        'disabled:pointer-events-none disabled:opacity-50',
        variantClasses[variant],
        className,
      ].join(' ')}
      {...props}
    />
  );
});

Button.displayName = 'Button';
