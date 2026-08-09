use maud::{DOCTYPE, Markup, PreEscaped, html};
use std::{env, fs, io, path::PathBuf};

const IMAGE: &[u8] = include_bytes!("../assets/418.png");

const STYLE: &str = r#"
:root {
  color-scheme: dark;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
  background: #000;
  color: #f5f5f5;
}

* {
  box-sizing: border-box;
}

body {
  min-height: 100svh;
  margin: 0;
  background: #000;
}

.page {
  width: min(100% - 2rem, 48rem);
  margin-inline: auto;
  padding-block: clamp(1rem, 4vw, 3rem) 3rem;
}

.toolbar {
  display: flex;
  justify-content: flex-end;
  margin-bottom: 1rem;
}

.language-toggle {
  appearance: none;
  border: 0;
  padding: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
  text-decoration-line: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 0.25em;
}

.language-toggle:hover {
  color: #cfcfcf;
}

.language-toggle:focus-visible {
  outline: none;
  text-decoration-thickness: 2px;
}

.meme {
  display: block;
  width: 100%;
  height: auto;
  border: 1px solid #444;
}

.copy {
  width: min(100%, 42rem);
  margin: clamp(1.5rem, 5vw, 3rem) auto 0;
}

h1 {
  margin: 0 0 1rem;
  font-size: clamp(1.65rem, 5vw, 2.5rem);
  line-height: 1.1;
  letter-spacing: -0.04em;
}

p {
  margin: 0 0 1rem;
  color: #d1d1d1;
  font-size: clamp(0.95rem, 2.5vw, 1.05rem);
  line-height: 1.7;
}

a {
  color: #fff;
  text-underline-offset: 0.2em;
}

a:hover {
  color: #cfcfcf;
}

.footnote {
  margin-top: 1.75rem;
  color: #888;
  font-size: 0.82rem;
}

[hidden] {
  display: none !important;
}

@media (max-width: 34rem) {
  .page {
    width: min(100% - 1rem, 48rem);
  }

  .copy {
    padding-inline: 0.5rem;
  }
}
"#;

const SCRIPT: &str = r#"
const toggle = document.querySelector("[data-language-toggle]");
const copies = [...document.querySelectorAll("[data-language]")];

const normalizeLanguage = (language) => {
  const primary = language.toLowerCase().split("-")[0];
  return primary === "ca" ? "ca" : "en";
};

const showLanguage = (language) => {
  document.documentElement.lang = language;

  for (const copy of copies) {
    const isCurrent = copy.dataset.language === language;
    copy.hidden = !isCurrent;

    if (isCurrent) {
      document.title = copy.dataset.title;
    }
  }

  toggle.textContent = language === "ca" ? "English" : "Català";
  toggle.setAttribute(
    "aria-label",
    language === "ca" ? "Switch to English" : "Canvia al català",
  );
};

showLanguage(normalizeLanguage(navigator.language || "en"));

toggle?.addEventListener("click", () => {
  showLanguage(document.documentElement.lang === "ca" ? "en" : "ca");
});
"#;

#[derive(Clone, Copy)]
struct Copy {
    language: &'static str,
    heading: &'static str,
    introduction: &'static str,
    history: &'static str,
    cat: &'static str,
    source_label: &'static str,
}

const CATALAN: Copy = Copy {
    language: "ca",
    heading: "418 — Sóc una tetera",
    introduction: "El codi d'estat HTTP 418 indica que el servidor es nega a preparar cafè perquè és, de manera permanent, una tetera.",
    history: "Va néixer com una broma del protocol Hyper Text Coffee Pot Control Protocol, publicat l'1 d'abril de 1998.",
    cat: "Aquest gat tampoc no prepara cafè.",
    source_label: "Llegiu l'especificació",
};

const ENGLISH: Copy = Copy {
    language: "en",
    heading: "418 — I'm a teapot",
    introduction: "The HTTP 418 status code means the server refuses to brew coffee because it is, permanently, a teapot.",
    history: "It began as an April Fools' joke in the Hyper Text Coffee Pot Control Protocol, published in 1998.",
    cat: "This cat does not brew coffee either.",
    source_label: "Read the specification",
};

fn copy(copy: Copy, hidden: bool) -> Markup {
    html! {
        section.copy
            data-language=(copy.language)
            data-title=(copy.heading)
            lang=(copy.language)
            hidden[hidden]
        {
            h1 { (copy.heading) }
            p { (copy.introduction) }
            p { (copy.history) }
            p { (copy.cat) }
            p.footnote {
                a href="https://www.rfc-editor.org/rfc/rfc2324"
                    rel="external noreferrer"
                {
                    (copy.source_label)
                }
            }
        }
    }
}

fn page() -> Markup {
    html! {
        (DOCTYPE)
        html lang="ca" {
            head {
                meta charset="utf-8";
                meta name="viewport" content="width=device-width, initial-scale=1";
                meta name="color-scheme" content="dark";
                meta name="theme-color" content="#000000";
                meta
                    name="description"
                    content="418.cat: un gat dins d'una tetera i una breu història del codi HTTP 418.";
                meta property="og:type" content="website";
                meta property="og:title" content="418 — Sóc una tetera";
                meta
                    property="og:description"
                    content="Un gat dins d'una tetera i la història breu del codi HTTP 418.";
                meta property="og:image" content="https://418.cat/418.png";
                meta property="og:url" content="https://418.cat/";
                link rel="canonical" href="https://418.cat/";
                title { "418 — Sóc una tetera" }
                style { (PreEscaped(STYLE)) }
            }
            body {
                main.page {
                    nav.toolbar aria-label="Language" {
                        button.language-toggle
                            type="button"
                            data-language-toggle
                            aria-label="Switch to English"
                        {
                            "English"
                        }
                    }
                    img.meme
                        src="/418.png"
                        width="752"
                        height="564"
                        alt="Un gat petit dins d'una tetera blanca, amb el número 418";
                    (copy(CATALAN, false))
                    (copy(ENGLISH, true))
                }
                script { (PreEscaped(SCRIPT)) }
            }
        }
    }
}

fn output_directory() -> PathBuf {
    env::args_os()
        .nth(1)
        .map_or_else(|| PathBuf::from("dist"), PathBuf::from)
}

fn main() -> io::Result<()> {
    let output = output_directory();
    fs::create_dir_all(&output)?;
    fs::write(output.join("index.html"), page().into_string())?;
    fs::write(output.join("418.png"), IMAGE)
}
