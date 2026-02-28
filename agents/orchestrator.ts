import type { AgentHarness, AgentTask, AgentResult } from './harness/harness-interface.ts';
import { ClaudeCodeHarness } from './harness/claude-code-harness.ts';
export type { AgentTask, AgentResult };

export function loadHarness(): AgentHarness {
	return new ClaudeCodeHarness();
}

async function main() {
	const harness = loadHarness();
	const available = await harness.isAvailable();
	if (!available) {
		console.warn("Harness is not available.");
	}

	await harness.deploy({ id: "1", payload: "test" });
}

main().catch(console.error);
