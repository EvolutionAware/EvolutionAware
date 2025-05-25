
# Supporting Materials for the Paper: *Evolution-Aware Heuristics for GR(1) Realizability Checking*

## 📘 Introduction

This repository contains the supporting materials for the paper *"Evolution-Aware Heuristics for GR(1) Realizability Checking"*.

It includes:
- All scripts for computing evolution-aware realizability checks and measuring performance.
- The full SPECVER dataset, organized by projects.
- A Python notebook with complete analysis and visualizations of the results.

---

## 📦 What Does the Artifact Contain?

| File | Purpose |
|-----------------------|----------------------------------------------------------------------------------------------|
| `singleSpec.jar`      | Implementation of traditional and evolution-aware realizability checking                     |
| `runner.sh`           | Shell script to automate batch performance evaluation                                        |
| `dataset/`            | Directory with all intermediate specification files                                          |
| `all_pairs.txt`       | List of comma-separated original and evolution spec file paths for evaluation                |
| `Evaluation.ipynb`    | Jupyter notebook for result analysis and visualization                                       |
| `requirements.txt`    | List of Python dependencies for running the analysis notebook                                |
| `README.md`           | This documentation file                                                                      |
| `libcudd.so`             | Compiled CUDD library required for BDD operations, also includes the C implementation of the heuristics                                            |
| `results/`            | Directory with a CSV file with all the performance results of running `runner.sh` on the entire dataset                                            |

---

## ⚙️ Installation

### Requirements for Running the Realizability Checking Scripts
- Linux-based system (Intel or AMD 64-bit architecture)
- Java (version 8+)
- CUDD library installed:
  ```bash
  sudo cp libcudd.so /usr/lib
  sudo ldconfig
  ```

### Requirements for Running the Evaluation Analysis Notebook
- Python 3.8+
- Install Python dependencies:
  ```bash
  pip install -r requirements.txt
  ```

---

## 📂 Dataset

- `dataset/` — Contains all intermediate specification files.
- `all_pairs.txt` — Each line contains two comma-separated paths to specifications (original, evolution) sorted by timestamp, used for evaluation.

---

## ▶️ Run Single Evolution-Aware Realizability Checking

Use `singleSpec.jar` to perform either:
- Traditional realizability checking
- Evolution-aware realizability checking

### 🛠️ Usage

```bash
java -jar singleSpec.jar <spec_file> <store_location> [<previous_store_location>]
```

#### Arguments
- `<spec_file>`: Path to the specification file to be analyzed.
- `<store_location>`: Path to store intermediate computation results.
- `[<previous_store_location>]`: *(Optional)* Path to a stored previous intermediate results for evolution-aware mode. When providing this argument, evolution-aware realizability checking is performed.

### 🔎 Output
Logs printed to `stdout` include:
- Realizability result:
  ```
  Is realizable: true|false
  ```
- Applied heuristics:
  ```
  Found: <heuristic_name>
  ```
- Timing information:
  - Storing BDD time: `<ms>`
  - Loading BDD time: `<ms>`
  - RunningTime: `<ms>`
  - Game Comparison Time: `<ms>`
- Fixed point iterations:
  ```
  z iterations = ..., y iterations = ..., x iterations = ...
  ```
- Game model loading times
- Local semantic diff details

### ❗ Notes
- Exits with code `124` on timeout (if run with `timeout`).

---

## 🧪 Run Performance Evaluation (`runner.sh`)

Automates performance benchmarking of evolution-aware realizability using `singleSpec.jar`.

### 🔧 Usage

```bash
./runner.sh <input_file> <original_storing_location> <evolution_storing_location> <output_csv_file>
```
Notice that running on the entire dataset takes a very long time, you may run on a smaller set of examples out of the pairs in `all_pairs.txt`

#### Arguments
- `<input_file>`: Text file with lines formatted as `original_spec,evolution_spec`
- `<original_storing_location>`: Directory for storing original spec intermediate data
- `<evolution_storing_location>`: Directory for evolution spec intermediate data
- `<output_csv_file>`: CSV file where performance metrics will be saved

### 🔁 Configuration (inside the script)
- `TIMEOUT_SECONDS`: Default: `600` seconds
- `CONFIGURABLE_RUNS`: Default: `3` repetitions per pair

### ❗ Notes
- The script skips evaluation if the original and evolution specs are identical (binary same)
- The script Logs `timeout` in CSV where a timeout occurs
- The script halts with an error if the realizability results mismatch between evolution and evolution-aware runs (as part of our validation process)

---

## 📊 Evaluation Analysis Notebook

Reproduce the experimental results presented in the paper.

### Contents of `Evaluation.ipynb`:
- Data loading and preprocessing
- Metric computation
- Comparative visualizations
- Summary tables

### Requirements

Install dependencies:

```bash
pip install -r requirements.txt
```

Launch the notebook:

```bash
jupyter notebook Evaluation.ipynb
```

Then:
1. Open `Evaluation.ipynb` in your browser.
2. Run all cells in order via **Kernel → Restart & Run All**.
3. Review generated plots and tables.

### Dependencies
The following Python packages are required:
- `pandas==1.5.3`
- `matplotlib==3.6.3`
- `seaborn==0.11.2`
- `numpy==1.24.0`
- `scipy==1.9.3`
- `jupyter`

---
