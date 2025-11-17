# tidydp: Basic Usage Examples
# This script demonstrates the core functionality of the tidydp package

library(tidydp)
library(magrittr)

# ===== Example 1: Basic Noise Addition =====
cat("\n=== Example 1: Adding Noise to Columns ===\n")

data <- data.frame(
  name = c("Alice", "Bob", "Charlie", "Diana"),
  age = c(25, 30, 35, 40),
  income = c(50000, 60000, 70000, 80000)
)

cat("Original data:\n")
print(data)

# Add differential privacy noise
private_data <- data %>%
  dp_add_noise(
    columns = c("age", "income"),
    epsilon = 0.1,  # Privacy parameter
    lower = c(age = 18, income = 0),
    upper = c(age = 100, income = 200000)
  )

cat("\nPrivate data (with noise):\n")
print(private_data)


# ===== Example 2: Private Counting =====
cat("\n\n=== Example 2: Private Counting ===\n")

city_data <- data.frame(
  city = c("NYC", "LA", "NYC", "LA", "NYC", "LA", "Chicago", "Chicago"),
  visits = c(10, 15, 12, 18, 14, 20, 8, 9)
)

# Overall count
overall <- dp_count(city_data, epsilon = 0.1)
cat("Overall count:\n")
print(overall)

# Grouped count
by_city <- city_data %>%
  dp_count(epsilon = 0.1, group_by = "city")
cat("\nCount by city:\n")
print(by_city)


# ===== Example 3: Private Statistics =====
cat("\n\n=== Example 3: Private Mean and Sum ===\n")

sales_data <- data.frame(
  region = c("East", "West", "East", "West", "East", "West"),
  sales = c(1000, 1500, 1200, 1800, 1100, 1600)
)

# Private mean
avg_sales <- sales_data %>%
  dp_mean("sales", epsilon = 0.1, lower = 0, upper = 5000, group_by = "region")
cat("Average sales by region:\n")
print(avg_sales)

# Private sum
total_sales <- sales_data %>%
  dp_sum("sales", epsilon = 0.1, lower = 0, upper = 5000, group_by = "region")
cat("\nTotal sales by region:\n")
print(total_sales)


# ===== Example 4: Privacy Budget Tracking =====
cat("\n\n=== Example 4: Privacy Budget Tracking ===\n")

# Create a privacy budget
budget <- new_privacy_budget(epsilon_total = 1.0, delta_total = 1e-5)

cat("Initial budget:\n")
print(budget)

# Perform first query
cat("\nPerforming first query (epsilon = 0.3)...\n")
result1 <- city_data %>%
  dp_count(epsilon = 0.3, .budget = budget)

cat("Budget after first query:\n")
print(budget)

# Perform second query
cat("\nPerforming second query (epsilon = 0.4)...\n")
result2 <- city_data %>%
  dp_mean("visits", epsilon = 0.4, lower = 0, upper = 50, .budget = budget)

cat("Budget after second query:\n")
print(budget)

# Check if we have budget for another query
can_proceed <- check_privacy_budget(budget, epsilon_required = 0.5)
cat(sprintf("\nCan perform query with epsilon=0.5? %s\n", can_proceed))

can_proceed <- check_privacy_budget(budget, epsilon_required = 0.2)
cat(sprintf("Can perform query with epsilon=0.2? %s\n", can_proceed))


# ===== Example 5: Chaining Operations =====
cat("\n\n=== Example 5: Chaining Multiple Operations ===\n")

employee_data <- data.frame(
  department = c("Engineering", "Sales", "Engineering", "Sales", "HR", "HR"),
  salary = c(80000, 70000, 85000, 75000, 65000, 68000),
  years = c(5, 3, 7, 4, 2, 6)
)

# Create private version of the entire dataset
private_employees <- employee_data %>%
  dp_add_noise(
    columns = c("salary", "years"),
    epsilon = 0.15,
    lower = c(salary = 50000, years = 0),
    upper = c(salary = 150000, years = 30)
  )

cat("Private employee data:\n")
print(private_employees)

# Then compute statistics on departments
dept_stats <- employee_data %>%
  dp_mean(
    "salary",
    epsilon = 0.2,
    lower = 50000,
    upper = 150000,
    group_by = "department"
  )

cat("\nAverage salary by department:\n")
print(dept_stats)


# ===== Example 6: Comparing Mechanisms =====
cat("\n\n=== Example 6: Laplace vs Gaussian Mechanism ===\n")

test_data <- data.frame(value = c(10, 20, 30, 40, 50))

# Laplace mechanism (default)
set.seed(42)
laplace_result <- test_data %>%
  dp_add_noise(
    columns = "value",
    epsilon = 0.1,
    lower = c(value = 0),
    upper = c(value = 100),
    mechanism = "laplace"
  )

# Gaussian mechanism
set.seed(42)
gaussian_result <- test_data %>%
  dp_add_noise(
    columns = "value",
    epsilon = 0.1,
    delta = 1e-5,
    lower = c(value = 0),
    upper = c(value = 100),
    mechanism = "gaussian"
  )

cat("Original values:\n")
print(test_data$value)

cat("\nWith Laplace noise:\n")
print(laplace_result$value)

cat("\nWith Gaussian noise:\n")
print(gaussian_result$value)

cat("\n=== All Examples Completed ===\n")
