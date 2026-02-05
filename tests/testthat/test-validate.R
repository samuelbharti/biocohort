# Tests for validate_cohort function
test_that('validate_cohort errors on invalid sample map', {
  subject_tbl <- tibble::tibble(
    subject_id = c('R1', 'R2'),
    species = c('rat', 'rat')
  )
  sample_map <- tibble::tibble(
    subject_id = c('R1', 'R3'),
    wes_id = c('W1', 'W3')
  )

  cohort <- Cohort(subject_tbl = subject_tbl, sample_map = sample_map)
  expect_error(validate_cohort(cohort), 'not found')
})
