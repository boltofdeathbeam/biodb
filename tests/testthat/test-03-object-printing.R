# vi: fdm=marker

source('common.R')

# Test BiodbCache show {{{1
################################################################

test.BiodbCache.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	expect_output(biodb$getCache()$show(), regexp = '^Biodb cache .* instance\\..*$')
}

# Test BiodbConfig show {{{1
################################################################

test.BiodbConfig.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	expect_output(biodb$getConfig()$show(), regexp = '^Biodb config.* instance\\..*Values:.*$')
}

# Test Biodb show {{{1
################################################################

test.Biodb.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	expect_output(biodb$show(), regexp = '^Biodb instance\\.$')
}

# Test BiodbFactory show {{{1
################################################################

test.BiodbFactory.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	expect_output(biodb$getFactory()$show(), regexp = '^Biodb factory instance\\.$')
}

# Test BiodbEntry show {{{1
################################################################

test.BiodbEntry.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	set.mode(biodb, MODE.OFFLINE)
	ids <- list.ref.entries('chebi')
	entry <- biodb$getFactory()$getEntry('chebi', ids[[1]])
	expect_output(entry$show(), regexp = '^Biodb .* entry instance\\.$')
}

# Test BiodbConn show {{{1
################################################################

test.BiodbConn.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	set.mode(biodb, MODE.OFFLINE)
	expect_output(biodb$getFactory()$createConn('chebi')$show(), regexp = '^Biodb .* connector instance, using URL .*\\.$')
}

# Test BiodbDbsInfo show {{{1
################################################################

test.BiodbDbsInfo.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	expect_output(biodb$getDbsInfo()$show(), regexp = '^Biodb databases information instance\\.$')
}

# Test BiodbEntryFields show {{{1
################################################################

test.BiodbEntryFields.show <- function() {
	biodb <- Biodb$new(logger = FALSE)
	expect_output(biodb$getEntryFields()$show(), regexp = '^Biodb entry fields information instance\\.$')
}

# MAIN {{{1
################################################################

context("Test object information printing")
test_that("Biodb show method returns correct information.", test.Biodb.show())
test_that("BiodbCache show method returns correct information.", test.BiodbCache.show())
test_that("BiodbConfig show method returns correct information.", test.BiodbConfig.show())
test_that("BiodbFactory show method returns correct information.", test.BiodbFactory.show())
test_that("BiodbEntry show method returns correct information.", test.BiodbEntry.show())
test_that("BiodbConn show method returns correct information.", test.BiodbConn.show())
test_that("BiodbDbsInfo show method returns correct information.", test.BiodbDbsInfo.show())
test_that("BiodbEntryFields show method returns correct information.", test.BiodbEntryFields.show())
