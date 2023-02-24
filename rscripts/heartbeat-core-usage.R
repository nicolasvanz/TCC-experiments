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
library(grid, warn.conflicts = FALSE)
library(gridExtra, warn.conflicts = FALSE)

# My Utilities
source(file = "rscripts/rplots/stacks.R")
source(file = "rscripts/rplots/lines.R")
source(file = "rscripts/rplots/bars.R")
source(file = "rscripts/rplots/theme.R")
source(file = "rscripts/rplots/utils.R")
source(file = "rscripts/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Input Reading
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

if (length(args) >= 3) {
	experiment.infile <- args[1]
	experiment.outdir <- args[2]
	experiment.outfile <- args[3]
} else {
	experiment.infile <- "./results/cooked/microbenchmarks/task-core-usage.csv"
	experiment.outdir <- "./results/plots/microbenchmarks"
	experiment.outfile <- "core-usage"
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
# Rename
#===============================================================================

# Header
# version;service;it;mtime;dtime;utime;total;kerror;cerror
# version;run;it;mtime;dtime;utime;total;kerror;cerror

experiment.df <- experiment.df %>% mutate(total = total - (kerror + cerror))

# Separate times
usage.df <- data.frame(
	version           = experiment.df$version,
	it                = experiment.df$it,
	user_user         = experiment.df$utime,
	user_idle         = (experiment.df$total - experiment.df$utime),
	kernel_master     = experiment.df$mtime,
	kernel_dispatcher = experiment.df$dtime,
	kernel_idle       = (experiment.df$total - (experiment.df$mtime + experiment.df$dtime))
)

# Convert cycles to ms
times_cols <- c("user_user", "user_idle", "kernel_master", "kernel_dispatcher", "kernel_idle")
usage.df[times_cols] <- lapply(usage.df[times_cols], function(x) x/MPPA.FREQ/MILLI)

usage.df.long <- pivot_longer(usage.df,
	cols = all_of(times_cols),
	names_to = c("core", "flow"),
	names_sep = "_",
	values_to = "time"
)

#===============================================================================
# Pre-Processing
#===============================================================================

variables.id <- c("version", "core", "flow")
variables <- c("time")

usage.df.melted <- melt(
	data = usage.df.long,
	id.vars = variables.id,
	measure.vars = variables
)

usage.df.cooked <- ddply(
	usage.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

usage.df.cooked.total <- aggregate(
	x   = usage.df.cooked$mean,
	by  = list(usage.df.cooked$version, usage.df.cooked$core),
	FUN = sum
)

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- usage.df.cooked

print(head(plot.df))

plot.x      <- "version"
plot.y      <- "mean"
plot.factor <- "flow"
plot.facet  <- "core"

# Titles
plot.title <- NULL#"Master and User Core Usage"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Execution Flow"
plot.legend.labels <- c("Idle", "User Thread", "Dispatcher", "Master Thread")

# X Axis
plot.axis.x.title <- "Heartbeat Version"
plot.df$version <- factor(plot.df$version, levels=c("baseline", "task"))
levels(plot.df$version) <- c("Baseline", "Task")
plot.axis.x.breaks <- levels(as.factor(plot.df$version))
force(plot.axis.x.breaks)

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 0.75, by = 0.15) # by = 10
plot.axis.y.limits <- c(0, 0.75)
plot.df$flow <- factor(plot.df$flow, levels=c("idle", "user", "dispatcher", "master"))

# Facets
plot.df$core <- factor(plot.df$core, levels=c("kernel", "user"))
levels(plot.df$core) <- c("Master Core", "User Core")

#===============================================================================
# Plot
#===============================================================================

plot <- plot.stacks(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels
) + plot.theme.title +
	plot.theme.legend.center.right +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

if (FALSE) {
	#plot.legend.labels <- c("Dispatcher", "Idle", "User Thread", "Master Thread")
	#plot.df$flow <- factor(plot.df$flow, levels=c("dispatcher", "idle", "user", "master"))

	plot <- plot.stacks.colour(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		facet = plot.facet,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.breaks = plot.axis.y.breaks,
		axis.y.limits = plot.axis.y.limits,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		palette_colour = c("#fee0d2", "#fc9272", "#9ecae1", "#de2d26"),
	) + plot.theme.title +
		plot.theme.legend.center.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor +
		plot.theme.facet.x
}

plot.save(
	plot = plot,
	width = 7,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(experiment.outfile, "time", sep = "-")
)

if (FALSE) {
#===============================================================================
# Power
#===============================================================================

#===============================================================================
# Input Reading
#===============================================================================

# Experiment File
power.infile <- paste(
	"./results",
	"cooked",
	experiment.nanvix.version,
	paste(experiment.name, "profile.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile <- paste(
	"./results",
	"cooked",
	experiment.nanvix.version,
	paste(experiment.name, "power.csv", sep = "-"),
	sep = "/"
)

# Generate power table
power.df <- experiment.generate.power(
	experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
	experiment.name = experiment.name,
	experiment.outfile = power.outfile
)

#===============================================================================
# Pre-Processing
#===============================================================================

usage.df.total <- setNames(
	aggregate(
		x   = usage.df.cooked$mean,
		by  = list(usage.df.cooked$version, usage.df.cooked$core),
		FUN = sum
	),
	c("version", "core", "time")
)

energy.usage.df <- merge(
	usage.df.total,
	power.df
)

energy.usage.df$energy <- energy.usage.df$power*energy.usage.df$time
energy.usage.df <- energy.usage.df %>% filter(core == "user")

#===============================================================================
# Energy Plot
#===============================================================================

plot.x      <- "version"
plot.y      <- "energy"
plot.factor <- "version"

# Titles
plot.title    <- "Energy of Core Usage Benchmark"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Heartbeat Version"
plot.legend.labels <- c("Baseline", "Task")

# X Axis
plot.axis.x.title <- "Heartbeat Version"
plot.axis.x.breaks <- c("Baseline", "Task")

# Y Axis
plot.axis.y.title <- "Energy (uJ)"

# Data Labels
plot.data.labels.digits <- 1

plot.df <- energy.usage.df
plot.axis.y.limits <- c(0, 6)

if (do_gray) {
	plot <- plot.bars(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.limits = plot.axis.y.limits,
		data.labels.digits = plot.data.labels.digits
	) + plot.theme.title +
		plot.theme.legend.none +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor
} else {
	plot <- plot.bars.colour(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.limits = plot.axis.y.limits,
		data.labels.digits = plot.data.labels.digits,
		palette_colour = c("#de2d26", "#3182bd")
	) + plot.theme.title +
		plot.theme.legend.none +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor
}

plot.save(
	plot = plot,
	width = 3.5,
	height = 5,
	directory = outdir,
	filename  = paste(
		experiment.name,
		"energy",
		sep = "-"
	)
)

if (do_arrange)
{
	plot.energy <- plot.bars(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		title = "Energy",
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.limits = plot.axis.y.limits,
		data.labels.digits = plot.data.labels.digits
	) + plot.theme.title +
		plot.theme.legend.none +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor

	force(plot.energy)

	arrange <- grid.arrange(
		plot.time,
		plot.energy,
		nrow = 1,
		widths = c(1.5,1),
		top = textGrob("Heartbeat Performance", gp=gpar(fontsize=20,font=8))
	)

	plot.save(
		plot = arrange,
		width = 7,
		height = 5,
		directory = outdir,
		filename  = paste(
			experiment.name,
			"all",
			sep = "-"
		)
	)
}
}
