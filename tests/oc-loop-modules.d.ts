// Narrow contracts for the unchanged JavaScript modules exercised by this suite.
declare module "*oc-loop-autonomy.mjs" {
  export interface Question {
    question?: string
    header?: string
    multiple?: boolean
    options: { label: string; description?: string }[]
  }
  export interface PendingRequest {
    id: string
    sessionID: string
    permission?: string
    patterns?: string[]
    questions?: Question[]
  }
  export type AutonomyEvent =
    | { type: "permission.asked" | "question.asked"; properties: PendingRequest }
    | { type: "session.created"; properties: { info: { id: string; parentID: string } } }
    | {
        type: "message.updated"
        properties: { info: { sessionID: string; role: string; error: { name: string } } }
      }
  export interface GetRequest {
    url: string
    path: { sessionID?: string }
    query: { directory: string }
    throwOnError: boolean
  }
  export interface PostRequest {
    url: string
    path: { requestID: string }
    query: { directory: string }
    body: { reply?: string; answers?: string[][] }
    bodySerializer: typeof JSON.stringify
    headers: Record<string, string>
    throwOnError: boolean
  }
  export interface AutonomyContext {
    directory: string
    client: {
      _client?: {
        get(request: GetRequest): Promise<{ data?: unknown; error?: unknown }>
        post?(request: PostRequest): Promise<{ data?: unknown; error?: unknown }>
      }
      question?: {
        reply(
          input: { requestID: string; directory: string; answers?: string[][] },
          options: { throwOnError: boolean }
        ): Promise<unknown>
      }
    }
  }
  export interface AutonomyOptions {
    sessionID: string
    controlFile?: string
    runId?: string
  }
  export interface AutonomyHooks {
    event(input: { event: AutonomyEvent }): Promise<void>
    "chat.message"(
      input: { sessionID: string },
      output: { parts: { type: string; text: string }[] }
    ): Promise<void>
  }
  export default function autonomy(
    context: AutonomyContext,
    options: AutonomyOptions
  ): Promise<AutonomyHooks>
}
declare module "*oc-loop-tui.mjs" {
  export interface Alert {
    title: string
    message: string
  }
  export interface KeymapLayer {
    commands: { name: string; run(): void | Promise<void> }[]
    bindings: { key: string; cmd: string; desc: string }[]
  }
  const plugin: {
    tui(
      api: {
        route: { current: { name: string; params: { sessionID: string } } }
        keymap: { registerLayer(value: KeymapLayer): () => void }
        lifecycle: { onDispose(fn: () => void): void }
        ui: {
          dialog: { replace(render: () => unknown): unknown }
          DialogAlert(value: Alert): unknown
        }
      },
      options: { directory: string; session: string; runId: string }
    ): Promise<void>
  }
  export default plugin
}
declare module "*oc-loop-runtime.mjs" {
  export interface RuntimeConfig {
    dir: string
    session: string
    configContent?: string
  }
  export interface RuntimeState {
    id: string
    helperReady?: boolean
    record(row: unknown): void
    activity(): void
  }
  export interface Transport {
    directory: string
    url: string
    env: { OPENCODE_SERVER_PASSWORD: string }
    error?: Error
    busy(): Promise<boolean>
    aborted(): Promise<boolean>
    ownerGate(since: number): Promise<string | undefined>
    close(): Promise<void>
  }
  export function prepare(config: RuntimeConfig): { directory: string }
  export function startServer(
    config: RuntimeConfig,
    state: RuntimeState,
    signal: AbortSignal
  ): Promise<Transport>
  export function request(
    config: RuntimeConfig,
    credentials: { url: string; password: string },
    path: string
  ): Promise<{ id: string }>
}
