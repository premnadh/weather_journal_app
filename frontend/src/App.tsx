
import { useCallback, useEffect, useState, type FormEvent } from "react";
import "./App.css";

const API_URL = "http://127.0.0.1:8000";

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

async function fetchEntries(): Promise<JournalEntry[]> {
  const response = await fetch(`${API_URL}/api/entries`);

  if (!response.ok) {
    throw new Error("Could not load journal entries.");
  }

  return response.json() as Promise<JournalEntry[]>;
}

function App() {
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [form, setForm] = useState<EntryForm>(initialForm);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const loadEntries = useCallback(async () => {
    try {
      const data = await fetchEntries();
      setEntries(data);
      setError("");
    } catch {
      setError("Cannot connect to the journal API. Is the backend running?");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function loadInitialEntries() {
      try {
        const data = await fetchEntries();

        if (!cancelled) {
          setEntries(data);
          setError("");
        }
      } catch {
        if (!cancelled) {
          setError("Cannot connect to the journal API. Is the backend running?");
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
  }, []);

  function updateField(field: keyof EntryForm, value: string) {
    setForm((current) => ({ ...current, [field]: value }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSaving(true);
    setError("");
    setMessage("");

    const wasEditing = editingId !== null;

    try {
      const url = wasEditing
        ? `${API_URL}/api/entries/${editingId}`
        : `${API_URL}/api/entries`;

      const response = await fetch(url, {
        method: wasEditing ? "PATCH" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });

      if (!response.ok) {
        const result = await response.json().catch(() => null);
        const detail = result?.detail;
        const errorMessage =
          typeof detail === "string"
            ? detail
            : Array.isArray(detail)
              ? detail.map((item: { msg?: string }) => item.msg ?? "").join(" ")
              : "Could not save the entry. Please check your details.";

        throw new Error(errorMessage);
      }

      setForm(initialForm);
      setEditingId(null);
      setMessage(wasEditing ? "Entry updated successfully." : "Your moment has been saved.");

      await loadEntries();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
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
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function cancelEditing() {
    setEditingId(null);
    setForm(initialForm);
    setError("");
    setMessage("");
  }

  async function deleteEntry(id: number) {
    if (!window.confirm("Delete this journal entry?")) {
      return;
    }

    setError("");
    setMessage("");

    try {
      const response = await fetch(`${API_URL}/api/entries/${id}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        throw new Error("Could not delete the entry.");
      }

      if (editingId === id) {
        cancelEditing();
      }

      setMessage("Entry deleted successfully.");
      await loadEntries();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    }
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <a className="brand" href="/" aria-label="Daylight Journal home">
          <span className="brand-icon">☀</span>
          <span>
            daylight <span className="brand-light">journal</span>
          </span>
        </a>
        <span className="topbar-label">YOUR PERSONAL WEATHER DIARY</span>
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
          ☁️ ☀️ ☁️
        </div>
      </section>

      <section className="content-grid">
        <div className="editor-panel">
          <div className="section-heading">
            <div>
              <p className="eyebrow">
                {editingId !== null ? "MAKE A CHANGE" : "PAUSE & REFLECT"}
              </p>
              <h2>{editingId !== null ? "Edit your entry" : "Today's journal"}</h2>
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
                  onChange={(event) => updateField("weather", event.target.value)}
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

            <button className="primary-button" type="submit" disabled={saving}>
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
              <p>Your saved entries will appear here. Make your first moment count.</p>
            </div>
          ) : (
            <div className="entry-list">
              {entries.map((entry) => (
                <article className="entry-card" key={entry.id}>
                  <div className="entry-card-top">
                    <span className="weather-pill">
                      {weatherEmoji(entry.weather)} {entry.weather || "No weather"}
                    </span>
                    <span className="mood-pill">
                      {moodEmoji(entry.mood)} {entry.mood}
                    </span>
                  </div>

                  <h3>{entry.title}</h3>
                  <p className="entry-date">
                    {new Date(entry.created_at).toLocaleString(undefined, {
                      dateStyle: "medium",
                      timeStyle: "short",
                    })}
                  </p>

                  {entry.content && (
                    <p className="entry-content">{entry.content}</p>
                  )}

                  <div className="entry-actions">
                    <button type="button" onClick={() => editEntry(entry)}>
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
