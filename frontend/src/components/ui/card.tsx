import type { HTMLAttributes } from 'react';

type DivProps = HTMLAttributes<HTMLDivElement>;

export function Card({ className = '', ...props }: DivProps) {
  return (
    <div
      className={[
        'rounded-[16px] border border-[#F0E8E8] bg-white shadow-[0_2px_12px_rgba(0,0,0,0.08)]',
        className,
      ].join(' ')}
      {...props}
    />
  );
}

export function CardHeader({ className = '', ...props }: DivProps) {
  return <div className={['flex flex-col space-y-1.5 p-5 sm:p-6', className].join(' ')} {...props} />;
}

export function CardTitle({ className = '', ...props }: DivProps) {
  return <h3 className={['text-lg font-semibold tracking-tight text-[#333333]', className].join(' ')} {...props} />;
}

export function CardDescription({ className = '', ...props }: DivProps) {
  return <p className={['text-sm text-[#666666]', className].join(' ')} {...props} />;
}

export function CardContent({ className = '', ...props }: DivProps) {
  return <div className={['p-5 pt-0 sm:p-6 sm:pt-0', className].join(' ')} {...props} />;
}
