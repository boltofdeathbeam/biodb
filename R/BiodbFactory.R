# vi: fdm=marker

# Class declaration {{{1
################################################################

#' A class for constructing biodb objects.
#'
#' This class is responsible for the creation of database connectors and database entries. You must go through the single instance of this class to create and get connectors, as well as instantiate entries. To get the single instance of this class, call the \code{getFactory()} method of class \code{Biodb}.
#'
#' @param content          The content (as character vector) of one or more database entries.
#' @param dbid  The ID of a database. The list of IDs can be obtained from the class \code{\link{BiodbDbsInfo}}.
#' @param drop             If set to \code{TRUE} and the list of entries contains only one element, then returns this element instead of the list. If set to \code{FALSE}, then returns always a list.
#' @param dwnld.chunk.size The number of entries to download before saving to cache. By default, saving to cache is only down once all requested entries have been downloaded.
#' @param id                A character vector containing database entry IDs (accession numbers).
#' @param token            A security access token for the database. Some database require such a token for all or some of their webservices. Usually you obtain the token through your account on the database website.
#' @param url              An URL to the database for which to create a connection. Each database connector is configured with a default URL, but some allow you to change it.
#'
#' @seealso \code{\link{Biodb}}, \code{\link{BiodbConn}}, \code{\link{BiodbEntry}}.
#'
#' @examples
#' # Create a Biodb instance with default settings:
#' mybiodb <- biodb::Biodb()
#'
#' # Obtain the factory instance:
#' factory <- mybiodb$getFactory()
#'
#' # Create a connection:
#' conn <- factory$createConn('chebi')
#'
#' # Get a database entry:
#' entry <- factory$getEntry('chebi', id = '2528')
#'
#' @import methods
#' @include ChildObject.R
#' @export BiodbFactory
#' @exportClass BiodbFactory
BiodbFactory <- methods::setRefClass("BiodbFactory", contains = 'ChildObject', fields = list( .conn = "list", .entries = "list", .chunk.size = "integer"))

# Constructor {{{1
################################################################

BiodbFactory$methods( initialize = function(...) {

	callSuper(...)

	.conn <<- list()
	.entries <<- list()
	.chunk.size <<- NA_integer_
})

# Create conn {{{1
################################################################

BiodbFactory$methods( createConn = function(dbid, url = NA_character_, token = NA_character_) {
    ":\n\nCreate a connection to a database."

    # Has a connection been already created for this database?
	if (dbid %in% names(.self$.conn))
		.self$message('error', paste0('A connection of type ', dbid, ' already exists. Please use method getConn() to access it.'))

    # Get connection class
    conn.class <- .self$getBiodb()$getDbsInfo()$get(dbid)$getConnClass()

	# Create connection instance
	conn <- conn.class$new(dbid = dbid, parent = .self)
    if ( ! is.na(url))
    	conn$getDbInfo()$setBaseUrl(url)

    # Set token
    if ( ! is.na(token))
	    conn$setToken(token)

	# Register new dbid instance
	.self$.conn[[dbid]] <- conn

	return (.self$.conn[[dbid]])
})

# Get conn {{{1
################################################################

BiodbFactory$methods( getConn = function(dbid) {
	":\n\nGet the connection to a database."

	if ( ! dbid %in% names(.self$.conn))
		.self$createConn(dbid)

	return (.self$.conn[[dbid]])
})


# Set chunk size {{{1
################################################################

BiodbFactory$methods( setDownloadChunkSize = function(dwnld.chunk.size) {
	":\n\nSet the download chunk size."

	.chunk.size <<- as.integer(dwnld.chunk.size)
})

# Create entry {{{1
################################################################

