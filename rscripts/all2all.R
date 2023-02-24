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
source(file = "rscripts/rplots/stacks.R")
source(file = "rscripts/rplots/theme.R")
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")

#===============================================================================
# Experiment Information
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/all2all.csv"
	experiment.outdir <- "./img/results"
	experiment.outfile <- "all2all"
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
# Filter
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

# Original columns
source.factors      <- c("runtime", "policy",  "rank", "size")
source.variables    <- c("config", "name", "local", "mailbox", "portal")
variables.names_to  <- "operation"
variables.values_to <- "time"

# Long table columns
experiment.factors   <- c(source.factors, variables.names_to)
experiment.variables <- c(variables.values_to)

experiment.df <- pivot_longer(experiment.df,
	cols = all_of(source.variables),
	names_to = variables.names_to,
	values_to = variables.values_to
)

experiment.df$time <- experiment.df$time/MPPA.FREQ/MILLI

experiment.df.melted <- melt(
	data = experiment.df,
	id.vars = experiment.factors,
	measure.vars = experiment.variables
)

experiment.df.cooked <- ddply(
	experiment.df.melted,
	c(experiment.factors, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print(head(experiment.df.cooked))

#===============================================================================
# Time Plot
#===============================================================================

plot.df <- subset(experiment.df.cooked, rank == 0 & runtime != "simplified")

plot.df$runtime <- factor(plot.df$runtime, levels=c("mpi", "ipc"))
levels(plot.df$runtime) <- c("LWMPI", "IPC")

plot.df$policy <- factor(plot.df$policy, levels=c("compact", "scatter"))
levels(plot.df$policy) <- c("Compact", "Scatter")

plot.df$operation <- factor(plot.df$operation, levels=c("name", "local", "portal", "mailbox", "config"))
levels(plot.df$operation) <- c("Name Service", "Local Data Copy", "Portal", "Mailbox", "Comm. Management")

plot.var.x  <- "size"
plot.var.y  <- "mean"
plot.factor <- "operation"
plot.facet  <- "policy"

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- NULL
plot.legend.labels <- levels(as.factor(plot.df$operation))

# X Axis
plot.axis.x.title  <- "Superstep (Message Payload Size in Bytes)"
plot.axis.x.breaks <- 2^c(8:15)
plot.axis.x.labels <-
	c("0 (256)", "1 (512)", "2 (1K)", "3 (2K)", "4 (4K)", "5 (8K)", "6 (16K)", "7 (32K)")

# Y Axis
plot.axis.y.title  <- "Time (ms)"
plot.axis.ymin     <- 0
plot.axis.ymax     <- 400
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax + 10)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, length.out = 11)

plot <- plot.stacks.colour(
	df = plot.df,
	var.x = plot.var.x,
	var.y = plot.var.y,
	factor = plot.factor,
	facet = ~ get("policy") + get("runtime"),
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	palette_colour = c("#ffffff", "#bfbfbf", "#808080", "#404040", "#000000")
) + plot.theme.title +
	plot.theme.legend.top.left2 +
	plot.theme.axis.x.angle(25) +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 5,
		width = 20,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "time-policy-runtime", sep = "-")
	)
} else {
	plot
}

plot <- plot.stacks.colour(
	df = plot.df,
	var.x = plot.var.x,
	var.y = plot.var.y,
	factor = plot.factor,
	facet = ~ get("runtime") + get("policy"),
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	palette_colour = c("#ffffff", "#bfbfbf", "#808080", "#404040", "#000000")
) + plot.theme.title +
	plot.theme.legend.top.left2 +
	plot.theme.axis.x.angle(25) +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 5,
		width = 20,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "time-runtime-policy", sep = "-")
	)
} else {
	plot
}
