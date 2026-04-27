<script lang="ts">
	import { enhance } from '$app/forms';
	import { Loader2, AlertCircle, X } from '@lucide/svelte';
	import { Button } from '$lib/components/ui/button';
	import type { RecipeImport } from '$lib/types/recipe';

	let { import: imp }: { import: RecipeImport } = $props();

	let isError = $derived(imp.status === 'error');
	let isWorking = $derived(imp.status === 'queued' || imp.status === 'running');
</script>

<div
	class="border-border bg-card flex items-center gap-3 rounded-2xl border p-4 {isWorking
		? 'animate-pulse'
		: ''} {isError ? 'border-destructive/40 bg-destructive/5' : ''}"
>
	<div
		class="flex size-11 shrink-0 items-center justify-center rounded-full {isError
			? 'bg-destructive/10 text-destructive'
			: 'bg-primary/10 text-primary'}"
	>
		{#if isError}
			<AlertCircle class="size-5" />
		{:else}
			<Loader2 class="size-5 animate-spin" />
		{/if}
	</div>
	<div class="min-w-0 flex-1">
		<p class="font-display text-lg leading-tight">
			{#if isError}
				Import failed
			{:else}
				Importing<span class="italic">…</span>
			{/if}
		</p>
		<p class="text-muted-foreground truncate text-xs">
			{isError ? (imp.error_message ?? 'Unknown error') : imp.source_url}
		</p>
	</div>
	{#if isError || imp.status === 'queued'}
		<form method="POST" action="/recipes?/dismissImport" use:enhance>
			<input type="hidden" name="id" value={imp.id} />
			<Button type="submit" variant="ghost" size="icon" aria-label="Dismiss">
				<X class="size-4" />
			</Button>
		</form>
	{/if}
</div>