BiodbFactory$methods( createEntry = function(dbid, content, drop = TRUE) {
	":\n\nCreate database entry objects from string content."

	entries <- list()

	if (length(content) > 0) {
		.self$message('info', paste('Creating ', dbid, ' entries from ', length(content), ' content(s).', sep = ''))

		# Check that class is known
		.self$getBiodb()$getDbsInfo()$checkIsDefined(dbid)

		# Get entry class
    	entry.class <- .self$getBiodb()$getDbsInfo()$get(dbid)$getEntryClass()

		# Get connection
		conn <- .self$getConn(dbid)

    	# Loop on all contents
    	.self$message('debug', paste('Parsing ', length(content), ' ', dbid, ' entries.', sep = ''))
		for (single.content in content) {

			# Create empty entry instance
    		entry <- entry.class$new(parent = conn)

			# Parse content
			if ( ! is.null(single.content) && ! is.na(single.content))
				entry$parseContent(single.content)

			entries <- c(entries, entry)
		}

		# Replace elements with no accession id by NULL
    	entries.without.accession <- vapply(entries, function(x) is.na(x$getFieldValue('ACCESSION')), FUN.VALUE = TRUE)
    	if (any(entries.without.accession)) {
	    	n <- sum(entries.without.accession)
    		.self$message('debug', paste('Found', n, if (n > 1) 'entries' else 'entry', 'without an accession number. Set', if (n > 1) 'them' else 'it', 'to NULL.'))
			entries[entries.without.accession] <- list(NULL)
    	}

		# If the input was a single element, then output a single object
		if (drop && length(content) == 1)
			entries <- entries[[1]]
	}

	return(entries)
})

# Get entry {{{1
################################################################

BiodbFactory$methods( getEntry = function(dbid, id, drop = TRUE) {
	":\n\nCreate database entry objects from IDs (accession numbers)."

	id <- as.character(id)

	# Use factory cache
	if (.self$getBiodb()$getConfig()$isEnabled('factory.cache')) {
		# What entries are missing from factory cache
		missing.ids <- .self$.getMissingEntryIds(dbid, id)

		if (length(missing.ids) > 0) {
			new.entries <- .self$.createNewEntries(dbid, missing.ids, drop = FALSE)
			.self$.storeNewEntries(dbid, missing.ids, new.entries)
		}

		# Get entries
		entries <- unname(.self$.getEntries(dbid, id))

		# If the input was a single element, then output a single object
		if (drop && length(id) == 1)
			entries <- entries[[1]]
	}

	# Do not use factory cache and create new entries for all IDs
	else
		entries <- .self$.createNewEntries(dbid, id, drop = drop)

	return(entries)
})

# Get entry content {{{1
################################################################

