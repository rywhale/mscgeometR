test_that("geomet_hydro_stns return a tibble with 10 columns", {

  skip_if_net_down()

  stns <- geomet_hydro_stns(
    query = list(
      "STATUS_EN" = "ACTIVE",
      "PROV_TERR_STATE_LOC" = "MB")
  )

  expect_type(stns, "list")

  expect(
    ncol(stns) == 10,
    failure_message = "Hydrometric metadata columns incorrect."
  )

})
