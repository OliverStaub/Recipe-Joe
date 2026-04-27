<script lang="ts">
	import '../app.css';
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Toaster } from '$lib/components/ui/sonner';
	import AppShell from '$lib/components/layout/app-shell.svelte';
	import type { LayoutData } from './$types';

	let { data, children }: { data: LayoutData; children: import('svelte').Snippet } = $props();
	let { supabase } = $derived(data);

	onMount(() => {
		const { data: subscription } = supabase.auth.onAuthStateChange((_event, newSession) => {
			if (newSession?.expires_at !== data.session?.expires_at) {
				invalidate('supabase:auth');
			}
		});
		return () => subscription.subscription.unsubscribe();
	});
</script>

<AppShell user={data.user}>
	{@render children()}
</AppShell>

<Toaster richColors closeButton position="top-center" />
