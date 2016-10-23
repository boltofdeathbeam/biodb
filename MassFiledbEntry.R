if ( ! exists('MassFiledbEntry')) {

	source('BiodbEntry.R')

	###########################
	# MASSBANK SPECTRUM CLASS #
	###########################
	
	MassFiledbEntry <- setRefClass("MassFiledbEntry", contains = "BiodbEntry")

	###########
	# FACTORY #
	###########
	
	createMassFiledbEntryFromCsv <- function(contents, drop = TRUE) {

		entries <- list()

		# Loop on all contents
		for (csv in contents) {

			# Create instance
			entry <- MassFiledbEntry$new()

			# Convert string to data frame
			tc <- textConnection("csv", "r")
			df <- read.csv(tc)

			entries <- c(entries, entry)
		}

		# Replace elements with no accession id by NULL
		entries <- lapply(entries, function(x) if (is.na(x$getField(BIODB.ACCESSION))) NULL else x)

		# If the input was a single element, then output a single object
		if (drop && length(contents) == 1)
			entries <- entries[[1]]

		return(entries)
	}
}
