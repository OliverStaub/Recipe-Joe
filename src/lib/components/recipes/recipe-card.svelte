<script lang="ts">
	import { Clock, Heart } from 'lucide-svelte';
	import { Card } from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';
	import { AspectRatio } from '$lib/components/ui/aspect-ratio';
	import { formatDuration } from '$lib/utils/format';
	import type { RecipeWithUserState } from '$lib/types/recipe';

	let { recipe }: { recipe: RecipeWithUserState } = $props();
</script>

<a href={`/recipes/${recipe.id}`} class="group block">
	<Card class="border-border/60 overflow-hidden transition-all group-hover:shadow-md">
		<AspectRatio ratio={1} class="bg-primary-soft relative">
			{#if recipe.image_url}
				<img
					src={recipe.image_url}
					alt={recipe.name}
					class="size-full object-cover"
					loading="lazy"
				/>
			{:else}
				<div
					class="text-primary-soft-foreground font-display flex size-full items-center justify-center"
				>
					<span class="text-3xl italic">{recipe.name.charAt(0)}</span>
				</div>
			{/if}
			{#if recipe.is_favorite}
				<span
					class="bg-background/90 text-primary absolute top-2 right-2 inline-flex size-7 items-center justify-center rounded-full"
				>
					<Heart class="size-3.5 fill-current" />
				</span>
			{/if}
		</AspectRatio>
		<div class="space-y-2 p-3">
			<h3 class="font-display line-clamp-2 text-lg leading-snug">{recipe.name}</h3>
			<div class="text-muted-foreground flex flex-wrap items-center gap-2 text-xs">
				{#if recipe.total_time_minutes}
					<span class="inline-flex items-center gap-1">
						<Clock class="size-3.5" />
						{formatDuration(recipe.total_time_minutes)}
					</span>
				{/if}
				{#if recipe.category}
					<Badge variant="secondary" class="text-[11px]">{recipe.category}</Badge>
				{/if}
			</div>
		</div>
	</Card>
</a>
