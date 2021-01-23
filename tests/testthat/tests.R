testthat::context("Test distance function")
source("../../utils.R")

testthat::test_that("distance zero for same location",{
  testthat::expect_equal(dt_haversine(59.86867, 30.22017,59.86867, 30.22017), 0)
})

testthat::test_that("distance NA for missing coordinates",{
  testthat::expect_equal(dt_haversine(19.4326, 99.1332,19.4326, NA), NA_real_)
})


testthat::test_that("correct distance",{
  testthat::expect_equal(round(dt_haversine(59.86867, 30.22017,59.86983, 30.21433)), 351)
})