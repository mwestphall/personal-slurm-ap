#!/usr/bin/env Rscript
# Usage: Rscript plot.R
# Concatenates each `N, N**2` line from *_squared.txt in the current directory into input.csv, then plots it.
writeLines(unlist(lapply(list.files(pattern = "_squared\\.txt$"), readLines)), "input.csv")
d <- read.csv("input.csv", header = FALSE)
png("plot.png")
plot(d[[1]], d[[2]], xlab = "x", ylab = "y")
invisible(dev.off())
