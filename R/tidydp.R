#' tidydp: Tidy Differential Privacy
#'
#' A tidy-style interface for applying differential privacy to data frames.
#'
#' @docType package
#' @name tidydp
#' @importFrom magrittr %>%
#' @importFrom stats rnorm runif aggregate
NULL

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL

#' Add Differentially Private Noise to Data Frame Columns
#'
#' Adds calibrated Laplace or Gaussian noise to specified numeric columns in a data frame
#' to achieve differential privacy. This is the primary function for column-level privacy.
#'
#' @param data A data frame
#' @param columns Character vector of column names to add noise to
#' @param epsilon Privacy parameter (smaller = more privacy, more noise)
#' @param delta Privacy parameter for Gaussian mechanism (default: NULL, uses Laplace)
#' @param lower Named numeric vector of lower bounds for each column
#' @param upper Named numeric vector of upper bounds for each column
#' @param mechanism Either "laplace" or "gaussian" (auto-selected based on delta if NULL)
#' @param .budget Optional privacy budget object to track expenditure
#'
#' @return Data frame with noise added to specified columns
#' @export
#'
#' @examples
#' data <- data.frame(age = c(25, 30, 35, 40), income = c(50000, 60000, 70000, 80000))
#' private_data <- data %>%
#'   dp_add_noise(
#'     columns = c("age", "income"),
#'     epsilon = 0.1,
#'     lower = c(age = 0, income = 0),
#'     upper = c(age = 100, income = 200000)
#'   )
dp_add_noise <- function(data, columns, epsilon, delta = NULL,
                         lower = NULL, upper = NULL,
                         mechanism = NULL, .budget = NULL) {

  # Input validation
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!all(columns %in% names(data))) {
    missing_cols <- columns[!columns %in% names(data)]
    stop(sprintf("Columns not found in data: %s", paste(missing_cols, collapse = ", ")))
  }
  if (epsilon <= 0) {
    stop("epsilon must be positive")
  }

  # Determine mechanism
  if (is.null(mechanism)) {
    mechanism <- if (is.null(delta)) "laplace" else "gaussian"
  }
  mechanism <- match.arg(mechanism, c("laplace", "gaussian"))

  # Check privacy budget if provided
  if (!is.null(.budget)) {
    delta_required <- if (mechanism == "gaussian") delta else 0
    if (!check_privacy_budget(.budget, epsilon, delta_required)) {
      stop("Insufficient privacy budget for this operation")
    }
  }

  # Process each column
  result <- data
  for (col in columns) {
    if (!is.numeric(data[[col]])) {
      warning(sprintf("Column '%s' is not numeric, skipping", col))
      next
    }

    # Determine bounds
    col_lower <- if (!is.null(lower) && col %in% names(lower)) {
      lower[[col]]
    } else {
      min(data[[col]], na.rm = TRUE)
    }

    col_upper <- if (!is.null(upper) && col %in% names(upper)) {
      upper[[col]]
    } else {
      max(data[[col]], na.rm = TRUE)
    }

    # Calculate sensitivity based on range
    sensitivity <- col_upper - col_lower

    # Add noise
    if (mechanism == "laplace") {
      result[[col]] <- add_laplace_noise(data[[col]], sensitivity, epsilon)
    } else {
      result[[col]] <- add_gaussian_noise(data[[col]], sensitivity, epsilon, delta)
    }
  }

  # Update budget if provided
  if (!is.null(.budget)) {
    delta_spent <- if (mechanism == "gaussian") delta else 0
    .budget <- spend_privacy_budget(.budget, epsilon, delta_spent, "dp_add_noise")
  }

  return(result)
}

