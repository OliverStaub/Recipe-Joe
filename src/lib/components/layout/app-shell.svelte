<script lang="ts">
	import type { User } from '@supabase/supabase-js';
	import { page } from '$app/stores';
	import { Home, Plus, Search, Settings, LogOut } from 'lucide-svelte';
	import { Button } from '$lib/components/ui/button';
	import {
		DropdownMenu,
		DropdownMenuContent,
		DropdownMenuItem,
		DropdownMenuLabel,
		DropdownMenuSeparator,
		DropdownMenuTrigger
	} from '$lib/components/ui/dropdown-menu';
	import { Avatar, AvatarFallback } from '$lib/components/ui/avatar';
	import Wordmark from '$lib/components/layout/wordmark.svelte';

	let { user, children }: { user: User | null; children: import('svelte').Snippet } = $props();

	const navItems = [
		{ href: '/recipes', label: 'Home', icon: Home },
		{ href: '/search', label: 'Search', icon: Search },
		{ href: '/recipes/add', label: 'Add', icon: Plus, primary: true },
		{ href: '/settings', label: 'Settings', icon: Settings }
	];

	let initials = $derived(
		user?.email
			?.split('@')[0]
			.split(/[._-]/)
			.map((p) => p[0]?.toUpperCase() ?? '')
			.slice(0, 2)
			.join('') ?? '?'
	);
</script>

<div class="flex min-h-screen flex-col">
	<header
		class="bg-background/80 supports-[backdrop-filter]:bg-background/70 sticky top-0 z-30 border-b border-transparent backdrop-blur"
	>
		<div class="mx-auto flex h-14 w-full max-w-5xl items-center gap-3 px-4">
			<a href="/" class="flex items-center gap-2">
				<span
					class="bg-primary text-primary-foreground flex size-7 items-center justify-center rounded-lg"
				>
					<span class="font-display text-xl leading-none italic">R</span>
				</span>
				<Wordmark size={22} />
			</a>

			<nav class="ml-auto hidden items-center gap-1 sm:flex">
				{#each navItems as item}
					{@const isActive = $page.url.pathname.startsWith(item.href)}
					<Button
						href={item.href}
						variant={item.primary ? 'default' : isActive ? 'secondary' : 'ghost'}
						size="sm"
					>
						<item.icon class="size-4" />
						<span>{item.label}</span>
					</Button>
				{/each}
			</nav>

			{#if user}
				<DropdownMenu>
					<DropdownMenuTrigger>
						<Avatar class="size-8 cursor-pointer">
							<AvatarFallback>{initials}</AvatarFallback>
						</Avatar>
					</DropdownMenuTrigger>
					<DropdownMenuContent align="end" class="w-56">
						<DropdownMenuLabel>
							<div class="flex flex-col">
								<span class="text-sm font-medium">{user.email}</span>
								<span class="text-muted-foreground text-xs">Signed in</span>
							</div>
						</DropdownMenuLabel>
						<DropdownMenuSeparator />
						<DropdownMenuItem>
							<a href="/settings" class="flex w-full items-center gap-2"
								><Settings class="size-4" /> Settings</a
							>
						</DropdownMenuItem>
						<DropdownMenuItem>
							<a href="/logout" class="flex w-full items-center gap-2"
								><LogOut class="size-4" /> Log out</a
							>
						</DropdownMenuItem>
					</DropdownMenuContent>
				</DropdownMenu>
			{:else}
				<Button href="/login" size="sm" variant="outline">Sign in</Button>
			{/if}
		</div>
	</header>

	<main class="mx-auto w-full max-w-5xl flex-1 px-4 pt-4 pb-20 sm:px-6 sm:pb-8">
		{@render children()}
	</main>

	<nav
		class="bg-background/95 border-border supports-[backdrop-filter]:bg-background/70 fixed inset-x-0 bottom-0 z-30 grid grid-cols-4 border-t backdrop-blur sm:hidden"
	>
		{#each navItems as item}
			{@const isActive = $page.url.pathname.startsWith(item.href)}
			<a
				href={item.href}
				class="text-muted-foreground relative flex flex-col items-center justify-center gap-0.5 py-2.5 text-[10.5px] font-medium {isActive
					? 'text-primary'
					: ''}"
				aria-current={isActive ? 'page' : undefined}
			>
				{#if isActive}
					<span class="bg-primary absolute top-0 h-0.5 w-6 rounded-full"></span>
				{/if}
				<item.icon class="size-5 {item.primary && !isActive ? 'text-primary' : ''}" />
				<span>{item.label}</span>
			</a>
		{/each}
	</nav>
</div>
