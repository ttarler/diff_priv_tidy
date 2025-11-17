test_that("Privacy budget is created correctly", {
  budget <- new_privacy_budget(epsilon_total = 1.0, delta_total = 1e-5)

  expect_s3_class(budget, "privacy_budget")
  expect_equal(budget$epsilon_total, 1.0)
  expect_equal(budget$delta_total, 1e-5)
  expect_equal(budget$epsilon_spent, 0)
  expect_equal(budget$delta_spent, 0)
})

test_that("Privacy budget checks work correctly", {
  budget <- new_privacy_budget(epsilon_total = 1.0)

  # Should have budget available
  expect_true(check_privacy_budget(budget, epsilon_required = 0.5))

  # Should not have enough budget
  expect_false(check_privacy_budget(budget, epsilon_required = 1.5))
})

test_that("Privacy budget spending works correctly", {
  budget <- new_privacy_budget(epsilon_total = 1.0)
  budget <- tidydp:::spend_privacy_budget(budget, epsilon_spent = 0.3, operation_name = "test")

  expect_equal(budget$epsilon_spent, 0.3)
  expect_equal(length(budget$operations), 1)
  expect_equal(budget$operations[[1]]$name, "test")
})

test_that("Exceeding budget throws error", {
  budget <- new_privacy_budget(epsilon_total = 1.0)

  expect_error(
    tidydp:::spend_privacy_budget(budget, epsilon_spent = 1.5),
    "Insufficient privacy budget"
  )
})

test_that("Invalid budget parameters throw errors", {
  expect_error(
    new_privacy_budget(epsilon_total = -1.0),
    "epsilon_total must be positive"
  )

  expect_error(
    new_privacy_budget(epsilon_total = 1.0, delta_total = 1.5),
    "delta_total must be between 0 and 1"
  )
})
