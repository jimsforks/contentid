context("local register & query")


test_that("We can query a remote registry", {
  skip_if_offline()
  # Online tests sporadically time-out on CRAN servers
  skip_on_cran()
  
  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"
  
  x <- query(url,
             registries = "https://hash-archive.org")
  
  expect_is(x, "data.frame")
  expect_true(any(grepl(paste0("hash://sha256/",
                           "9412325831dab22aeebdd674b6eb53ba",
                           "6b7bdd04bb99a4dbb21ddff646287e37"),
                    x$identifier)))
  
})

test_that("We can register a URL in the local registry", {
  skip_if_offline()
  skip_on_cran()

  local <- tempfile(fileext = ".tsv")
  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"
  
  x <- register(url, registries = local)
  
  expect_is(x, "character")
  expect_true(is_hash(x, "hashuri"))

  expect_true(file.exists(local))
  
  })


test_that("Warn on registering a non-existent URL", {
  skip_if_offline()
  skip_on_cran()

  local <- tempfile(fileext = ".tsv")
  
  expect_warning(
    register("https://httpbin.org/404", local)
  )
})


test_that("We can register to multiple registries", {
  skip_if_offline()
  skip_on_cran()
  skip_if_not_installed("vroom", minimum_version = "1.2.1.9000")

  r1 <- tempfile(fileext = ".tsv")
  r2 <- tempfile(fileext = ".tsv")

  url <- "https://knb.ecoinformatics.org/knb/d1/mn/v2/object/ess-dive-457358fdc81d3a5-20180726T203952542"

  
  
  x <- register(url, registries = c(r1, r2))
  
  register_tsv(url, tsv = r1)
  reg <- utils::read.table(r1, header = TRUE, sep = "\t", quote = "", colClasses = registry_spec)
  
  y <- query_history(url,
             registries = c(r1, r2))

  ## should be multiple entries from the multiple registries
  expect_true(dim(y)[1] > 1)

  ## Should be exactly 1 entry for the URL in the temporary local registry
  y <- query_history(url,
             registries = r1)
  expect_true(dim(y)[1] >= 1)

  ## Should be exactly 1 entry for the Content Hash in temp local registry
  y <- query_sources(x, registries = r1)
  expect_true(dim(y)[1] >= 1)


  ## clear out r1
  unlink(r1)
})

