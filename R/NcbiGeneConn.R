# vi: fdm=marker

# Class declaration {{{1
################################################################

NcbiGeneConn <- methods::setRefClass("NcbiGeneConn", contains = "NcbiEntrezConn")

# Constructor {{{1
################################################################

NcbiGeneConn$methods( initialize = function(...) {

	callSuper(content.type = BIODB.XML, db.name = 'gene', ...)
})

# Get entry content {{{1
################################################################

NcbiGeneConn$methods( getEntryContent = function(id) {

	# Initialize return values
	content <- rep(NA_character_, length(id))

	# Get URLs
	urls <- .self$getEntryContentUrl(id)

	# Request
	content <- vapply(urls, function(url) .self$.getUrlScheduler()$getUrl(url), FUN.VALUE = '')

	return(content)
})

# Do get entry content url {{{1
################################################################

NcbiGeneConn$methods( .doGetEntryContentUrl = function(id, concatenate = TRUE) {

	url <- paste0('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=', id, '&rettype=xml&retmode=text')

	return(url)
})