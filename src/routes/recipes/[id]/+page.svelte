<script lang="ts">
	import {
		Clock,
		Flame,
		Heart,
		Trash2,
		Users,
		Bookmark,
		Globe,
		Link as LinkIcon,
		ArrowUpRight
	} from '@lucide/svelte';
	import { enhance } from '$app/forms';
	import { Button } from '$lib/components/ui/button';
	import { Separator } from '$lib/components/ui/separator';
	import { AspectRatio } from '$lib/components/ui/aspect-ratio';
	import {
		AlertDialog,
		AlertDialogAction,
		AlertDialogCancel,
		AlertDialogContent,
		AlertDialogDescription,
		AlertDialogFooter,
		AlertDialogHeader,
		AlertDialogTitle,
		AlertDialogTrigger
	} from '$lib/components/ui/alert-dialog';
	import { formatDuration, formatQuantity } from '$lib/utils/format';
	import { toast } from 'svelte-sonner';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	let recipe = $derived(data.recipe);

	type Lang = 'en' | 'de';
	let lang = $state<Lang>('en');
	$effect(() => {
		// Default to the recipe's import language whenever a different recipe loads.
		lang = recipe.language as Lang;
	});

	const stat = (label: string, value: string | number | null | undefined) => ({ label, value });
</script>