#' Differentially Private Count
#'
#' Computes a differentially private count of rows, optionally grouped by specified columns.
#'
#' @param data A data frame
#' @param epsilon Privacy parameter
#' @param delta Privacy parameter (default: NULL, uses Laplace mechanism)
#' @param group_by Character vector of column names to group by (optional)
#' @param .budget Optional privacy budget object to track expenditure
#'
#' @return Data frame with (possibly grouped) counts
#' @export
#'
#' @examples
#' data <- data.frame(city = c("NYC", "LA", "NYC", "LA", "NYC"),
#'                    age = c(25, 30, 35, 40, 45))
#' # Overall count
#' dp_count(data, epsilon = 0.1)
#'
#' # Grouped count
#' data %>% dp_count(epsilon = 0.1, group_by = "city")
dp_count <- function(data, epsilon, delta = NULL, group_by = NULL, .budget = NULL) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (epsilon <= 0) {
    stop("epsilon must be positive")
  }

  # Determine mechanism
  mechanism <- if (is.null(delta)) "laplace" else "gaussian"

  # Check privacy budget
  if (!is.null(.budget)) {
    delta_required <- if (mechanism == "gaussian") delta else 0
    if (!check_privacy_budget(.budget, epsilon, delta_required)) {
      stop("Insufficient privacy budget for this operation")
    }
  }

  # Calculate counts
  if (is.null(group_by)) {
    # Overall count
    true_count <- nrow(data)
    sensitivity <- sensitivity_count()

    if (mechanism == "laplace") {
      noisy_count <- add_laplace_noise(true_count, sensitivity, epsilon)
    } else {
      noisy_count <- add_gaussian_noise(true_count, sensitivity, epsilon, delta)
    }

    result <- data.frame(count = max(0, round(noisy_count)))
  } else {
    # Grouped count
    if (!all(group_by %in% names(data))) {
      stop("group_by columns not found in data")
    }

    # Use base R aggregate for counting
    true_counts <- aggregate(
      rep(1, nrow(data)),
      by = data[group_by],
      FUN = length
    )
    names(true_counts)[ncol(true_counts)] <- "count"

    sensitivity <- sensitivity_count()

    if (mechanism == "laplace") {
      true_counts$count <- add_laplace_noise(true_counts$count, sensitivity, epsilon)
    } else {
      true_counts$count <- add_gaussian_noise(true_counts$count, sensitivity, epsilon, delta)
    }

    # Round and ensure non-negative
    true_counts$count <- pmax(0, round(true_counts$count))
    result <- true_counts
  }

  # Update budget
  if (!is.null(.budget)) {
    delta_spent <- if (mechanism == "gaussian") delta else 0
    .budget <- spend_privacy_budget(.budget, epsilon, delta_spent, "dp_count")
  }

  return(result)
}

#' Differentially Private Mean
#'
#' Computes a differentially private mean of a numeric column.
#'
#' @param data A data frame
#' @param column Column name to compute mean of
#' @param epsilon Privacy parameter
#' @param delta Privacy parameter (default: NULL, uses Laplace mechanism)
#' @param lower Lower bound of the data range
#' @param upper Upper bound of the data range
#' @param group_by Character vector of column names to group by (optional)
#' @param .budget Optional privacy budget object to track expenditure
#'
#' @return Data frame with (possibly grouped) private means
#' @export
#'
#' @examples
#' data <- data.frame(city = c("NYC", "LA", "NYC", "LA"),
#'                    income = c(50000, 60000, 70000, 80000))
#' data %>% dp_mean("income", epsilon = 0.1, lower = 0, upper = 200000, group_by = "city")
dp_mean <- function(data, column, epsilon, delta = NULL,
                    lower = NULL, upper = NULL, group_by = NULL, .budget = NULL) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!column %in% names(data)) {
    stop(sprintf("Column '%s' not found in data", column))
  }
  if (!is.numeric(data[[column]])) {
    stop(sprintf("Column '%s' must be numeric", column))
  }
  if (epsilon <= 0) {
    stop("epsilon must be positive")
  }

  # Determine bounds
  if (is.null(lower)) lower <- min(data[[column]], na.rm = TRUE)
  if (is.null(upper)) upper <- max(data[[column]], na.rm = TRUE)

  # Determine mechanism
  mechanism <- if (is.null(delta)) "laplace" else "gaussian"

  # Check privacy budget
  if (!is.null(.budget)) {
    delta_required <- if (mechanism == "gaussian") delta else 0
    if (!check_privacy_budget(.budget, epsilon, delta_required)) {
      stop("Insufficient privacy budget for this operation")
    }
  }

  # Calculate means
  if (is.null(group_by)) {
    # Overall mean
    true_mean <- mean(data[[column]], na.rm = TRUE)
    n <- sum(!is.na(data[[column]]))
    sensitivity <- sensitivity_mean(lower, upper, n)

    if (mechanism == "laplace") {
      noisy_mean <- add_laplace_noise(true_mean, sensitivity, epsilon)
    } else {
      noisy_mean <- add_gaussian_noise(true_mean, sensitivity, epsilon, delta)
    }

    result <- data.frame(mean = noisy_mean)
    names(result) <- paste0(column, "_mean")
  } else {
    # Grouped mean
    if (!all(group_by %in% names(data))) {
      stop("group_by columns not found in data")
    }

    true_means <- aggregate(
      data[[column]],
      by = data[group_by],
      FUN = function(x) mean(x, na.rm = TRUE)
    )
    names(true_means)[ncol(true_means)] <- "mean"

    # Calculate sensitivity for each group
    group_sizes <- aggregate(
      data[[column]],
      by = data[group_by],
      FUN = function(x) sum(!is.na(x))
    )

    sensitivity <- sensitivity_mean(lower, upper, min(group_sizes$x))

    if (mechanism == "laplace") {
      true_means$mean <- add_laplace_noise(true_means$mean, sensitivity, epsilon)
    } else {
      true_means$mean <- add_gaussian_noise(true_means$mean, sensitivity, epsilon, delta)
    }

    names(true_means)[ncol(true_means)] <- paste0(column, "_mean")
    result <- true_means
  }

  # Update budget
  if (!is.null(.budget)) {
    delta_spent <- if (mechanism == "gaussian") delta else 0
    .budget <- spend_privacy_budget(.budget, epsilon, delta_spent, "dp_mean")
  }

  return(result)
}

