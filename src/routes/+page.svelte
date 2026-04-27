<script lang="ts">
	import { Sparkles, Search, ChefHat } from 'lucide-svelte';
	import { Button } from '$lib/components/ui/button';
	import { Card, CardContent } from '$lib/components/ui/card';
	import Wordmark from '$lib/components/layout/wordmark.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<section class="mx-auto flex max-w-3xl flex-col gap-8 py-10 sm:py-16">
	<div class="text-center">
		<div class="mb-6 flex justify-center">
			<div
				class="bg-primary text-primary-foreground flex size-20 items-center justify-center rounded-3xl shadow-lg shadow-orange-900/15"
			>
				<span class="font-display text-5xl leading-none italic">R</span>
			</div>
		</div>
		<h1 class="font-display text-5xl leading-[0.95] tracking-tight sm:text-7xl">
			Save every<br />
			<span class="text-primary italic">recipe</span> you love.
		</h1>
		<p class="text-muted-foreground mx-auto mt-6 max-w-prose text-lg leading-relaxed">
			From any video or website, into one beautiful cookbook.
		</p>
		<div class="mt-8 flex flex-wrap justify-center gap-3">
			{#if data.user}
				<Button href="/recipes" size="lg">Open my library</Button>
				<Button href="/recipes/add" variant="outline" size="lg">Add a recipe</Button>
			{:else}
				<Button href="/login" size="lg">Get started</Button>
				<Button href="/login" variant="outline" size="lg">Sign in</Button>
			{/if}
		</div>
	</div>

	<div class="mt-8 grid gap-4 sm:grid-cols-3">
		<Card>
			<CardContent class="flex flex-col gap-2 pt-6">
				<Sparkles class="text-primary size-5" />
				<h3 class="font-display text-2xl">Import from any URL</h3>
				<p class="text-muted-foreground text-sm">Paste a link, get clean ingredients and steps.</p>
			</CardContent>
		</Card>
		<Card>
			<CardContent class="flex flex-col gap-2 pt-6">
				<Search class="text-primary size-5" />
				<h3 class="font-display text-2xl">Search & filter</h3>
				<p class="text-muted-foreground text-sm">Find what you can cook with what you have.</p>
			</CardContent>
		</Card>
		<Card>
			<CardContent class="flex flex-col gap-2 pt-6">
				<ChefHat class="text-primary size-5" />
				<h3 class="font-display text-2xl">Cook mode</h3>
				<p class="text-muted-foreground text-sm">
					Step-by-step view that won't let your screen sleep.
				</p>
			</CardContent>
		</Card>
	</div>

	<p class="text-muted-foreground text-center text-xs">
		<Wordmark size={14} /> · personal recipe library
	</p>
</section>
