export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isRetryableLinearError(error: unknown): boolean {
  if (!error || typeof error !== "object") {
    return false;
  }
  const maybe = error as {
    status?: number;
    response?: { status?: number };
    type?: string;
    message?: string;
  };
  const status = maybe.status ?? maybe.response?.status;
  if (status === 429 || status === 502 || status === 503 || status === 504) {
    return true;
  }
  const message = (maybe.message ?? "").toLowerCase();
  if (message.includes("bad gateway") || message.includes("timeout")) {
    return true;
  }
  return false;
}

export async function withLinearRetry<T>(
  op: () => Promise<T>,
  label: string,
  maxAttempts: number = 5
): Promise<T> {
  let attempt = 1;
  while (true) {
    try {
      return await op();
    } catch (error) {
      if (attempt >= maxAttempts || !isRetryableLinearError(error)) {
        throw error;
      }
      const delayMs = Math.min(2000 * attempt, 10000);
      console.warn(
        `[retry] ${label} failed (attempt ${attempt}/${maxAttempts}), waiting ${delayMs}ms...`
      );
      await sleep(delayMs);
      attempt += 1;
    }
  }
}

