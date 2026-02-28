import { AgentHarness, AgentTask, AgentResult } from './harness-interface.ts';

export class ClaudeCodeHarness implements AgentHarness {
	async deploy(task: AgentTask): Promise<AgentResult> {
		return { id: task.id, success: true };
	}

	async isAvailable(): Promise<boolean> {
		try {
			const proc = Bun.spawn(['claude', '--version']);
			await proc.exited;
			return proc.exitCode === 0;
		} catch (e) {
			return false;
		}
	}
}
