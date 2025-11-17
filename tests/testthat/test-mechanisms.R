test_that("Laplace noise is added correctly", {
  set.seed(123)
  x <- 100
  result <- tidydp:::add_laplace_noise(x, sensitivity = 1, epsilon = 0.1)

  # Result should be different from input
  expect_false(result == x)

  # Result should be numeric
  expect_true(is.numeric(result))
})

test_that("Gaussian noise is added correctly", {
  set.seed(123)
  x <- 100
  result <- tidydp:::add_gaussian_noise(x, sensitivity = 1, epsilon = 0.1, delta = 1e-5)

  # Result should be different from input
  expect_false(result == x)

  # Result should be numeric
  expect_true(is.numeric(result))
})

test_that("Invalid epsilon throws error", {
  expect_error(
    tidydp:::add_laplace_noise(100, sensitivity = 1, epsilon = -0.1),
    "epsilon must be positive"
  )
})

test_that("Invalid sensitivity throws error", {
  expect_error(
    tidydp:::add_laplace_noise(100, sensitivity = -1, epsilon = 0.1),
    "sensitivity must be positive"
  )
})

test_that("Sensitivity calculations are correct", {
  expect_equal(tidydp:::sensitivity_count(), 1)
  expect_equal(tidydp:::sensitivity_sum(0, 10), 10)
  expect_equal(tidydp:::sensitivity_sum(-5, 5), 5)
  expect_equal(tidydp:::sensitivity_mean(0, 100, 10), 10)
})
