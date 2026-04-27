<script lang="ts">
	import { Search } from 'lucide-svelte';
	import { Input } from '$lib/components/ui/input';
	import RecipeCard from '$lib/components/recipes/recipe-card.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<h1 class="mb-6 text-2xl font-bold tracking-tight sm:text-3xl">Search</h1>

<form method="GET" class="relative">
	<Search class="text-muted-foreground absolute top-1/2 left-3 size-4 -translate-y-1/2" />
	<Input name="q" value={data.q} placeholder="Search by name…" class="pl-9" autocomplete="off" />
</form>

{#if data.q && data.recipes.length === 0}
	<p class="text-muted-foreground mt-8 text-center text-sm">No results for “{data.q}”.</p>
{:else}
	<div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
		{#each data.recipes as recipe (recipe.id)}
			<RecipeCard {recipe} />
		{/each}
	</div>
{/if}
