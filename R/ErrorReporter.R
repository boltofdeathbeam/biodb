# vi: fdm=marker

# CLASS DECLARATION {{{1
################################################################

ErrorReporter <- methods::setRefClass("ErrorReporter", contains = 'BiodbObserver')

# MESSAGE {{{1
################################################################

ErrorReporter$methods( message = function(type = MSG.INFO, msg, class = NA_character_, method = NA_character_, level = 1) {

	# Raise error
	if (type == MSG.ERROR) {
		caller.info <- if (is.na(class)) '' else class
		caller.info <- if (is.na(method)) caller.info else paste(caller.info, method, sep = '::')
		if (nchar(caller.info) > 0) caller.info <- paste('[', caller.info, '] ', sep = '')
		stop(paste0(caller.info, msg))
	}
})