// Test inputs intentionally include invalid values; validators accept unknown data.
interface FindingBase {
  verdict: string;
  fingerprint: string;
  title: string;
  description: string;
  trace: { kind: string; file: string; line: number; scope: string; description: string }[];
  evidence: { file: string; line: number; description: string }[];
}
export interface Confirmed extends FindingBase {
  root_cause: string;
  intended_behavior: string;
  conditions: { kind: string; description: string }[];
  execution: {
    attacker_perspective: string;
    payloads: string[];
    instructions: string[];
    observed_result: string;
    [extra: `extra-${string}`]: unknown;
  };
  remediation: { strategy: string; code_changes?: { file_name: string; fixed_code: string }[] };
  severity: {
    likelihood: { score: string; reason: string };
    impact: { score: string; reason: string };
    overall_severity: string;
  };
  confidence: { score: string; reason: string };
}
export interface NeedsValidation extends FindingBase {
  claimed_root_cause: string;
  blockers: string[];
  validation_plan: { local?: string; deployment?: string };
}
export interface CanonicalRefs {
  surface: string;
  boundary: string;
  subsystem: string;
  attack_class: string;
  lifecycle?: string;
}
export interface Check {
  agent_id: string | null;
  reviewed_paths: string[];
  invariant: string;
  method: string;
  result: string;
  artifact: string | null;
}
export interface Attempt {
  wave: number;
  status: string;
  agent_id: string | null;
  reviewed_paths: string[];
  local_checks: Check[];
  result_fingerprints: string[];
  unresolved: string[];
  reassignment_reason: string;
}
export interface CoverageUnit extends Omit<Attempt, "reassignment_reason"> {
  coverage_id: string;
  canonical_refs: CanonicalRefs;
  surface: string;
  boundary: string;
  subsystem: string;
  attack_class: string;
  starting_paths: string[];
  ordinary_attack_class_block: string;
  selected_companion_blocks: string[];
  excluded_blocks: { block: string; reason: string }[];
  prior_status: string;
  attempts?: Attempt[];
}
interface SharedValidator {
  VISIBLE_CONTENT: RegExp;
  PATH_FORBIDDEN_CHARACTER: RegExp;
  WINDOWS_RESERVED_COMPONENT: RegExp;
  UNSAFE_DIAGNOSTIC_CHARACTER: RegExp;
  LIMITS: Readonly<Record<string, number>>;
  hasVisibleProse(value: unknown): boolean;
}
export interface FindingsValidator extends SharedValidator {
  collect(value: unknown, schema: unknown, path?: string): string[];
  collectSchemaErrors(schema: unknown): string[];
  validateDocument(value: unknown, schema: unknown): string[];
  isSafeRelativeSourcePath(value: unknown): boolean;
}
export interface LedgerValidator extends SharedValidator {
  canonicalCoverageId(refs: CanonicalRefs): string;
  encodeCanonicalRef(value: string): string;
  isSafeAgentId(value: unknown): boolean;
  isSafeRelativePath(value: unknown): boolean;
  preflightJsonText(value: string): void;
  validateDocument(value: unknown): string[];
}
