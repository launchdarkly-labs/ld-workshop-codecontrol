---
slug: quiz-experiments
id: uslszdbffjiz
type: quiz
title: 'Quiz: Experiments'
teaser: Check your understanding of experiment design and reading results.
notes:
- type: text
  contents: Quick checkpoint before you ship the winner. One question on what the
    results table is actually telling you.
answers:
- Personalized had more total clicks than Bestsellers.
- Given the data so far, there is at least a 90% probability that Personalized's share
  of shoppers who click a recommendation is higher than Bestsellers' share, so the
  difference is unlikely to be noise.
- 90% of shoppers who saw Personalized clicked a recommendation.
- The experiment has reached 90% of its planned sample size and can be stopped.
solution:
- 1
difficulty: basic
timelimit: 600
enhanced_loading: null
---

Three labs in, the experiment is running and the results table is filling in. The pieces so far:

- A **metric** (`Recs engagement`) defines "better": the percentage of shoppers who clicked a recommended item at least once, higher is better, one vote per shopper.
- The app sends the `recs-engagement` event for the **same context** that evaluated the flag, so every click lands on the right variation.
- The **experiment** fixes a hypothesis, splits traffic 50/50 on the flag's default rule, names **Bestsellers** the control, and analyzes with **Bayesian** statistics at a **90%** threshold.
- The **Results** tab reports conversion rate, probability to be best, probability to beat control, relative difference, and expected loss per variation.

# One question

On the Results tab, Personalized's **probability to beat control** reads **93%** and its relative difference has turned green. What does that mean?
