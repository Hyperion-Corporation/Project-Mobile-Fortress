import { useForm } from '@tanstack/vue-form';

/**
 * Shared TanStack Form helper for the Vue docs site.
 * Prefer this over importing `@tanstack/vue-form` directly so defaults
 * stay consistent across hub panels and future islands.
 */
export function useCustomForm<TValues extends Record<string, unknown>>(options: {
  defaultValues: TValues;
  onSubmit?: (props: { value: TValues }) => void | Promise<void>;
}) {
  return useForm({
    defaultValues: options.defaultValues,
    onSubmit: options.onSubmit
      ? async ({ value }) => {
          await options.onSubmit?.({ value: value as TValues });
        }
      : undefined,
  });
}

export { useForm } from '@tanstack/vue-form';
