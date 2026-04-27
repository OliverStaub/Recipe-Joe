<script lang="ts">
	import { Loader2, Link, ArrowUpRight, Sparkles, Globe } from '@lucide/svelte';
	import { enhance } from '$app/forms';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { RadioGroup, RadioGroupItem } from '$lib/components/ui/radio-group';
	import { Switch } from '$lib/components/ui/switch';
	import { Alert, AlertDescription, AlertTitle } from '$lib/components/ui/alert';
	import type { ActionData } from './$types';

	let { form }: { form: ActionData } = $props();
	let submitting = $state(false);
</script>

<div class="mx-auto max-w-2xl space-y-8 py-4">
	<header>
		<h1 class="font-display text-4xl leading-[1.05] sm:text-5xl">
			Paste a link from<br />
			<span class="italic">anywhere</span>.
		</h1>
		<p class="text-muted-foreground mt-3 max-w-prose text-sm leading-relaxed">
			We'll extract the ingredients and steps and add it to your cookbook.
		</p>
	</header>

	<form
		method="POST"
		class="space-y-6"
		use:enhance={() => {
			submitting = true;
			return async ({ update }) => {
				await update();
				submitting = false;
			};
		}}
	>
		<div class="relative">
			<Link class="text-muted-foreground absolute top-1/2 left-4 size-5 -translate-y-1/2" />
			<Input
				name="url"
				type="url"
				placeholder="Paste a recipe URL…"
				required
				autofocus
				value={form?.url ?? ''}
				class="h-14 rounded-full pr-14 pl-12 text-base"
			/>
			<Button
				type="submit"
				size="icon"
				disabled={submitting}
				class="absolute top-1.5 right-1.5 size-11 rounded-full"
				aria-label="Import"
			>
				{#if submitting}
					<Loader2 class="size-4 animate-spin" />
				{:else}
					<ArrowUpRight class="size-4" />
				{/if}
			</Button>
		</div>
		{#if form?.errors?.url}
			<p class="text-destructive -mt-3 text-xs">{form.errors.url[0]}</p>
		{/if}

		<div class="space-y-2">
			<Label class="text-muted-foreground text-xs tracking-wider uppercase">Language</Label>
			<RadioGroup name="language" value="en" class="flex gap-2">
				<Label
					class="border-border has-data-[state=checked]:border-primary has-data-[state=checked]:bg-primary-soft has-data-[state=checked]:text-primary-soft-foreground inline-flex cursor-pointer items-center gap-2 rounded-full border px-4 py-2 text-sm"
				>
					<RadioGroupItem value="en" class="sr-only" /> English
				</Label>
				<Label
					class="border-border has-data-[state=checked]:border-primary has-data-[state=checked]:bg-primary-soft has-data-[state=checked]:text-primary-soft-foreground inline-flex cursor-pointer items-center gap-2 rounded-full border px-4 py-2 text-sm"
				>
					<RadioGroupItem value="de" class="sr-only" /> Deutsch
				</Label>
			</RadioGroup>
		</div>

		<div
			class="border-border bg-card flex items-center justify-between gap-4 rounded-2xl border p-4"
		>
			<div>
				<Label for="reword" class="block font-medium">Rewrite & simplify steps</Label>
				<p class="text-muted-foreground mt-0.5 text-xs">
					Off keeps the original wording — only adds category prefixes.
				</p>
			</div>
			<Switch id="reword" name="reword" value="true" checked />
		</div>

		<div
			class="bg-primary-soft text-primary-soft-foreground flex items-start gap-3 rounded-2xl p-4"
		>
			<Sparkles class="mt-0.5 size-5 shrink-0" />
			<p class="text-sm leading-relaxed">
				<strong class="font-semibold">You can close this screen.</strong> Imports take up to two minutes
				— we'll keep working in the background and your recipe will appear at the top of your list when
				it's ready.
			</p>
		</div>

		{#if form?.errors?.url}
			<Alert variant="destructive">
				<AlertTitle>Invalid URL</AlertTitle>
				<AlertDescription>{form.errors.url[0]}</AlertDescription>
			</Alert>
		{/if}
	</form>

	<div>
		<p class="text-muted-foreground mb-3 text-xs font-medium tracking-wider uppercase">
			Supported sources
		</p>
		<div class="flex flex-wrap gap-2 text-sm">
			{#each [{ label: 'YouTube' }, { label: 'TikTok' }, { label: 'Instagram' }, { label: 'Any web page' }] as src}
				<span
					class="border-border bg-card text-foreground inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5"
				>
					<Globe class="text-muted-foreground size-3.5" />
					{src.label}
				</span>
			{/each}
		</div>
	</div>
</div>
