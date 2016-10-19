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

			# Convert string to data frame
			tc <- textConnection("csv", "w")
			df <- read.csv(tc)
		}

		# Replace elements with no accession id by NULL
		entries <- lapply(entries, function(x) if (is.na(x$getField(BIODB.ACCESSION))) NULL else x)

		# If the input was a single element, then output a single object
		if (drop && length(contents) == 1)
			entries <- entries[[1]]

		return(entries)
	}
}
