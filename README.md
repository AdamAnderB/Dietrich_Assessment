# Building Better Assessment: Scalable Tools for Human and AI Scoring

## *Reference:*
Bramlett, A. A. (2025). From Bottlenecks to Breakthroughs: Building Secure, Scalable, and Data-Driven Assessment Systems. *Graduate Assessment Fellowship Report, Dietrich College, CMU*.

## Overview
This project provides a scalable and transparent infrastructure for educational assessment, developed during the Graduate Assessment Fellowship at Carnegie Mellon University. It features a secure scoring app, a robust reliability framework, and an AI-assisted workflow for evaluating student artifacts.

## Repository Contents

### 🧩 `survey revised/app.R`
- **Dynamic Scoring App (R + Shiny)**  
  A secure, user-friendly interface for raters to score student work using dropdown menus, embedded rubrics, and real-time validation. Built for speed, consistency, and privacy-compliance.

  <img src="figures/rating_app.png" alt="Shiny App Interface solution" width="450">
  <img src="figures/rubric_scoring.png" alt="Shiny App Interface" width="450">

---

### 📈 `reliability.Rmd`
- **Reliability Analysis Script (R Markdown)**  
  Quantifies inter-rater agreement using metrics like exact match, one-off tolerance, and Cohen’s Kappa. Designed to compare both human-human and AI-human scores across multiple rubric components.

  <img src="figures/overal_reliability.png" alt="Reliability Output" width="400">

---

### 🧠 `survey revised/work_flow_updated.Rmd`
- **AI-Assisted Artifact Scoring Pipeline**  
  An end-to-end system using GPT-4.0 mini (via CMU’s LiteLLM) to score artifacts with rubric-aligned prompts. Includes preprocessing, prompt engineering, and structured output for downstream analysis.

  <img src="figures/AI vs AI and Human vs AI Agreement by Rubric Component.png" alt="AI Scoring Workflow" width="500">

---

## Key Features
- 🔐 **FERPA-Compliant Infrastructure**  
  All data handled securely within CMU systems.

- ⚖️ **Human & AI Calibration**  
  Multi-layer rubric reliability and cross-rater consistency checks.

- 🤖 **LLM Integration**  
  GPT-4.0 mini used for scoring under the same constraints as human raters.

- 📊 **Tidy Data Outputs**  
  Designed for reproducibility and scalability in R.