#' Differentially Private Sum
#'
#' Computes a differentially private sum of a numeric column.
#'
#' @param data A data frame
#' @param column Column name to compute sum of
#' @param epsilon Privacy parameter
#' @param delta Privacy parameter (default: NULL, uses Laplace mechanism)
#' @param lower Lower bound of the data range
#' @param upper Upper bound of the data range
#' @param group_by Character vector of column names to group by (optional)
#' @param .budget Optional privacy budget object to track expenditure
#'
#' @return Data frame with (possibly grouped) private sums
#' @export
#'
#' @examples
#' data <- data.frame(city = c("NYC", "LA", "NYC", "LA"),
#'                    sales = c(100, 200, 150, 250))
#' data %>% dp_sum("sales", epsilon = 0.1, lower = 0, upper = 1000, group_by = "city")
dp_sum <- function(data, column, epsilon, delta = NULL,
                   lower = NULL, upper = NULL, group_by = NULL, .budget = NULL) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!column %in% names(data)) {
    stop(sprintf("Column '%s' not found in data", column))
  }
  if (!is.numeric(data[[column]])) {
    stop(sprintf("Column '%s' must be numeric", column))
  }
  if (epsilon <= 0) {
    stop("epsilon must be positive")
  }

  # Determine bounds
  if (is.null(lower)) lower <- min(data[[column]], na.rm = TRUE)
  if (is.null(upper)) upper <- max(data[[column]], na.rm = TRUE)

  # Determine mechanism
  mechanism <- if (is.null(delta)) "laplace" else "gaussian"

  # Check privacy budget
  if (!is.null(.budget)) {
    delta_required <- if (mechanism == "gaussian") delta else 0
    if (!check_privacy_budget(.budget, epsilon, delta_required)) {
      stop("Insufficient privacy budget for this operation")
    }
  }

  sensitivity <- sensitivity_sum(lower, upper)

  # Calculate sums
  if (is.null(group_by)) {
    # Overall sum
    true_sum <- sum(data[[column]], na.rm = TRUE)

    if (mechanism == "laplace") {
      noisy_sum <- add_laplace_noise(true_sum, sensitivity, epsilon)
    } else {
      noisy_sum <- add_gaussian_noise(true_sum, sensitivity, epsilon, delta)
    }

    result <- data.frame(sum = noisy_sum)
    names(result) <- paste0(column, "_sum")
  } else {
    # Grouped sum
    if (!all(group_by %in% names(data))) {
      stop("group_by columns not found in data")
    }

    true_sums <- aggregate(
      data[[column]],
      by = data[group_by],
      FUN = function(x) sum(x, na.rm = TRUE)
    )
    names(true_sums)[ncol(true_sums)] <- "sum"

    if (mechanism == "laplace") {
      true_sums$sum <- add_laplace_noise(true_sums$sum, sensitivity, epsilon)
    } else {
      true_sums$sum <- add_gaussian_noise(true_sums$sum, sensitivity, epsilon, delta)
    }

    names(true_sums)[ncol(true_sums)] <- paste0(column, "_sum")
    result <- true_sums
  }

  # Update budget
  if (!is.null(.budget)) {
    delta_spent <- if (mechanism == "gaussian") delta else 0
    .budget <- spend_privacy_budget(.budget, epsilon, delta_spent, "dp_sum")
  }

  return(result)
}
