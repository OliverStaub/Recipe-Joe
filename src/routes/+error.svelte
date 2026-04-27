<script lang="ts">
	import { page } from '$app/stores';
	import { Button } from '$lib/components/ui/button';
</script>

<div class="mx-auto max-w-lg py-16 text-center">
	<p class="text-primary text-sm font-medium">Error {$page.status}</p>
	<h1 class="mt-2 text-3xl font-bold tracking-tight">
		{$page.error?.message ?? 'Something went wrong'}
	</h1>
	<div class="mt-6 flex justify-center gap-3">
		<Button href="/">Home</Button>
		<Button variant="outline" onclick={() => history.back()}>Go back</Button>
	</div>
</div>