BiodbFactory$methods( getEntryContent = function(dbid, id) {
	":\n\nGet the contents of database entries from IDs (accession numbers)."

	content <- character(0)

	if ( ! is.null(id) && length(id) > 0) {

		id <- as.character(id)

		# Debug
		.self$message('info', paste0("Get ", dbid, " entry content(s) for ", length(id)," id(s)..."))

		# Download full database if possible
		if (.self$getBiodb()$getCache()$isWritable() && methods::is(.self$getConn(dbid), 'BiodbDownloadable')) {
			.self$message('debug', paste('Ask for whole database download of ', dbid, '.', sep = ''))
			.self$getConn(dbid)$download()
		}

		# Initialize content
		if (.self$getBiodb()$getCache()$isReadable()) {
			# Load content from cache
			content <- .self$getBiodb()$getCache()$loadFileContent(dbid = dbid, subfolder = 'shortterm', name = id, ext = .self$getConn(dbid)$getEntryContentType())
			missing.ids <- id[vapply(content, is.null, FUN.VALUE = TRUE)]
		}
		else {
			content <- lapply(id, as.null)
			missing.ids <- id
		}

		# Remove duplicates
		n.duplicates <- sum(duplicated(missing.ids))
		missing.ids <- missing.ids[ ! duplicated(missing.ids)]

		# Debug
		if (any(is.na(id)))
			.self$message('info', paste0(sum(is.na(id)), " ", dbid, " entry ids are NA."))
		if (.self$getBiodb()$getCache()$isReadable()) {
			.self$message('info', paste0(sum( ! is.na(id)) - length(missing.ids), " ", dbid, " entry content(s) loaded from cache."))
			if (n.duplicates > 0)
				.self$message('info', paste0(n.duplicates, " ", dbid, " entry ids, whose content needs to be fetched, are duplicates."))
		}

		# Get contents
		if (length(missing.ids) > 0 && ( ! methods::is(.self$getConn(dbid), 'BiodbDownloadable') || ! .self$getConn(dbid)$isDownloaded())) {

			.self$message('info', paste0(length(missing.ids), " entry content(s) need to be fetched from ", dbid, " database."))

			# Use connector to get missing contents
			conn <- .self$getConn(dbid)

			# Divide list of missing ids in chunks (in order to save in cache regularly)
			chunks.of.missing.ids = if (is.na(.self$.chunk.size)) list(missing.ids) else split(missing.ids, ceiling(seq_along(missing.ids) / .self$.chunk.size))

			# Loop on chunks
			missing.contents <- NULL
			for (ch.missing.ids in chunks.of.missing.ids) {

				ch.missing.contents <- conn$getEntryContent(ch.missing.ids)

				# Save to cache
				if ( ! is.null(ch.missing.contents) && .self$getBiodb()$getCache()$isWritable())
					.self$getBiodb()$getCache()$saveContentToFile(ch.missing.contents, dbid = dbid, subfolder = 'shortterm', name = ch.missing.ids, ext = .self$getConn(dbid)$getEntryContentType())

				# Append
				missing.contents <- c(missing.contents, ch.missing.contents)

				# Debug
				if (.self$getBiodb()$getCache()$isReadable())
					.self$message('info', paste0("Now ", length(missing.ids) - length(missing.contents)," id(s) left to be retrieved..."))
			}

			# Merge content and missing.contents
			content[id %in% missing.ids] <- vapply(id[id %in% missing.ids], function(x) missing.contents[missing.ids %in% x], FUN.VALUE = '')
		}
	}

	return(content)
})

# Show {{{1
################################################################

BiodbFactory$methods( show = function() {
	cat("Biodb factory instance.\n")
})

# Private methods {{{1
################################################################

# Create new entries {{{2
################################################################

BiodbFactory$methods( .createNewEntries = function(dbid, ids, drop) {

	new.entries <- list()

	if (length(ids) > 0) {

		# Debug
		.self$message('info', paste("Creating", length(ids), "entries from ids", paste(if (length(ids) > 10) ids[1:10] else ids, collapse = ", "), "..."))

		# Get contents
		content <- .self$getEntryContent(dbid, ids)

		# Create entries
		new.entries <- .self$createEntry(dbid, content = content, drop = drop)
	}

	return(new.entries)
})

# Create entries db slot {{{2
################################################################

BiodbFactory$methods( .createEntriesDbSlot = function(dbid) {

	if ( ! dbid %in% names(.self$.entries))
		.self$.entries[[dbid]] <- list()
})

# Get entries {{{2
################################################################

BiodbFactory$methods( .getEntries = function(dbid, ids) {

	ids <- as.character(ids)

	.self$.createEntriesDbSlot(dbid)

	return(.self$.entries[[dbid]][ids])
})

# Store new entries {{{2
################################################################

BiodbFactory$methods( .storeNewEntries = function(dbid, ids, entries) {

	ids <- as.character(ids)

	.self$.createEntriesDbSlot(dbid)
	
	names(entries) <- ids

	.self$.entries[[dbid]] <- c(.self$.entries[[dbid]], entries)
})

# Get missing entry IDs {{{2
################################################################

BiodbFactory$methods( .getMissingEntryIds = function(dbid, ids) {

	ids <- as.character(ids)

	.self$.createEntriesDbSlot(dbid)

	missing.ids <- ids[ ! ids %in% names(.self$.entries[[dbid]])]

	return(missing.ids)
})
