# tidydp: Tidy Differential Privacy

A tidy-style R package for applying differential privacy to data frames using the familiar `%>%` pipe syntax.

## Installation

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("ttarler/tidydp")
```

## What is Differential Privacy?

Differential privacy is a mathematical framework for sharing information about a dataset while protecting the privacy of individuals in that dataset. It works by adding carefully calibrated noise to query results, making it difficult to determine whether any individual's data was included in the dataset.

Key parameters:
- **epsilon (ε)**: Privacy budget - smaller values mean more privacy but more noise
- **delta (δ)**: Probability of privacy breach - typically very small (e.g., 1e-5)

## Features

- Tidy-style pipe-friendly API
- Core differential privacy mechanisms (Laplace and Gaussian)
- Privacy budget tracking and management
- Support for grouped operations
- Common statistical queries: count, sum, mean
- Column-level noise addition
- Built-in sensitivity calculations

## Quick Start

```r
library(tidydp)
library(magrittr)

# Create sample data
data <- data.frame(
  city = c("NYC", "LA", "NYC", "LA", "NYC", "LA"),
  age = c(25, 30, 35, 40, 45, 50),
  income = c(50000, 60000, 70000, 80000, 90000, 100000)
)

# Add noise to columns
private_data <- data %>%
  dp_add_noise(
    columns = c("age", "income"),
    epsilon = 0.1,
    lower = c(age = 18, income = 0),
    upper = c(age = 100, income = 200000)
  )

# Compute private count by group
city_counts <- data %>%
  dp_count(epsilon = 0.1, group_by = "city")

# Compute private mean
avg_income <- data %>%
  dp_mean("income", epsilon = 0.1, lower = 0, upper = 200000)

# Compute private sum by group
city_income <- data %>%
  dp_sum("income", epsilon = 0.1, lower = 0, upper = 200000, group_by = "city")
```

## Privacy Budget Tracking

Track your privacy expenditure across multiple operations:

```r
# Create a privacy budget
budget <- new_privacy_budget(epsilon_total = 1.0, delta_total = 1e-5)

# Check budget status
print(budget)

# Use budget with operations
data %>%
  dp_count(epsilon = 0.3, .budget = budget) %>%
  dp_mean("income", epsilon = 0.3, lower = 0, upper = 200000, .budget = budget)

# Check remaining budget
print(budget)
```

## Core Functions

### `dp_add_noise()`

Add differentially private noise to numeric columns:

```r
data %>%
  dp_add_noise(
    columns = c("age", "salary"),
    epsilon = 0.1,
    lower = c(age = 0, salary = 0),
    upper = c(age = 100, salary = 200000),
    mechanism = "laplace"  # or "gaussian"
  )
```

### `dp_count()`

Compute differentially private counts:

```r
# Overall count
data %>% dp_count(epsilon = 0.1)

# Grouped count
data %>% dp_count(epsilon = 0.1, group_by = "city")

# With Gaussian mechanism
data %>% dp_count(epsilon = 0.1, delta = 1e-5, group_by = "city")
```

### `dp_mean()`

Compute differentially private means:

```r
# Overall mean
data %>% dp_mean("income", epsilon = 0.1, lower = 0, upper = 200000)

# Grouped mean
data %>% dp_mean(
  "income",
  epsilon = 0.1,
  lower = 0,
  upper = 200000,
  group_by = "city"
)
```

### `dp_sum()`

Compute differentially private sums:

```r
# Overall sum
data %>% dp_sum("sales", epsilon = 0.1, lower = 0, upper = 10000)

# Grouped sum
data %>% dp_sum(
  "sales",
  epsilon = 0.1,
  lower = 0,
  upper = 10000,
  group_by = c("city", "category")
)
```

## Privacy Budget Management

```r
# Create a budget
budget <- new_privacy_budget(
  epsilon_total = 1.0,
  delta_total = 1e-5,
  composition = "basic"
)

# Check if operation is within budget
check_privacy_budget(budget, epsilon_required = 0.5)

# Track operations
data %>%
  dp_count(epsilon = 0.3, .budget = budget) %>%
  dp_mean("age", epsilon = 0.3, lower = 0, upper = 100, .budget = budget)

# View budget status
print(budget)
```

## Mechanisms

### Laplace Mechanism

Best for epsilon-differential privacy (delta = 0). Used by default when `delta` is not specified.

- Adds noise from Laplace distribution
- Scale: sensitivity / epsilon
- Suitable for counting queries, sums

### Gaussian Mechanism

Best for (epsilon, delta)-differential privacy. Used when `delta` is specified.

- Adds noise from Gaussian (normal) distribution
- Standard deviation based on sensitivity, epsilon, and delta
- Often provides better utility for the same privacy level when delta > 0 is acceptable

## Best Practices

1. **Set realistic bounds**: Provide accurate `lower` and `upper` bounds for better utility
2. **Budget wisely**: Smaller epsilon = more privacy but more noise
3. **Track your budget**: Use privacy budget objects for multiple queries
4. **Understand sensitivity**: The package calculates sensitivity automatically based on your bounds
5. **Test with synthetic data**: Validate your privacy-utility tradeoff before deploying

## Example: Complete Workflow

```r
library(tidydp)
library(magrittr)

# Initialize privacy budget
budget <- new_privacy_budget(epsilon_total = 1.0)

# Load data
data <- read.csv("sensitive_data.csv")

# Perform multiple private queries
city_stats <- data %>%
  dp_count(epsilon = 0.2, group_by = "city", .budget = budget)

avg_age <- data %>%
  dp_mean("age", epsilon = 0.3, lower = 0, upper = 100, .budget = budget)

total_income <- data %>%
  dp_sum(
    "income",
    epsilon = 0.5,
    lower = 0,
    upper = 500000,
    group_by = "city",
    .budget = budget
  )

# Check remaining budget
print(budget)
# Privacy Budget
# ==============
# Total:     ε = 1.0000, δ = 1.00e-05
# Spent:     ε = 1.0000, δ = 0.00e+00
# Remaining: ε = 0.0000, δ = 1.00e-05
# Composition: basic
# Operations executed: 3
```

## Mathematical Background

The package implements:

- **Laplace Mechanism**: Adds noise ~ Laplace(0, Δf/ε) where Δf is the sensitivity
- **Gaussian Mechanism**: Adds noise ~ N(0, σ²) where σ = Δf · √(2ln(1.25/δ)) / ε
- **Basic Composition**: Total privacy cost is sum of individual epsilons and deltas

## Roadmap

Future enhancements planned:
- Advanced composition theorems (e.g., Rényi DP, concentrated DP)
- Additional statistics (median, quantiles, variance)
- Private histogram generation
- Integration with `dplyr` verbs
- Synthetic data generation
- More sophisticated sensitivity analysis

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Citation

If you use tidydp in your research, please cite:

```
@Manual{,
  title = {tidydp: Tidy Differential Privacy},
  author = {Thomas Tarler},
  year = {2025},
  note = {R package version 0.1.0},
  url = {https://github.com/ttarler/tidydp},
}
```

## References

- Dwork, C., & Roth, A. (2014). The algorithmic foundations of differential privacy. Foundations and Trends in Theoretical Computer Science, 9(3-4), 211-407.
- Differential Privacy Team (2017). Learning with Privacy at Scale. Apple Machine Learning Journal, Vol 1, Issue 8.

## Author

Thomas Tarler (ttarler@gmail.com)
