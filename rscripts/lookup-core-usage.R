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
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(dplyr, warn.conflicts = FALSE)
library(tidyr, warn.conflicts = FALSE)

# My Utilities
source(file = "rscripts/include/rplots/utils.R")
source(file = "rscripts/include/rplots/theme.R")
source(file = "rscripts/include/rplots/stacks.R")
source(file = "rscripts/include/rplots/bars.R")
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Experiment Information
#===============================================================================

experiment.name = "lookup-core-usage"
experiment.nanvix.version = "4ef39d3"

#===============================================================================
# Input Reading
#===============================================================================

args = commandArgs(trailingOnly=TRUE)

# Experiment File
experiment.file<-ifelse(
	length(args) >= 2,
	args[1],
	paste(
		"./results",
		"cooked",
		experiment.nanvix.version,
		paste(experiment.name, "csv", sep = "."),
		sep = "/"
	)
)

# Output Directory
outdir <- ifelse(
	length(args) >= 3,
	args[2],
	getwd()
)

experiment.df <- read.table(file = experiment.file, sep = ";", header = TRUE)

#===============================================================================
# Rename
#===============================================================================

# Header
# version;service;it;mtime;dtime;utime;total;kerror;cerror

experiment.df <- experiment.df %>% mutate(total = total - (kerror + cerror))

# Separate times
usage.df <- data.frame(
	version           = experiment.df$version,
	service           = experiment.df$service,
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

plot.x      <- "version"
plot.y      <- "mean"
plot.factor <- "flow"
plot.facet  <- "core"

# Titles
plot.title <- "Master and User Core Usage"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Execution Flow"
plot.legend.labels <- c("Idle", "User", "Dispatcher", "Kernel")

# X Axis
plot.axis.x.title <- "IKC Version"
plot.df$version <- factor(plot.df$version, levels=c("baseline", "task"))
levels(plot.df$version) <- c("Baseline", "Task Engine")
plot.axis.x.breaks <- levels(as.factor(plot.df$version))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 2, by = 0.3) # by = 10
plot.axis.y.limits <- c(0, 2)
plot.df$flow <- factor(plot.df$flow, levels=c("idle", "user", "dispatcher", "master"))

# Facets
plot.df$core <- factor(plot.df$core, levels=c("kernel", "user"))
levels(plot.df$core) <- c("Kernel Core", "User Core")

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
	title = plot.title,
	subtitle = plot.subtitle,
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

plot.save(
	plot = plot,
	width = 6.0,
	height = 6.0,
	directory = outdir,
	filename  = paste(experiment.name, "time", sep = "-")
)

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
plot.factor <- "core"

# Titles
plot.title    <- "Energy of Core Usage Benchmark"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "IKC Version"
plot.legend.labels <- c("Baseline", "Task")

# X Axis
plot.axis.x.title <- "IKC Version"
plot.axis.x.breaks <- c("Baseline", "Task")

# Y Axis
plot.axis.y.title <- "Energy (uJ)"

# Data Labels
plot.data.labels.digits <- 0

plot.df <- energy.usage.df
plot.axis.y.limits <- c(0, 6)

plot <- plot.bars(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	title = plot.title,
	subtitle = plot.subtitle,
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

plot.save(
	plot = plot,
	width = 3,
	height = 5.0,
	directory = outdir,
	filename  = paste(
		experiment.name,
		"energy",
		sep = "-"
	)
)

