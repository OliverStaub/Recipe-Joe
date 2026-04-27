<script lang="ts">
	import { Plus, Heart, Clock } from '@lucide/svelte';
	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import {
		Empty,
		EmptyContent,
		EmptyDescription,
		EmptyHeader,
		EmptyTitle
	} from '$lib/components/ui/empty';
	import RecipeCard from '$lib/components/recipes/recipe-card.svelte';
	import ImportCard from '$lib/components/recipes/import-card.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	type Filter = 'all' | 'fav' | 'recent';
	let filter = $state<Filter>('all');

	const filters: Array<{ id: Filter; label: string; icon?: typeof Plus }> = [
		{ id: 'all', label: 'All' },
		{ id: 'fav', label: 'Favorites', icon: Heart },
		{ id: 'recent', label: 'Recent', icon: Clock }
	];

	let visibleRecipes = $derived.by(() => {
		if (filter === 'fav') return data.recipes.filter((r) => r.is_favorite);
		if (filter === 'recent') return data.recipes.slice(0, 12);
		return data.recipes;
	});

	// Subscribe to recipe_imports changes for live "importing…" updates.
	onMount(() => {
		if (!data.user) return;
		const channel = data.supabase
			.channel(`imports:${data.user.id}`)
			.on(
				'postgres_changes',
				{
					event: '*',
					schema: 'public',
					table: 'recipe_imports',
					filter: `user_id=eq.${data.user.id}`
				},
				() => invalidate('supabase:auth')
			)
			.on(
				'postgres_changes',
				{
					event: 'INSERT',
					schema: 'public',
					table: 'user_recipes',
					filter: `user_id=eq.${data.user.id}`
				},
				() => invalidate('supabase:auth')
			)
			.subscribe();
		return () => {
			void data.supabase.removeChannel(channel);
		};
	});
</script>

<section class="space-y-6">
	<div class="flex items-end justify-between gap-4">
		<h1 class="font-display text-4xl leading-none sm:text-5xl">
			What are we<br />
			<span class="italic">cooking</span> today?
		</h1>
		<Button href="/recipes/add" size="sm" class="hidden sm:inline-flex">
			<Plus class="size-4" /> New
		</Button>
	</div>

	<div class="-mx-4 flex gap-2 overflow-x-auto px-4 pb-1">
		{#each filters as f}
			<Button
				size="sm"
				variant={filter === f.id ? 'default' : 'secondary'}
				class="rounded-full px-4"
				onclick={() => (filter = f.id)}
			>
				{#if f.icon}<f.icon class="size-3.5" />{/if}
				{f.label}
			</Button>
		{/each}
	</div>

	{#if data.imports.length > 0}
		<div class="space-y-2">
			{#each data.imports as imp (imp.id)}
				<ImportCard import={imp} />
			{/each}
		</div>
	{/if}

	{#if data.recipes.length === 0 && data.imports.length === 0}
		<Empty class="mt-10">
			<EmptyHeader>
				<EmptyTitle>No recipes yet</EmptyTitle>
				<EmptyDescription>Import your first recipe from a link.</EmptyDescription>
			</EmptyHeader>
			<EmptyContent>
				<Button href="/recipes/add"><Plus class="size-4" /> Add a recipe</Button>
			</EmptyContent>
		</Empty>
	{:else if data.recipes.length > 0}
		<p class="text-muted-foreground text-sm">
			{visibleRecipes.length} of {data.recipes.length} recipes
		</p>
		<div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
			{#each visibleRecipes as recipe (recipe.id)}
				<RecipeCard {recipe} />
			{/each}
		</div>
	{/if}
</section>