<article class="space-y-6">
	{#if recipe.image_url}
		<AspectRatio ratio={16 / 9} class="bg-primary-soft overflow-hidden rounded-2xl">
			<img src={recipe.image_url} alt={recipe.name} class="size-full object-cover" />
		</AspectRatio>
	{:else}
		<div class="bg-primary-soft flex aspect-[16/9] items-center justify-center rounded-2xl">
			<span class="text-primary font-display text-7xl italic">
				{recipe.name.charAt(0).toUpperCase()}
			</span>
		</div>
	{/if}

	<header class="space-y-3">
		<h1 class="font-display text-4xl leading-[1.05] tracking-tight sm:text-5xl">{recipe.name}</h1>
		{#if recipe.author}
			<p class="font-display text-muted-foreground text-lg italic">by {recipe.author}</p>
		{/if}
		{#if recipe.description}
			<p class="text-muted-foreground max-w-prose leading-relaxed">{recipe.description}</p>
		{/if}
	</header>

	<div class="flex flex-wrap items-center gap-2">
		{#if recipe.category}
			<span
				class="bg-primary-soft text-primary-soft-foreground inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm"
			>
				<Bookmark class="size-3.5" />
				{recipe.category}
			</span>
		{/if}
		{#if recipe.cuisine}
			<span
				class="bg-primary-soft text-primary-soft-foreground inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm"
			>
				<Globe class="size-3.5" />
				{recipe.cuisine}
			</span>
		{/if}
		{#if recipe.recipe_yield}
			<span class="text-muted-foreground inline-flex items-center gap-1.5 text-sm">
				<Users class="size-3.5" />
				{recipe.recipe_yield}
			</span>
		{/if}
	</div>

	<div class="grid grid-cols-3 gap-2">
		{#each [stat('Prep', recipe.prep_time_minutes ? formatDuration(recipe.prep_time_minutes) : '—'), stat('Cook', recipe.cook_time_minutes ? formatDuration(recipe.cook_time_minutes) : '—'), stat('Total', recipe.total_time_minutes ? formatDuration(recipe.total_time_minutes) : '—')] as s}
			<div class="bg-muted rounded-xl p-3">
				<div class="font-display text-2xl leading-none">{s.value}</div>
				<div class="text-muted-foreground mt-1 text-xs">{s.label}</div>
			</div>
		{/each}
	</div>

	<div class="flex flex-wrap items-center gap-2">
		<form
			method="POST"
			action="?/favorite"
			use:enhance={() => {
				return async ({ result, update }) => {
					if (result.type === 'success')
						toast.success(recipe.is_favorite ? 'Removed from favorites' : 'Saved to favorites');
					await update();
				};
			}}
		>
			<input type="hidden" name="value" value={recipe.is_favorite ? 'false' : 'true'} />
			<Button type="submit" variant={recipe.is_favorite ? 'default' : 'outline'} size="sm">
				<Heart class="size-4 {recipe.is_favorite ? 'fill-current' : ''}" />
				{recipe.is_favorite ? 'Favorited' : 'Favorite'}
			</Button>
		</form>

		{#if recipe.source_url}
			<Button href={recipe.source_url} target="_blank" rel="noreferrer" variant="outline" size="sm">
				<LinkIcon class="size-4" /> Open original
				<ArrowUpRight class="size-4" />
			</Button>
		{/if}

		<div class="ml-auto flex gap-1">
			<Button
				size="sm"
				variant={lang === 'en' ? 'secondary' : 'ghost'}
				onclick={() => (lang = 'en')}>EN</Button
			>
			<Button
				size="sm"
				variant={lang === 'de' ? 'secondary' : 'ghost'}
				onclick={() => (lang = 'de')}>DE</Button
			>
		</div>

		<AlertDialog>
			<AlertDialogTrigger>
				<Button
					variant="ghost"
					size="icon"
					class="text-destructive"
					aria-label="Remove from library"
				>
					<Trash2 class="size-4" />
				</Button>
			</AlertDialogTrigger>
			<AlertDialogContent>
				<AlertDialogHeader>
					<AlertDialogTitle>Remove from your library?</AlertDialogTitle>
					<AlertDialogDescription>
						The recipe will stay available for everyone else who imported it — you'll just lose your
						save and favorite.
					</AlertDialogDescription>
				</AlertDialogHeader>
				<AlertDialogFooter>
					<AlertDialogCancel>Cancel</AlertDialogCancel>
					<form method="POST" action="?/unsave" use:enhance>
						<AlertDialogAction type="submit">Remove</AlertDialogAction>
					</form>
				</AlertDialogFooter>
			</AlertDialogContent>
		</AlertDialog>
	</div>

	<Separator />

	<div class="grid gap-8 lg:grid-cols-[1fr_2fr]">
		<section>
			<h2 class="font-display mb-4 text-2xl">Ingredients</h2>
			<ul class="bg-muted divide-border divide-y rounded-2xl px-1">
				{#each recipe.recipe_ingredients as ri (ri.id)}
					{@const name = lang === 'de' ? ri.ingredients?.name_de : ri.ingredients?.name_en}
					{@const unit =
						lang === 'de'
							? ri.measurement_types?.abbreviation_de
							: ri.measurement_types?.abbreviation_en}
					<li class="grid grid-cols-[70px_1fr] gap-3 px-4 py-2.5 text-sm">
						<span class="font-medium tabular-nums">
							{formatQuantity(ri.quantity)}
							{unit ?? ''}
						</span>
						<div>
							<div>{name ?? '—'}</div>
							{#if ri.notes}
								<div class="text-muted-foreground text-xs">{ri.notes}</div>
							{/if}
						</div>
					</li>
				{/each}
			</ul>
		</section>

		<section>
			<h2 class="font-display mb-4 text-2xl">Steps</h2>
			<ol class="space-y-3">
				{#each recipe.recipe_steps as step (step.id)}
					<li class="border-border grid grid-cols-[28px_1fr] gap-4 border-b py-3 last:border-b-0">
						<span class="text-primary font-display text-2xl leading-none">{step.step_number}</span>
						<div>
							<p class="text-sm leading-relaxed">{step.instruction}</p>
							{#if step.duration_minutes}
								<p class="text-muted-foreground mt-1 text-xs">
									{formatDuration(step.duration_minutes)}
								</p>
							{/if}
						</div>
					</li>
				{/each}
			</ol>
		</section>
	</div>
</article>
