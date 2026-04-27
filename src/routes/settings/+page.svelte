<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<h1 class="mb-6 text-2xl font-bold tracking-tight sm:text-3xl">Settings</h1>

<div class="space-y-4">
	<Card>
		<CardHeader>
			<CardTitle>Account</CardTitle>
			<CardDescription>Signed in as {data.user.email}</CardDescription>
		</CardHeader>
		<CardContent class="flex justify-end">
			<Button href="/logout" variant="outline">Sign out</Button>
		</CardContent>
	</Card>
</div>
