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
source(file = "rscripts/rplots/lines.R")
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
	experiment.infile <- "./results/cooked/throughput.csv"
	experiment.outdir <- "./img/results"
	experiment.outfile <- "throughput"
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

# Original columns
source.factors      <- c("runtime", "policy",  "rank", "size", "nprocs", "rule")
source.variables    <- c("config", "name", "local", "mailbox", "portal")
variables.names_to  <- "operation"
variables.values_to <- "time"

# Long table columns
experiment.factors   <- c(source.factors, variables.names_to)
experiment.variables <- c(variables.values_to)

#===============================================================================
# Throughput
#===============================================================================

throughput.factors   <- c("runtime", "policy", "size", "nprocs")
throughput.variables <- c("throughput")

# Subset
throughput.df <- subset(experiment.df, rank == 0 & rule == "all2one")

# Transformations
throughput.df$size <- throughput.df$size*8
throughput.df$time <- rowSums(throughput.df[,source.variables])
throughput.df$time <- throughput.df$time/MPPA.FREQ

# Throughput
throughput.df$throughput <- throughput.df$size/throughput.df$time/MEGA

throughput.df.melted <- melt(
	data = throughput.df,
	id.vars = throughput.factors,
	measure.vars = throughput.variables
)

throughput.df.cooked <- ddply(
	throughput.df.melted,
	c(throughput.factors, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print(head(throughput.df.cooked))

#===============================================================================
# Time Plot
#===============================================================================

plot.df <- throughput.df.cooked

plot.df$runtime <- factor(plot.df$runtime, levels=c("mpi", "ipc"))
levels(plot.df$runtime) <- c("LWMPI", "IPC")

plot.df$policy<- factor(plot.df$policy, levels=c("scatter", "compact"))
levels(plot.df$policy) <- c("Scatter", "Compact")

plot.var.x  <- "size"
plot.var.y  <- "mean"
plot.factor <- "runtime"
plot.facet  <- get("nprocs") ~ get("policy")

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- "Runtime"
plot.legend.labels <- levels(as.factor(plot.df$runtime))

# X Axis
plot.axis.x.title  <- "Superstep (Message Payload Size in Bytes)"
plot.axis.x.breaks <- 2^c(11:18)
plot.axis.x.labels <- c("0 (256)", "1 (512)", "2 (1K)", "3 (2K)", "4 (4K)", "5 (8K)", "6 (16K)", "7 (32K)")

# Y Axis
plot.axis.y.title  <- "Troughput (Mbps)"
plot.axis.ymin     <- 0
plot.axis.ymax     <- max(plot.df$mean) + 25.77301
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, length.out = 7)

# Data Labels
plot.data.labels.digits <- 0

plot <- plot.lines.facet(
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
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.facet.x +
	plot.theme.facet.y

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 25,
		width = 13,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "runtime", sep = "-")
	)
} else {
	plot
}

#===============================================================================
# Time Plot
#===============================================================================

plot.factor <- "policy"
plot.facet  <- get("nprocs") ~ get("runtime")

plot.legend.title  <- "Policy"
plot.legend.labels <- levels(as.factor(plot.df$policy))

plot <- plot.lines.facet(
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
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.facet.x +
	plot.theme.facet.y

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 25,
		width = 13,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "-policy", sep = "-")
	)
} else {
	plot
}

#===============================================================================
# STACK
#===============================================================================

# Original columns
source.factors      <- c("runtime", "policy",  "rank", "size", "nprocs")
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

#===============================================================================
# Time Plot
#===============================================================================

plot.df <- subset(experiment.df.cooked, rank == 0)

plot.df$runtime <- factor(plot.df$runtime, levels=c("mpi", "ipc"))
levels(plot.df$runtime) <- c("LWMPI", "IPC")

plot.df$policy <- factor(plot.df$policy, levels=c("scatter", "compact"))
levels(plot.df$policy) <- c("Scatter", "Compact")

plot.df$operation <- factor(plot.df$operation, levels=c("config", "name", "local", "mailbox", "portal"))
levels(plot.df$operation) <- c("Config", "Name", "Local", "Mailbox", "Portal")

plot.var.x  <- "size"
plot.var.y  <- "mean"
plot.factor <- "operation"
plot.facet  <- get("nprocs") ~ get("runtime") + get("policy")

# Titles
plot.title    <- NULL
plot.subtitle <- NULL

# Legend
plot.legend.title  <- "Operation"
plot.legend.labels <- levels(as.factor(plot.df$operation))

# X Axis
plot.axis.x.title  <- "Superstep (Message Payload Size in Bytes)"
plot.axis.x.breaks <- 2^c(8:15)
plot.axis.x.labels <-
	c("256", "512", "1K", "2K", "4K", "8K", "16K", "32K")

# Y Axis
plot.axis.y.title  <- "Time (ms)"
plot.axis.ymin     <- 0
plot.axis.ymax     <- max(plot.df$mean) + 100
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, length.out = 11)

# Data Labels
plot.data.labels.digits <- 0

plot <- plot.stacks.colour(
	df = plot.df,
	var.x = plot.var.x,
	var.y = plot.var.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	palette_colour = c("#ca0020", "#f4a582", "#f7f7f7", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left2 +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x +
	plot.theme.facet.y

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 40,
		width = 20,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "time-rank0", sep = "-")
	)
} else {
	plot
}

#===============================================================================
# Time Plot
#===============================================================================

plot.df <- subset(experiment.df.cooked, nprocs == 12)

plot.var.x  <- "size"
plot.var.y  <- "mean"
plot.factor <- "operation"
plot.facet  <- get("rank") ~ get("runtime") + get("policy")

# Y Axis
plot.axis.y.title  <- "Time (ms)"
plot.axis.ymin     <- 0
plot.axis.ymax     <- max(plot.df$mean) + 100
plot.axis.y.limits <- c(plot.axis.ymin, plot.axis.ymax)
plot.axis.y.breaks <- seq(from = plot.axis.ymin, to = plot.axis.ymax, length.out = 11)

# Data Labels
plot.data.labels.digits <- 0

plot <- plot.stacks.colour(
	df = plot.df,
	var.x = plot.var.x,
	var.y = plot.var.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	palette_colour = c("#ca0020", "#f4a582", "#f7f7f7", "#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left2 +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x +
	plot.theme.facet.y

if (length(args) >= 1) {
	plot.save(
		plot,
		height = 40,
		width = 20,
		directory = experiment.outdir,
		filename = paste(experiment.outfile, "time-nprocs12", sep = "-")
	)
} else {
	plot
}
