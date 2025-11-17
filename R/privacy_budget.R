#' Create a New Privacy Budget
#'
#' Initializes a privacy budget tracker for managing epsilon and delta across multiple
#' differentially private operations. The budget uses composition theorems to track
#' cumulative privacy loss.
#'
#' @param epsilon_total Total epsilon budget available
#' @param delta_total Total delta budget available (default: 1e-5)
#' @param composition Method for budget composition: "basic" or "advanced" (default: "basic")
#'
#' @return A privacy budget object (list with class "privacy_budget")
#' @export
#'
#' @examples
#' budget <- new_privacy_budget(epsilon_total = 1.0, delta_total = 1e-5)
new_privacy_budget <- function(epsilon_total, delta_total = 1e-5, composition = "basic") {
  if (epsilon_total <= 0) {
    stop("epsilon_total must be positive")
  }
  if (delta_total <= 0 || delta_total >= 1) {
    stop("delta_total must be between 0 and 1")
  }
  if (!composition %in% c("basic", "advanced")) {
    stop("composition must be either 'basic' or 'advanced'")
  }

  budget <- list(
    epsilon_total = epsilon_total,
    delta_total = delta_total,
    epsilon_spent = 0,
    delta_spent = 0,
    composition = composition,
    operations = list()
  )

  class(budget) <- "privacy_budget"
  return(budget)
}

#' Check Privacy Budget
#'
#' Checks if a proposed operation would exceed the privacy budget
#'
#' @param budget A privacy budget object
#' @param epsilon_required Epsilon required for the operation
#' @param delta_required Delta required for the operation (default: 0)
#'
#' @return Logical indicating if budget is sufficient
#' @export
#'
#' @examples
#' budget <- new_privacy_budget(epsilon_total = 1.0)
#' check_privacy_budget(budget, epsilon_required = 0.5)
check_privacy_budget <- function(budget, epsilon_required, delta_required = 0) {
  if (!inherits(budget, "privacy_budget")) {
    stop("budget must be a privacy_budget object")
  }

  # Basic composition: epsilons and deltas add up
  epsilon_after <- budget$epsilon_spent + epsilon_required
  delta_after <- budget$delta_spent + delta_required

  return(epsilon_after <= budget$epsilon_total && delta_after <= budget$delta_total)
}

#' Spend Privacy Budget
#'
#' Records a privacy expenditure and updates the budget
#'
#' @param budget A privacy budget object
#' @param epsilon_spent Epsilon spent on the operation
#' @param delta_spent Delta spent on the operation (default: 0)
#' @param operation_name Name/description of the operation (optional)
#'
#' @return Updated privacy budget object
#' @keywords internal
spend_privacy_budget <- function(budget, epsilon_spent, delta_spent = 0, operation_name = NULL) {
  if (!inherits(budget, "privacy_budget")) {
    stop("budget must be a privacy_budget object")
  }

  if (!check_privacy_budget(budget, epsilon_spent, delta_spent)) {
    stop(sprintf(
      "Insufficient privacy budget. Required: (%.4f, %.2e), Available: (%.4f, %.2e)",
      epsilon_spent, delta_spent,
      budget$epsilon_total - budget$epsilon_spent,
      budget$delta_total - budget$delta_spent
    ))
  }

  budget$epsilon_spent <- budget$epsilon_spent + epsilon_spent
  budget$delta_spent <- budget$delta_spent + delta_spent

  # Record the operation
  operation <- list(
    name = operation_name,
    epsilon = epsilon_spent,
    delta = delta_spent,
    timestamp = Sys.time()
  )
  budget$operations <- c(budget$operations, list(operation))

  return(budget)
}

#' Print Privacy Budget
#'
#' @param x A privacy budget object
#' @param ... Additional arguments (unused)
#'
#' @export
print.privacy_budget <- function(x, ...) {
  cat("Privacy Budget\n")
  cat("==============\n")
  cat(sprintf("Total:     epsilon = %.4f, delta = %.2e\n", x$epsilon_total, x$delta_total))
  cat(sprintf("Spent:     epsilon = %.4f, delta = %.2e\n", x$epsilon_spent, x$delta_spent))
  cat(sprintf("Remaining: epsilon = %.4f, delta = %.2e\n",
              x$epsilon_total - x$epsilon_spent,
              x$delta_total - x$delta_spent))
  cat(sprintf("Composition: %s\n", x$composition))
  cat(sprintf("Operations executed: %d\n", length(x$operations)))
  invisible(x)
}
