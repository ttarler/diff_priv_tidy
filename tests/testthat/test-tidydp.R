test_that("dp_add_noise works on data frames", {
  data <- data.frame(age = c(25, 30, 35, 40), income = c(50000, 60000, 70000, 80000))

  result <- dp_add_noise(
    data,
    columns = c("age", "income"),
    epsilon = 0.1,
    lower = c(age = 0, income = 0),
    upper = c(age = 100, income = 200000)
  )

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), nrow(data))
  expect_equal(ncol(result), ncol(data))
})

test_that("dp_count works", {
  data <- data.frame(city = c("NYC", "LA", "NYC", "LA", "NYC"))

  result <- dp_count(data, epsilon = 0.1)

  expect_true(is.data.frame(result))
  expect_true("count" %in% names(result))
  expect_true(is.numeric(result$count))
})

test_that("dp_count works with groups", {
  data <- data.frame(city = c("NYC", "LA", "NYC", "LA", "NYC"))

  result <- dp_count(data, epsilon = 0.1, group_by = "city")

  expect_true(is.data.frame(result))
  expect_true("count" %in% names(result))
  expect_true("city" %in% names(result))
  expect_equal(nrow(result), 2)  # Two cities
})

test_that("dp_mean works", {
  data <- data.frame(income = c(50000, 60000, 70000, 80000))

  result <- dp_mean(data, "income", epsilon = 0.1, lower = 0, upper = 200000)

  expect_true(is.data.frame(result))
  expect_true("income_mean" %in% names(result))
})

test_that("dp_mean works with groups", {
  data <- data.frame(
    city = c("NYC", "LA", "NYC", "LA"),
    income = c(50000, 60000, 70000, 80000)
  )

  result <- dp_mean(data, "income", epsilon = 0.1, lower = 0, upper = 200000, group_by = "city")

  expect_true(is.data.frame(result))
  expect_true("income_mean" %in% names(result))
  expect_equal(nrow(result), 2)
})

test_that("dp_sum works", {
  data <- data.frame(sales = c(100, 200, 150, 250))

  result <- dp_sum(data, "sales", epsilon = 0.1, lower = 0, upper = 1000)

  expect_true(is.data.frame(result))
  expect_true("sales_sum" %in% names(result))
})

test_that("dp_sum works with groups", {
  data <- data.frame(
    city = c("NYC", "LA", "NYC", "LA"),
    sales = c(100, 200, 150, 250)
  )

  result <- dp_sum(data, "sales", epsilon = 0.1, lower = 0, upper = 1000, group_by = "city")

  expect_true(is.data.frame(result))
  expect_true("sales_sum" %in% names(result))
  expect_equal(nrow(result), 2)
})

test_that("Pipe syntax works", {
  data <- data.frame(age = c(25, 30, 35, 40))

  result <- data %>%
    dp_add_noise(columns = "age", epsilon = 0.1, lower = c(age = 0), upper = c(age = 100))

  expect_true(is.data.frame(result))
})
