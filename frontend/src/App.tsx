import { useCallback, useEffect, useState, type FormEvent } from "react";
import "./App.css";

const API_URL = "";

type JournalEntry = {
  id: number;
  title: string;
  content: string;
  mood: string;
  weather: string;
  created_at: string;
};

type EntryForm = {
  title: string;
  content: string;
  mood: string;
  weather: string;
};

const initialForm: EntryForm = {
  title: "",
  content: "",
  mood: "happy",
  weather: "Sunny",
};

async function readError(response: Response): Promise<string> {
  const result = await response.json().catch(() => null);
  const detail = result?.detail;

  if (typeof detail === "string") {
    return detail;
  }

  if (Array.isArray(detail)) {
    return detail
      .map((item: { msg?: string }) => item.msg ?? "")
      .join(" ");
  }

  return "Something went wrong. Please try again.";
}

/**
 * Requests use the browser's session cookie instead of a JWT
 * stored in React state or browser-accessible storage.
 */
async function apiFetch(
  url: string,
  options: RequestInit = {},
): Promise<Response> {
  return fetch(url, {
    ...options,
    credentials: "include",
  });
}

type AuthScreenProps = {
  onAuthenticated: () => void;
  notice: string;
};

function AuthScreen({ onAuthenticated, notice }: AuthScreenProps) {
  const [mode, setMode] = useState<"login" | "register">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    setBusy(true);
    setError("");
    setMessage("");

    try {
      if (mode === "register") {
        const registration = await apiFetch(
          `${API_URL}/api/auth/register`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              email,
              password,
            }),
          },
        );

        if (!registration.ok) {
          throw new Error(await readError(registration));
        }

        setMode("login");
        setPassword("");
        setMessage(
          "Account created. Sign in to open your journal.",
        );

        return;
      }

      const response = await apiFetch(
        `${API_URL}/api/auth/login`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            email,
            password,
          }),
        },
      );

      if (!response.ok) {
        throw new Error(await readError(response));
      }

      // The backend sets the HttpOnly session cookie.
      // Do not store or read the access token in JavaScript.
      onAuthenticated();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Unable to sign in.",
      );
    } finally {
      setBusy(false);
    }
  }

  function changeMode(nextMode: "login" | "register") {
    setMode(nextMode);
    setError("");
    setMessage("");
  }

  return (
    <main className="auth-shell">
      <header className="topbar">
        <a
          className="brand"
          href="/"
          aria-label="Daylight Journal home"
        >
          <span className="brand-icon">☀</span>
          <span>
            daylight <span className="brand-light">journal</span>
          </span>
        </a>

        <span className="topbar-label">
          YOUR PERSONAL WEATHER DIARY
        </span>
      </header>

      <section className="auth-layout">
        <div className="auth-intro">
          <p className="eyebrow">A LITTLE SPACE FOR YOURSELF</p>

          <h1>
            Every day has
            <br />
            <span>a story.</span>
          </h1>

          <p className="hero-copy">
            Capture the moments, moods and weather that make
            each day yours. Your journal is personal, just like
            your story.
          </p>

          <div className="auth-decoration" aria-hidden="true">
            <span>☁️</span>
            <span>☀️</span>
            <span>☁️</span>
          </div>
        </div>

        <section className="auth-card">
          <div className="section-heading">
            <div>
              <p className="eyebrow">
                {mode === "login" ? "WELCOME BACK" : "A NEW CHAPTER"}
              </p>

              <h2>
                {mode === "login"
                  ? "Your journal awaits."
                  : "Create your account."}
              </h2>
            </div>

            <span className="heading-icon">✎</span>
          </div>

          <p className="auth-description">
            {mode === "login"
              ? "Sign in to revisit your favourite moments."
              : "Create a private space for your daily moments."}
          </p>

          {notice && (
            <p className="feedback error" role="status">
              {notice}
            </p>
          )}

          <form
            className="entry-form auth-form"
            onSubmit={handleSubmit}
          >
            <label htmlFor="auth-email">Email address</label>

            <input
              id="auth-email"
              type="email"
              autoComplete="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="you@example.com"
              maxLength={254}
              required
            />

            <label htmlFor="auth-password">Password</label>

            <input
              id="auth-password"
              type="password"
              autoComplete={
                mode === "login" ? "current-password" : "new-password"
              }
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder={
                mode === "register"
                  ? "At least 8 characters"
                  : "Your password"
              }
              minLength={mode === "register" ? 8 : 1}
              maxLength={128}
              required
            />

            {error && (
              <p className="feedback error" role="alert">
                {error}
              </p>
            )}

            {message && (
              <p className="feedback success" role="status">
                {message}
              </p>
            )}

            <button
              className="primary-button"
              type="submit"
              disabled={busy}
            >
              {busy
                ? "Please wait..."
                : mode === "login"
                  ? "Sign in →"
                  : "Create account →"}
            </button>
          </form>

          <p className="auth-switch">
            {mode === "login"
              ? "New to Daylight Journal?"
              : "Already have an account?"}{" "}
            <button
              type="button"
              className="text-button"
              onClick={() =>
                changeMode(mode === "login" ? "register" : "login")
              }
            >
              {mode === "login" ? "Create an account" : "Sign in"}
            </button>
          </p>
        </section>
      </section>

      <footer className="footer">
        <span>Made for the moments in between.</span>
        <span>DAYLIGHT JOURNAL · FULL-STACK EDITION</span>
      </footer>
    </main>
  );
}

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [checkingSession, setCheckingSession] = useState(true);
  const [authNotice, setAuthNotice] = useState("");

  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [form, setForm] = useState<EntryForm>(initialForm);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const expireSession = useCallback(() => {
    setIsAuthenticated(false);
    setEntries([]);
    setForm(initialForm);
    setEditingId(null);
    setAuthNotice("Your session has expired. Please sign in again.");
    setError("");
    setMessage("");
  }, []);

  // Restore the session after a page refresh.
  useEffect(() => {
    let cancelled = false;

    async function restoreSession() {
      try {
        const response = await apiFetch(`${API_URL}/api/auth/me`);

        if (cancelled) {
          return;
        }

        if (response.ok) {
          setIsAuthenticated(true);
          setAuthNotice("");
        } else if (response.status === 401) {
          setIsAuthenticated(false);
        } else {
          setAuthNotice(
            "Unable to verify your session. Please try signing in again.",
          );
        }
      } catch {
        if (!cancelled) {
          setAuthNotice(
            "Unable to connect to the server. Check your connection and try again.",
          );
        }
      } finally {
        if (!cancelled) {
          setCheckingSession(false);
        }
      }
    }

    void restoreSession();

    return () => {
      cancelled = true;
    };
  }, []);

  const loadEntries = useCallback(async () => {
    if (!isAuthenticated) {
      return;
    }

    setLoading(true);

    try {
      const response = await apiFetch(`${API_URL}/api/entries`);

      if (response.status === 401) {
        expireSession();
        return;
      }

      if (!response.ok) {
        throw new Error(await readError(response));
      }

      const data = (await response.json()) as JournalEntry[];

      setEntries(data);
      setError("");
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Could not load entries.",
      );
    } finally {
      setLoading(false);
    }
  }, [isAuthenticated, expireSession]);

  // Load the current user's entries once the session is restored.
  useEffect(() => {
    if (!isAuthenticated) {
      return;
    }

    let cancelled = false;

    async function loadInitialEntries() {
      try {
        const response = await apiFetch(`${API_URL}/api/entries`);

        if (cancelled) {
          return;
        }

        if (response.status === 401) {
          expireSession();
          return;
        }

        if (!response.ok) {
          throw new Error(await readError(response));
        }

        const data = (await response.json()) as JournalEntry[];

        if (!cancelled) {
          setEntries(data);
          setError("");
        }
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof Error
              ? err.message
              : "Could not load entries.",
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }


    void loadInitialEntries();

    return () => {
      cancelled = true;
    };
  }, [isAuthenticated, expireSession]);

  function handleAuthenticated() {
    setIsAuthenticated(true);
    setAuthNotice("");
    setError("");
    setMessage("");
  }

  function updateField(field: keyof EntryForm, value: string) {
    setForm((current) => ({
      ...current,
      [field]: value,
    }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!isAuthenticated) {
      return;
    }

    setSaving(true);
    setError("");
    setMessage("");

    const wasEditing = editingId !== null;

    const url = wasEditing
      ? `${API_URL}/api/entries/${editingId}`
      : `${API_URL}/api/entries`;

    try {
      const response = await apiFetch(url, {
        method: wasEditing ? "PATCH" : "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(form),
      });

      if (response.status === 401) {
        expireSession();
        return;
      }

      if (!response.ok) {
        throw new Error(await readError(response));
      }

      setForm(initialForm);
      setEditingId(null);

      setMessage(
        wasEditing
          ? "Entry updated successfully."
          : "Your moment has been saved.",
      );

      await loadEntries();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Could not save entry.",
      );
    } finally {
      setSaving(false);
    }
  }

  function editEntry(entry: JournalEntry) {
    setEditingId(entry.id);

    setForm({
      title: entry.title,
      content: entry.content,
      mood: entry.mood,
      weather: entry.weather,
    });

    setError("");
    setMessage("");

    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  }

  function cancelEditing() {
    setEditingId(null);
    setForm(initialForm);
    setError("");
    setMessage("");
  }

  async function deleteEntry(id: number) {
    if (!isAuthenticated || !window.confirm("Delete this journal entry?")) {
      return;
    }

    setError("");
    setMessage("");

    try {
      const response = await apiFetch(`${API_URL}/api/entries/${id}`, {
        method: "DELETE",
      });

      if (response.status === 401) {
        expireSession();
        return;
      }

      if (!response.ok) {
        throw new Error(await readError(response));
      }

      if (editingId === id) {
        cancelEditing();
      }

      setMessage("Entry deleted successfully.");
      await loadEntries();
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Could not delete entry.",
      );
    }
  }

  async function logout() {
    try {
      const response = await apiFetch(`${API_URL}/api/auth/logout`, {
        method: "POST",
      });

      if (!response.ok) {
        setError("Could not sign out cleanly. Please try again.");
        return;
      }
    } catch {
      setError("Unable to contact the server to sign out.");
      return;
    }

    setIsAuthenticated(false);
    setEntries([]);
    setForm(initialForm);
    setEditingId(null);
    setLoading(false);
    setSaving(false);
    setError("");
    setMessage("");
    setAuthNotice("");
  }

  if (checkingSession) {
    return (
      <main className="auth-shell">
        <section className="empty-state">
          <p>Checking your session...</p>
        </section>
      </main>
    );
  }

  if (!isAuthenticated) {
    return (
      <AuthScreen
        onAuthenticated={handleAuthenticated}
        notice={authNotice}
      />
    );
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <a
          className="brand"
          href="/"
          aria-label="Daylight Journal home"
        >
          <span className="brand-icon">☀</span>
          <span>
            daylight <span className="brand-light">journal</span>
          </span>
        </a>

        <div className="account-actions">
          <span className="topbar-label">
            YOUR PERSONAL WEATHER DIARY
          </span>

          <button
            className="logout-button"
            type="button"
            onClick={() => void logout()}
          >
            Sign out
          </button>
        </div>
      </header>

      <section className="hero">
        <p className="eyebrow">A LITTLE SPACE FOR YOURSELF</p>

        <h1>
          Every day has
          <br />
          <span>a story.</span>
        </h1>

        <p className="hero-copy">
          Capture the moments, moods and weather that make each day yours.
        </p>

        <div className="hero-decoration" aria-hidden="true">
          <span>☁️</span>
          <span>☀️</span>
          <span>☁️</span>
        </div>
      </section>

      <section className="content-grid">
        <div className="editor-panel">
          <div className="section-heading">
            <div>
              <p className="eyebrow">
                {editingId !== null ? "MAKE A CHANGE" : "PAUSE & REFLECT"}
              </p>

              <h2>
                {editingId !== null ? "Edit your entry" : "Today's journal"}
              </h2>
            </div>

            <span className="heading-icon">✎</span>
          </div>

          <form className="entry-form" onSubmit={handleSubmit}>
            <label htmlFor="title">Give this day a title</label>

            <input
              id="title"
              value={form.title}
              onChange={(event) => updateField("title", event.target.value)}
              placeholder="A day worth remembering..."
              maxLength={120}
              required
            />

            <label htmlFor="content">What happened?</label>

            <textarea
              id="content"
              value={form.content}
              onChange={(event) => updateField("content", event.target.value)}
              placeholder="Write down your thoughts, little wins or big adventures..."
              rows={5}
              maxLength={10000}
            />

            <div className="form-row">
              <div>
                <label htmlFor="mood">Your mood</label>

                <select
                  id="mood"
                  value={form.mood}
                  onChange={(event) => updateField("mood", event.target.value)}
                >
                  <option value="happy">😊 Happy</option>
                  <option value="calm">😌 Calm</option>
                  <option value="focused">🎯 Focused</option>
                  <option value="excited">🤩 Excited</option>
                  <option value="tired">😴 Tired</option>
                  <option value="thoughtful">💭 Thoughtful</option>
                  <option value="neutral">😐 Neutral</option>
                </select>
              </div>

              <div>
                <label htmlFor="weather">Weather</label>

                <select
                  id="weather"
                  value={form.weather}
                  onChange={(event) =>
                    updateField("weather", event.target.value)
                  }
                >
                  <option>Sunny</option>
                  <option>Cloudy</option>
                  <option>Rainy</option>
                  <option>Windy</option>
                  <option>Snowy</option>
                  <option>Stormy</option>
                  <option>Foggy</option>
                  <option>Unknown</option>
                </select>
              </div>
            </div>

            {error && (
              <p className="feedback error" role="alert">
                {error}
              </p>
            )}

            {message && (
              <p className="feedback success" role="status">
                {message}
              </p>
            )}

            <button
              className="primary-button"
              type="submit"
              disabled={saving}
            >
              {saving
                ? "Saving..."
                : editingId !== null
                  ? "Save changes →"
                  : "Save this moment →"}
            </button>

            {editingId !== null && (
              <button
                className="secondary-button"
                type="button"
                onClick={cancelEditing}
              >
                Cancel editing
              </button>
            )}
          </form>
        </div>

        <div className="entries-panel">
          <div className="section-heading">
            <div>
              <p className="eyebrow">YOUR COLLECTION</p>
              <h2>Recent moments</h2>
            </div>

            <span className="count-badge">{entries.length}</span>
          </div>

          {loading ? (
            <div className="empty-state">
              <p>Opening your journal...</p>
            </div>
          ) : entries.length === 0 ? (
            <div className="empty-state">
              <span>📖</span>
              <h3>Your story starts here.</h3>
              <p>
                Your saved entries will appear here. Make your first
                moment count.
              </p>
            </div>
          ) : (
            <div className="entry-list">
              {entries.map((entry) => (
                <article className="entry-card" key={entry.id}>
                  <div className="entry-card-top">
                    <span className="weather-pill">
                      {weatherEmoji(entry.weather)}{" "}
                      {entry.weather || "No weather"}
                    </span>

                    <span className="mood-pill">
                      {moodEmoji(entry.mood)} {entry.mood}
                    </span>
                  </div>

                  <h3>{entry.title}</h3>

                  <p className="entry-date">
                    {new Date(entry.created_at).toLocaleString(
                      undefined,
                      {
                        dateStyle: "medium",
                        timeStyle: "short",
                      },
                    )}
                  </p>

                  {entry.content && (
                    <p className="entry-content">{entry.content}</p>
                  )}

                  <div className="entry-actions">
                    <button
                      type="button"
                      onClick={() => editEntry(entry)}
                    >
                      Edit
                    </button>

                    <button
                      type="button"
                      className="delete-action"
                      onClick={() => void deleteEntry(entry.id)}
                    >
                      Delete
                    </button>
                  </div>
                </article>
              ))}
            </div>
          )}
        </div>
      </section>

      <footer className="footer">
        <span>Made for the moments in between.</span>
        <span>DAYLIGHT JOURNAL · FULL-STACK EDITION</span>
      </footer>
    </main>
  );
}

function weatherEmoji(weather: string) {
  const value = weather.toLowerCase();

  if (value.includes("rain")) return "🌧️";
  if (value.includes("cloud")) return "☁️";
  if (value.includes("snow")) return "❄️";
  if (value.includes("wind")) return "💨";
  if (value.includes("storm")) return "⛈️";
  if (value.includes("fog")) return "🌫️";
  if (value.includes("sun")) return "☀️";

  return "🌤️";
}

function moodEmoji(mood: string) {
  const moods: Record<string, string> = {
    happy: "😊",
    calm: "😌",
    focused: "🎯",
    excited: "🤩",
    tired: "😴",
    thoughtful: "💭",
    neutral: "😐",
  };

  return moods[mood.toLowerCase()] ?? "💛";
}

export default App;