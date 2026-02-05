# RAE-Functional-Scraper

A functional web scraper built in **Racket** that extracts definitions, etymology, synonyms, and antonyms directly from the [Real Academia Española (RAE)](https://dle.rae.es/) dictionary.

The project processes natural language text, tokenizes it, and queries the RAE database to generate a structured list of linguistic data using S-Expressions (SXML).

## Features
* **HTML Parsing to SXML:** Converts raw HTML into Scheme XML (SXML) for functional traversing using `sxpath`.
* **Natural Language Processing:** Tokenizes input strings and filters "stop words" and punctuation.
* **Data Extraction:** Scrapes specific DOM elements (definitions, abbreviations, synonyms).
* **Recursive Logic:** Handles navigational structures and list processing purely with recursion and higher-order functions (`map`, `filter`).

## 🛠️ Tech Stack
* **Language:** Racket (Scheme dialect)
* **Paradigm:** Functional Programming
* **Libraries:** `html-parsing`, `net/url`, `sxml`

## 📦 Installation & Usage

1. **Prerequisites:** Ensure you have [Racket](https://racket-lang.org/) installed.
2. **Install Dependencies:**
   ```bash
   raco pkg install html-parsing
   raco pkg install sxml
