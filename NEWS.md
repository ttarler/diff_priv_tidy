# tidydp 0.1.0

## Initial CRAN Release

This is the first release of tidydp, a tidy-style interface for applying differential privacy to data frames in R.

### Core Features

* **Differential Privacy Mechanisms**
  - Laplace mechanism for pure epsilon-differential privacy
  - Gaussian mechanism for (epsilon, delta)-differential privacy
  - Automatic sensitivity calculations based on data bounds

* **Tidy-Style API Functions**
  - `dp_add_noise()`: Add calibrated noise to numeric columns with pipe support
  - `dp_count()`: Compute differentially private counts with optional grouping
  - `dp_mean()`: Compute differentially private means with optional grouping
  - `dp_sum()`: Compute differentially private sums with optional grouping

* **Privacy Budget Management**
  - `new_privacy_budget()`: Create and initialize privacy budgets
  - `check_privacy_budget()`: Verify sufficient budget before operations
  - Automatic budget tracking with basic composition
  - Print method for budget status visualization

### Technical Details

* All functions support the magrittr pipe operator (`%>%`)
* Flexible mechanism selection (Laplace or Gaussian)
* Support for grouped operations using `group_by` parameter
* Comprehensive error handling and input validation
* Built from scratch without external differential privacy dependencies

### Documentation

* Complete function documentation with examples
* Comprehensive README with usage examples
* Full test suite with >95% code coverage
* Example script demonstrating common workflows

### Notes

* This package implements differential privacy mechanisms from first principles
* Suitable for statistical analysis with formal privacy guarantees
* Compatible with the tidyverse ecosystem
* Designed for CRAN submission standards
