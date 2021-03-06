# vi: fdm=marker

# Class declaration {{{1
################################################################

#' @include RemotedbConn.R
PeakforestConn <- methods::setRefClass("PeakforestConn", contains = c("RemotedbConn"), fields = list(.db.name = 'character'))

# Constructor {{{1
################################################################

PeakforestConn$methods( initialize = function(db.name, ...) {

	# Call mother class constructor
	callSuper(...)
	.self$.abstract.class('PeakforestConn')

	# Set db name
	.db.name <<- db.name

	# Check token
	if (is.na(.self$getToken()))
		.self$message('caution', "Peakforest requires a token to function correctly.")
})

# Check if error {{{1
################################################################

PeakforestConn$methods( .checkIfError = function(content) {

	if (length(grep('^<!DOCTYPE HTML ', content)) > 0) {
		.self$message('debug', paste("Peakforest returned error: ", content))
		return(TRUE)
	}

	if (length(grep('^<html>.*Apache Tomcat.*Error report', content)) > 0)
		.self$message('error', paste("Peakforest connection error: ", content))

	return(FALSE)
})

# Get entry content {{{1
################################################################

PeakforestConn$methods( getEntryContent = function(entry.id) {
	
	# Initialize contents to return
	content <- rep(NA_character_, length(entry.id))

	# Get URLs
	urls <- .self$getEntryContentUrl(entry.id, max.length = 2048)

	# Send request
	jsonstr <- vapply(urls, function(url) .self$.getUrlScheduler()$getUrl(url), FUN.VALUE = '')

	# Get directly one JSON string for each ID
	if (length(jsonstr) == length(entry.id)) {
		first_json = jsonlite::fromJSON(jsonstr[[1]], simplifyDataFrame = FALSE)
		if ( ! is.null(first_json) && class(first_json) == 'list' && ! is.null(names(first_json))) {
			content <- jsonstr
			return(content)
		}
	}

	# Parse all JSON strings
	for (single.jsonstr in jsonstr) {

		if (.self$.checkIfError(single.jsonstr))
			break

		json <- jsonlite::fromJSON(single.jsonstr, simplifyDataFrame = FALSE)

		if ( ! is.null(json)) {
			if (class(json) == 'list' && is.null(names(json))) {
				null <- vapply(json, is.null, FUN.VALUE = TRUE)
				json.ids <- vapply(json[ ! null], function(x) as.character(x$id), FUN.VALUE = '')
				content[entry.id %in% json.ids] <- vapply(json[ ! null], function(x) jsonlite::toJSON(x, pretty = TRUE, digits = NA_integer_), FUN.VALUE = '')
			}
		}
	}

	return(content)
})

# Get entry ids {{{1
################################################################

PeakforestConn$methods( getEntryIds = function(max.results = NA_integer_) {

	# Build URL
	url <- paste(.self$getBaseUrl(), .self$.db.name, '/all/ids?token=', .self$getToken(), sep = '')

	# Send request
	json.str <- .self$.getUrlScheduler()$getUrl(url)
	.self$.checkIfError(json.str)

	# Parse JSON
	json <- jsonlite::fromJSON(json.str, simplifyDataFrame = FALSE)

	# Get IDs
	ids <- json
	ids <- as.character(ids)

	# Cut
	if ( ! is.na(max.results) && max.results > 1 && max.results < length(ids))
		ids <- ids[1:max.results]

	return(ids)
})

# Get nb entries {{{1
################################################################

PeakforestConn$methods( getNbEntries = function(count = FALSE) {

	# Build URL
	url <- paste(.self$getBaseUrl(), .self$.db.name, '/all/count?token=', .self$getToken(), sep = '')

	# Send request
	n <- as.integer(.self$.getUrlScheduler()$getUrl(url))

	return(n)
})
