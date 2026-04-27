<script lang="ts">
	let { size = 22, accent = false }: { size?: number; accent?: boolean } = $props();
</script>

<span
	class="font-display leading-none"
	style:font-size="{size}px"
	style:color={accent ? 'var(--primary)' : 'currentColor'}
>
	Recipe<span class="italic">Joe</span>
</span>
