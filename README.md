# TranslateSayings
🌐 **Live Site:** https://translatesayings.com
A crowdsourced, meaning-focused translation platform for proverbs and sayings.

[![codecov](https://codecov.io/gh/jamesjason/translate_sayings/graph/badge.svg?token=CHZTOBY8AT)](https://codecov.io/gh/jamesjason/translate_sayings)

## Overview

**TranslateSayings** lets you search for a saying in one language and find the closest matching saying in another.
It focuses on **preserving meaning**, not literal word-for-word translation.

Users can:
- Search for a saying and see the best equivalent expressions in the target language.
- Upvote/downvote translation pairs so the best translations rise to the top.
- Contribute new translation pairs.


---

## Features

### 🔍 Natural Saying Translation
Enter a proverb in one language and see the meaning-equivalent expression used by native speakers in another.

### 👍 Community Voting
Each translation pair can be upvoted or downvoted, ensuring the highest-quality matches appear first.

### ➕ Contribute New Translations
Users can submit new translations.
Submissions then enter a **review queue** and are added to the public dataset after approval.


---

## Tech Stack

**Backend**
- Ruby on Rails 8
- PostgreSQL
- Devise for authentication
- OmniAuth (Google)
- RSpec for testing

**Frontend**
- Turbo / Stimulus (Hotwire)
- TailwindCSS
- ESBuild / Importmap

**Testing**
- RSpec system tests with Capybara + Selenium
- FactoryBot
- Codecov integration

---

## Setup

### Prerequisites
- Ruby 3.4+
- PostgreSQL
- Node/Yarn (if building Tailwind via JS)

### Install

```bash
bundle install
rails db:create db:migrate db:seed
