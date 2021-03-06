% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/BiodbConn.R
\docType{class}
\name{BiodbConn-class}
\alias{BiodbConn-class}
\alias{BiodbConn}
\title{The mother abstract class of all database connectors.}
\arguments{
\item{count}{If set to \code{TRUE} and no straightforward way exists to get number of entries, count the output of \code{getEntryIds()}.}

\item{entry.id}{The identifiers (e.g.: accession numbers) as a \code{character vector} of the database entries.}

\item{max.results}{The maximum of elements to return from the method.}
}
\description{
This is the super class of all connector classes. All methods defined here are thus common to all connector classes. Some connector classes inherit directly from this abstract class. Some others inherit from intermediate classes \code{\link{RemotedbConn}} and \code{\link{MassdbConn}}. As for all connector concrete classes, you won't have to create an instance of this class directly, but you will instead go through the factory class. However, if you plan to develop a new connector, you will have to call the constructor of this class. See section Fields for a list of the constructor's parameters. Concrete classes may have direct web services methods or other specific methods implemented, in which case they will be described inside the documentation of the concrete class. Please refer to the documentation of each concrete class for more information. The database direct web services methods will be named "ws.*".
}
\section{Fields}{

\describe{
\item{\code{dbid}}{The identifier of the connector.}
}}

\section{Methods}{

\describe{
\item{\code{getBaseUrl()}}{:

Get the base URL of this connector.}

\item{\code{getDbInfo()}}{:

Get the database information associated with this connector.}

\item{\code{getEntryContent(entry.id)}}{:

Get the content of an entry.}

\item{\code{getEntryContentType()}}{:

Get the base URL of the content type.}

\item{\code{getEntryIds(max.results = NA_integer_)}}{:

Get entry identifiers from the database.}

\item{\code{getId()}}{:

Get the identifier of this connector.}

\item{\code{getNbEntries(count = FALSE)}}{:

Get the number of entries contained in this database.}

\item{\code{getWsUrl()}}{:

Get the web service URL of this connector.}
}}

\examples{
# Create an instance with default settings:
mybiodb <- biodb::Biodb()

# Create a connector
conn <- mybiodb$getFactory()$createConn('chebi')

# Get 10 identifiers from the database:
ids <- conn$getEntryIds(10)

# Get number of entries contained in the database:
n <- conn$getNbEntries()

}
\seealso{
\code{\link{BiodbFactory}}, \code{\link{RemotedbConn}}, \code{\link{MassdbConn}}.
}
