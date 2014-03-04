options(digits=4, width=70)
library(zoo)
library(tseries)

getQuotes <- function(csv, quote = c("adjclose")) {
  x <- read.table(csv, header = TRUE, sep = ",", as.is = TRUE, fill = TRUE)
  x <- na.omit(x)
  
  cols <- pmatch(quote, names(x)[-1]) + 1
  if (any(is.na(cols)))
    stop("This quote is not available")
  
  dat <- as.Date(as.character(x[, 1]), "%Y-%m-%d")
  x <- as.matrix(x[, cols, drop = FALSE])
  rownames(x) <- NULL
  y <- zoo(x, dat)
  y <- y[, seq_along(cols), drop = FALSE]
  
  return (y)
}
