export type AgentTask = { id: string, payload: any };
export type AgentResult = { id: string, success: boolean };

export interface AgentHarness {
	deploy(task: AgentTask): Promise<AgentResult>;
	isAvailable(): Promise<boolean>;
}
