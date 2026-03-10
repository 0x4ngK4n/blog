# exploit dev — Blog Workflow

## Write a New Post

```bash
cd ~/blog
hugo new content posts/your-post-title.md
```

Edit the file at `content/posts/your-post-title.md`:

```markdown
+++
title = "Your Post Title"
date = "2026-03-10"
draft = false
+++

Write your content here in **Markdown**.

Code block:
    ```shell
    echo "hello"
    ```

Image (place file in content/posts/ first):
    ![alt text](./image.png)
```

Set `draft = false` when ready to publish.

---

## Preview Locally

```bash
cd ~/blog
hugo server --buildDrafts
```

Open http://localhost:1313 in browser. Live-reloads on save.

---

## Publish

```bash
cd ~/blog
./publish.sh "your commit message"
```

Live at https://0x4ngk4n.github.io within seconds.

---

## Useful Markdown

| What           | Syntax                        |
|----------------|-------------------------------|
| Bold           | `**text**`                    |
| Italic         | `*text*`                      |
| Strikethrough  | `~~text~~`                    |
| Inline code    | `` `code` ``                  |
| Link           | `[label](url)`                |
| Image          | `![alt](./filename.png)`      |
| Code block     | ` ```lang ` ... ` ``` `       |
| Heading        | `## Heading`                  |
| List           | `- item`                      |

---

## Repo Layout

```
~/blog/                        ← write here
  content/posts/               ← your .md files + images go here
  themes/terminal/             ← theme (don't touch)
  hugo.toml                    ← site config
  publish.sh                   ← build + push script

~/0x4ngk4n.github.io/         ← auto-generated, don't edit manually
```
