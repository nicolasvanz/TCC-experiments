#
# MIT License
#
# Copyright (c) 2011-2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# R Libraries
library(ggplot2)
library(reshape2)
library(scales)
library(plyr)
library(tidyverse)

# My Utilities
source(file = "rscripts/rplots/lines.R")
source(file = "rscripts/rplots/bars.R")
source(file = "rscripts/rplots/stacks.R")
source(file = "rscripts/rplots/theme.R")
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Experiment Information
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/detail/gf.csv"
	experiment.outdir <- "./results/plots/detail"
	experiment.outfile <- "detail"
}

if (length(args) >= 4) {
	experiment.power.it <- args[4]
} else {
	experiment.power.it <- 0
}

#===============================================================================
# Input Reading
#===============================================================================

experiment.df <- read_delim(
	file = experiment.infile,
	col_names = TRUE,
	delim = ";"
)

#===============================================================================
# Pre-changes
#===============================================================================

#variant;cluster;type;id;cycle;amount

# Changes number procs to clusters used
#experiment.df$cluster <- (experiment.df$cluster / 12)
experiment.df <- experiment.df %>%
	mutate(id = ifelse(id <= 1, id, (id / 12) + 1))
experiment.df <- experiment.df %>%
	mutate(cycle = ifelse(id == 0, cycle / (1200 * (cluster / 12)), cycle / 1200))
experiment.df$time <- (experiment.df$cycle / MPPA.FREQ / MILLI)
experiment.df <- experiment.df %>%
	mutate(rule = ifelse(id == 0, "master", "slave"))

print(head(experiment.df))
print(tail(experiment.df))

#===============================================================================
# Pre-Processing
#===============================================================================

experiment.df.melted <- melt(
	data = experiment.df,
	id.vars = c("cluster", "type", "id"),
	measure.vars = c("time"),
)
experiment.df.cooked <- ddply(
	experiment.df.melted,
	c("cluster", "type", "id", "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

if (TRUE) {
	experiment.df.cooked <- filter(experiment.df.cooked, id == 0)
	print("receive")
	abc.df <- filter(experiment.df.cooked, type == "receive")
	total.df <- aggregate(
		x   = abc.df$mean,
		by  = list(abc.df$id, abc.df$cluster),
		FUN = sum
	)
	print(total.df)

	print("send")
	abc.df <- filter(experiment.df.cooked, type == "send")
	total.df <- aggregate(
		x   = abc.df$mean,
		by  = list(abc.df$id, abc.df$cluster),
		FUN = sum
	)
	print(total.df)

	print("Generate")
	abc.df <- filter(experiment.df.cooked, type == "generate")
	total.df <- aggregate(
		x   = abc.df$mean,
		by  = list(abc.df$id, abc.df$cluster),
		FUN = sum
	)
	print(total.df)

	print("COMM")
	abc.df <- filter(experiment.df.cooked, type != "generate")
	total.df <- aggregate(
		x   = abc.df$mean,
		by  = list(abc.df$id, abc.df$cluster),
		FUN = sum
	)
	print(total.df)
	print("total")
	abc.df <- filter(experiment.df.cooked)
	total.df <- aggregate(
		x   = abc.df$mean,
		by  = list(abc.df$id, abc.df$cluster),
		FUN = sum
	)
	print(total.df)
}

#===============================================================================
# Weak Scaling
#===============================================================================

print("Weak Scaling")

plot.df <- filter(experiment.df.cooked, type != "generate")

print(plot.df)

plot.x  <- "id"
plot.y  <- "mean"
plot.factor <- "type"
plot.facet  <- "cluster"

# Titles
plot.title <- NULL#"Master and User Core Usage"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operation"
plot.legend.labels <- c("Send", "Receive")
plot.df$type <- factor(plot.df$type, levels=c("send", "receive"))

# X Axis
plot.axis.x.title <- "Master (M) and Submasters (S1-S16)"
plot.axis.x.breaks <- seq(0, 16)
plot.axis.x.labels <- c("M", "S1", "S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10", "S11", "S12", "S13", "S14", "S15", "S16")

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 2000, by = 200) # by = 10
plot.axis.y.limits <- c(0, 2000)

print("OK")

# Facets
#plot.df$core <- factor(plot.df$core, levels=c("kernel", "user"))
#levels(plot.df$core) <- c("Master Core", "Slave Core")

#===============================================================================
# Plot
#===============================================================================

plot <- plot.stacks.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.labels = plot.axis.x.labels,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	colour = c("#92c5de", "#0571b0", "#ca0020") # mid  
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x2

print("OK")

plot.save(
	plot = plot,
	width = 18,
	height = 5,
	directory = experiment.outdir,
	filename  = experiment.outfile
)

print("OK")

exit(0)

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$api <- factor(plot.df$api, levels=c("baseline", "comm", "daemons"))
levels(plot.df$api) <- c("Baseline", "Parital", "Full")

# X Axis
if (experiment.outfile == "is") {
	plot.axis.x.title <- "Number of Clusters (MPI Processes)"
} else {
	plot.axis.x.title <- ""
}
plot.axis.x.breaks <- 2^c(0:4)
plot.axis.x.labels <- c("1 (12)", "2 (24)", "4 (48)", "8 (96)", "16 (192)")

# Y Axis
if (experiment.outfile == "fn") {
	plot.axis.y.title <- "Weak Scaling Efficiency"
} else if (experiment.outfile == "fast") {
	plot.axis.y.title <- "Weak Scaling Efficiency"
} else {
	plot.axis.y.title <- ""
}
plot.axis.ymin  <- 0.0
plot.axis.ymax  <- 1.1
plot.axis.ystep <- 0.1

plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = plot.axis.ystep)

