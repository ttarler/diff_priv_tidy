#' Add Laplace Noise
#'
#' Adds Laplace-distributed noise to a numeric value or vector for differential privacy.
#' The Laplace mechanism is typically used for queries with sensitivity based on the
#' maximum absolute difference a single record can make.
#'
#' @param x Numeric value or vector to add noise to
#' @param sensitivity The sensitivity of the query (maximum change from one record)
#' @param epsilon Privacy parameter (smaller = more privacy, more noise)
#'
#' @return Numeric value or vector with Laplace noise added
#' @keywords internal
add_laplace_noise <- function(x, sensitivity, epsilon) {
  if (epsilon <= 0) {
    stop("epsilon must be positive")
  }
  if (sensitivity <= 0) {
    stop("sensitivity must be positive")
  }

  # Laplace distribution scale parameter
  scale <- sensitivity / epsilon

  # Generate Laplace noise using inverse CDF method
  # Laplace CDF: F(x) = 0.5 + 0.5 * sign(x) * (1 - exp(-|x|/b))
  u <- runif(length(x), min = -0.5, max = 0.5)
  noise <- -scale * sign(u) * log(1 - 2 * abs(u))

  return(x + noise)
}

#' Add Gaussian Noise
#'
#' Adds Gaussian (normal) noise to a numeric value or vector for (epsilon, delta)-differential
#' privacy. The Gaussian mechanism provides (epsilon, delta)-DP and is often used when
#' delta > 0 is acceptable.
#'
#' @param x Numeric value or vector to add noise to
#' @param sensitivity The L2 sensitivity of the query
#' @param epsilon Privacy parameter (smaller = more privacy)
#' @param delta Privacy parameter (probability of privacy breach), typically very small
#'
#' @return Numeric value or vector with Gaussian noise added
#' @keywords internal
add_gaussian_noise <- function(x, sensitivity, epsilon, delta = 1e-5) {
  if (epsilon <= 0) {
    stop("epsilon must be positive")
  }
  if (delta <= 0 || delta >= 1) {
    stop("delta must be between 0 and 1")
  }
  if (sensitivity <= 0) {
    stop("sensitivity must be positive")
  }

  # Gaussian mechanism standard deviation
  # sigma = sensitivity * sqrt(2 * log(1.25/delta)) / epsilon
  sigma <- sensitivity * sqrt(2 * log(1.25 / delta)) / epsilon

  # Generate Gaussian noise
  noise <- rnorm(length(x), mean = 0, sd = sigma)

  return(x + noise)
}

#' Calculate L1 Sensitivity for Count Queries
#'
#' For count queries, the sensitivity is 1 (adding/removing one record changes count by 1)
#'
#' @return Numeric sensitivity value
#' @keywords internal
sensitivity_count <- function() {
  return(1)
}

#' Calculate L1 Sensitivity for Sum Queries
#'
#' For sum queries, sensitivity depends on the range of values
#'
#' @param lower Lower bound of the data range
#' @param upper Upper bound of the data range
#'
#' @return Numeric sensitivity value
#' @keywords internal
sensitivity_sum <- function(lower, upper) {
  return(max(abs(lower), abs(upper)))
}

#' Calculate L2 Sensitivity for Mean Queries
#'
#' For mean queries with bounded data
#'
#' @param lower Lower bound of the data range
#' @param upper Upper bound of the data range
#' @param n Sample size
#'
#' @return Numeric sensitivity value
#' @keywords internal
sensitivity_mean <- function(lower, upper, n) {
  return((upper - lower) / n)
}
