import {
  createApiRef,
  DiscoveryApi,
  FetchApi,
} from '@backstage/core-plugin-api';

/** A single lab result within a belt. */
export interface LabResult {
  /** Lab identifier, e.g. "lab-01" */
  id: string;
  /** Display label, e.g. "Lab 01 — First Deployment" */
  label: string;
  /** "PASS" | "FAIL" | "PENDING" */
  status: 'PASS' | 'FAIL' | 'PENDING';
}

/** Progress for one belt level. */
export interface BeltProgress {
  /** Belt name: "white" | "yellow" | "green" | "brown" | "black" */
  belt: string;
  /** Display colour for UI chips, e.g. "#f5f5f5" */
  colour: string;
  /** Emoji icon for the belt row */
  icon: string;
  /** 0-100 completion percentage (PASS labs / total labs * 100) */
  completionPct: number;
  /** Individual lab results */
  labs: LabResult[];
}

/** Full dojo progress for a single learner. */
export interface DojoProgress {
  /** GitHub username */
  username: string;
  /** One entry per belt, ordered white → black */
  belts: BeltProgress[];
  /** ISO 8601 timestamp of the last update */
  lastUpdated: string;
}

/** API reference for the DojoProgress plugin. */
export const dojoProgressApiRef = createApiRef<DojoProgressApi>({
  id: 'plugin.dojo-progress.service',
});

/** Contract the plugin uses to fetch dojo progress data. */
export interface DojoProgressApi {
  /**
   * Fetch progress for a given GitHub username.
   * Returns null when the user has no entry in the ConfigMap yet.
   */
  getProgress(username: string): Promise<DojoProgress | null>;
}

/** Default implementation — reads from the Backstage proxy endpoint. */
export class DojoProgressClient implements DojoProgressApi {
  private readonly discoveryApi: DiscoveryApi;
  private readonly fetchApi: FetchApi;

  constructor(options: { discoveryApi: DiscoveryApi; fetchApi: FetchApi }) {
    this.discoveryApi = options.discoveryApi;
    this.fetchApi = options.fetchApi;
  }

  async getProgress(username: string): Promise<DojoProgress | null> {
    const baseUrl = await this.discoveryApi.getBaseUrl('proxy');
    const url = `${baseUrl}/dojo/progress`;

    const response = await this.fetchApi.fetch(url);

    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error(
        `Failed to fetch dojo progress: ${response.status} ${response.statusText}`,
      );
    }

    // The proxy returns the raw Kubernetes ConfigMap JSON.
    // We extract and parse the per-user YAML/JSON value.
    const configMap = await response.json();
    const data: Record<string, string> = configMap?.data ?? {};
    const raw = data[username];

    if (!raw) {
      return null;
    }

    // Use the ConfigMap's last modification time from Kubernetes metadata.
    const lastUpdated: string =
      configMap?.metadata?.managedFields?.[0]?.time ??
      configMap?.metadata?.creationTimestamp ??
      new Date().toISOString();

    return parseProgressEntry(username, raw, lastUpdated);
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

const BELT_META: Array<{ belt: string; colour: string; icon: string }> = [
  { belt: 'white', colour: '#f5f5f5', icon: '🥋' },
  { belt: 'yellow', colour: '#fdd835', icon: '🟡' },
  { belt: 'green', colour: '#43a047', icon: '🟢' },
  { belt: 'brown', colour: '#6d4c41', icon: '🟤' },
  { belt: 'black', colour: '#212121', icon: '⚫' },
];

/**
 * Parse a JSON progress string stored in the ConfigMap.
 *
 * Expected format (JSON string per username key):
 * {
 *   "white":  { "labs": { "lab-01": "PASS", "lab-02": "FAIL" } },
 *   "yellow": { "labs": {} },
 *   ...
 * }
 */
function parseProgressEntry(
  username: string,
  raw: string,
  lastUpdated: string,
): DojoProgress {
  let parsed: Record<string, { labs: Record<string, string> }> = {};

  try {
    parsed = JSON.parse(raw);
  } catch {
    // Gracefully handle corrupt data — treat as empty progress.
  }

  const belts: BeltProgress[] = BELT_META.map(({ belt, colour, icon }) => {
    const beltData = parsed[belt] ?? { labs: {} };
    const labEntries = Object.entries(beltData.labs ?? {}).map(
      ([id, status]) => ({
        id,
        label: `Lab ${id.replace('lab-', '')}`,
        status: (status as LabResult['status']) ?? 'PENDING',
      }),
    );

    const total = labEntries.length;
    const passed = labEntries.filter(l => l.status === 'PASS').length;
    const completionPct = total > 0 ? Math.round((passed / total) * 100) : 0;

    return { belt, colour, icon, completionPct, labs: labEntries };
  });

  return {
    username,
    belts,
    lastUpdated,
  };
}
