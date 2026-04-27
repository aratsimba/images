# Slide Deck Generation Instructions

Read the spec's design.md file and convert it into a lecture-style slide deck that helps beginners understand the spec before implementation.

## Target Audience
- Beginners learning AWS services for the first time
- Add short parenthetical explanations for technical terms, e.g. "IAM Role (a permission badge for AWS services)"
- Use real-world analogies to explain abstract concepts

## Output Format
- Separate slides with --- on its own line
- Aim for 12-15 slides
- Each slide title must use a single # (h1), not ## or ###
- If the output file already exists, overwrite it completely with the new content

## Slide Structure (follow this order)

1. **Title Slide** — Topic name + one-sentence summary of what the learner will build
2. **The Problem** — What challenge does this spec solve? Describe a Before scenario (without this) vs After scenario (with this)
3. **Key Concepts (1-3 slides)** — One concept per slide with a real-world analogy and a short definition
4. **Architecture Overview** — Mermaid diagram showing how components connect, with a brief walkthrough
5. **Component Deep Dive (2-3 slides)** — Each major component: what it does, why it matters, and how it fits the whole
6. **How It Works** — Step-by-step data/request flow with a Mermaid sequence or flow diagram
7. **Code Snapshot (1-2 slides)** — Short, annotated code snippets (max 8 lines each) showing the most important patterns
8. **Common Pitfalls** — 3-4 mistakes beginners make, each with a one-line fix
9. **Summary** — 3 key takeaways as bullet points + a "What's Next?" pointer to the implementation tasks

## Content Style
- Write as a friendly lecture — explain each topic as if teaching step by step
- Each slide: bold title + 4-6 detailed bullets in complete sentences
- Use comparison tables for contrasting options (e.g. S3 Standard vs Glacier)
- Use blockquote Key Insight boxes (> **Key Insight:** ...) for important takeaways
- Prefer diagrams over text walls — if a concept can be drawn, draw it

## Mermaid Rules
- Use SHORT labels (max 2-3 words per node, e.g. "Create Bucket" not "BucketCreationManager")
- Use line breaks with <br/> if needed
- Keep diagrams simple — max 6-8 nodes
- Use at least 2 diagrams across the deck (architecture + flow)

## Completion
After creating the file, tell the user: "Slide deck is ready! Click the Show Slides button to view."
