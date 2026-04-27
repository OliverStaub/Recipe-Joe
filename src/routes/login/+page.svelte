<script lang="ts">
	import { Mail, Loader2 } from 'lucide-svelte';
	import { enhance } from '$app/forms';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Alert, AlertDescription, AlertTitle } from '$lib/components/ui/alert';
	import type { ActionData } from './$types';

	let { form }: { form: ActionData } = $props();
	let submitting = $state(false);
</script>

<div class="mx-auto flex min-h-[70vh] max-w-md flex-col justify-center gap-8 py-10">
	<div class="text-center">
		<div class="mb-6 flex justify-center">
			<div
				class="bg-primary text-primary-foreground flex size-20 items-center justify-center rounded-3xl shadow-lg shadow-orange-900/15"
			>
				<span class="font-display text-5xl leading-none italic">R</span>
			</div>
		</div>
		<h1 class="font-display text-4xl leading-[0.95] sm:text-5xl">
			Save every<br />
			<span class="text-primary italic">recipe</span> you love.
		</h1>
		<p class="text-muted-foreground mt-4 text-sm leading-relaxed">
			From any video or website, into one beautiful cookbook.
		</p>
	</div>

	<Card class="border-border/60">
		<CardHeader>
			<CardTitle>Sign in with email</CardTitle>
			<CardDescription>We'll email you a magic link — no password.</CardDescription>
		</CardHeader>
		<CardContent>
			{#if form?.sent}
				<Alert>
					<Mail class="size-4" />
					<AlertTitle>Check your inbox</AlertTitle>
					<AlertDescription
						>We sent a sign-in link to <strong>{form.email}</strong>.</AlertDescription
					>
				</Alert>
			{:else}
				<form
					method="POST"
					action="?/otp"
					class="space-y-4"
					use:enhance={() => {
						submitting = true;
						return async ({ update }) => {
							await update();
							submitting = false;
						};
					}}
				>
					<div class="space-y-2">
						<Label for="email">Email</Label>
						<Input
							id="email"
							name="email"
							type="email"
							placeholder="you@example.com"
							required
							value={form?.email ?? ''}
						/>
						{#if form?.errors?.email}
							<p class="text-destructive text-xs">{form.errors.email[0]}</p>
						{/if}
					</div>

					{#if form?.message}
						<Alert variant="destructive">
							<AlertTitle>Sign-in failed</AlertTitle>
							<AlertDescription>{form.message}</AlertDescription>
						</Alert>
					{/if}

					<Button type="submit" class="w-full" disabled={submitting}>
						{#if submitting}<Loader2 class="size-4 animate-spin" />Sending…{:else}Email me a link{/if}
					</Button>
				</form>
			{/if}
		</CardContent>
	</Card>
</div>