plot <- plot.linespoint.facet.colour(
	df = plot.df,
	factor = plot.var.x,
	respvar = plot.var.y,
	param = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.x.trans = "log2",
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.facet.x

if (experiment.outfile == "fn") {
	plot <- plot + plot.theme.legend.bottom.left
} else {
	plot <- plot + plot.theme.legend.none
}

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 4,
		width = 4.7,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "speedup", sep = "-")
	)
} else {
	plot
}

#===============================================================================
# Time Plot
#===============================================================================

print("Time Plot")

plot.df <- rbind(baseline.df.cooked, comm.df.cooked, daemons.df.cooked)

plot.x <- "nprocs"
plot.y <- "mean"
plot.factor <- "api"
plot.facet <- "exp"

# Titles
plot.title <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title <- "Nanvix Variant"
plot.legend.labels <- c("Baseline", "Partial", "Full")
plot.df$api <- factor(plot.df$api, levels=c("baseline", "comm", "daemons"))
levels(plot.df$api) <- c("Baseline", "Partial", "Full")

# X Axis (Look the paper, we reuse the x title from weak scaling)
if (experiment.outfile == "is") {
	plot.axis.x.title <- "Number of Clusters (MPI Processes)"
} else {
	plot.axis.x.title <- ""
}
plot.df$nprocs <- as.factor(plot.df$nprocs)
plot.axis.x.breaks <- c("1 (12)", "2 (24)", "4 (48)", "8 (96)", "16 (192)")

# Y Axis
if (experiment.outfile == "fn") {
	plot.axis.y.title <- "Time (s)"
} else if (experiment.outfile == "fast") {
	plot.axis.y.title <- "Time (s)"
} else {
	plot.axis.y.title <- ""
}

# Internal label offset
plot.labels.hjust <- -0.22
plot.labels.vjust <- 0.5

if (experiment.outfile == "km") {
	plot.axis.ystep <- 300
	plot.axis.ymax  <- 10*plot.axis.ystep
} else if (experiment.outfile == "gf") {
	plot.axis.ystep <- 500
	plot.axis.ymax  <- 9*plot.axis.ystep
} else if (experiment.outfile == "fn") {
	plot.axis.ystep <- 25
	plot.axis.ymax  <- 6*plot.axis.ystep
} else if (experiment.outfile == "fast") {
	plot.axis.ystep <- 1050
	plot.axis.ymax  <- 6*plot.axis.ystep
} else if (experiment.outfile == "is") {
	plot.axis.ystep <- 250
	plot.axis.ymax  <- 6*plot.axis.ystep
} else { # lu
	plot.axis.ystep <- 400
	plot.axis.ymax  <- 6*plot.axis.ystep
}

plot.axis.ymin <- 0

plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, by = plot.axis.ystep)

# Data Labels
plot.data.labels.digits <- 0

plot <- plot.bars.facet.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	title = plot.title,
	subtitle = plot.subtitle,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	data.labels.hjust = plot.labels.hjust,
	data.labels.vjust = plot.labels.vjust,
	data.labels.angle = 90,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (experiment.outfile == "fn") {
	plot <- plot + plot.theme.legend.bottom.left
} else {
	plot <- plot + plot.theme.legend.none
}

if (length(args) >= 1) {
	plot.save(
		plot,
		width = 5,
		height = 4,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "time", sep = "-")
	)
} else {
	plot
}

