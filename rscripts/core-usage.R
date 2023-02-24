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
	experiment.infile <- "./results/cooked/microbenchmarks/core-usage.csv"
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
#experiment.df <- experiment.df %>% mutate(dtime = dtime - kerror)

# Separate times
usage.df <- data.frame(
	version           = experiment.df$version,
	user_user         = experiment.df$utime,
	user_idle         = (experiment.df$total - experiment.df$utime),
	kernel_master     = experiment.df$mtime,
	kernel_dispatcher = experiment.df$dtime,
	kernel_idle       = (experiment.df$total - (experiment.df$mtime + experiment.df$dtime))
)

usage.df$user_idle[usage.df$version == "baseline"]   <- usage.df$user_idle[usage.df$version == "baseline"] - usage.df$user_user[usage.df$version == "daemon"]
usage.df$kernel_idle[usage.df$version == "baseline"] <- usage.df$kernel_idle[usage.df$version == "baseline"] - usage.df$user_user[usage.df$version == "daemon"]
usage.df$kernel_idle[usage.df$version == "daemon"]   <- usage.df$kernel_idle[usage.df$version == "daemon"] - usage.df$user_user[usage.df$version == "daemon"]
usage.df$user_user[usage.df$version == "daemon"] <- 0
print(tail(usage.df))

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
plot.legend.labels <- c("Idle", "Daemon with thread", "Daemon with task", "Kernel")
plot.df$flow <- factor(plot.df$flow, levels=c("idle", "user", "dispatcher", "master"))

# X Axis
plot.axis.x.title <- "Experimental Environment"
plot.df$version <- factor(plot.df$version, levels=c("baseline", "daemon"))
levels(plot.df$version) <- c("Baseline", "Full")
plot.axis.x.breaks <- c("Baseline", "Full")
plot.axis.x.labels <- c("Baseline", "Full")

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 0.6, by = 0.1) # by = 10
plot.axis.y.limits <- c(0, 0.6)

# Facets
plot.df$core <- factor(plot.df$core, levels=c("kernel", "user"))
levels(plot.df$core) <- c("Master Core", "Slave Core")

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
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	colour = c("#fddbc7", "#ef8a62", "#67a9cf", "#b2182b")
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
	width = 7.0,
	height = 5.0,
	directory = experiment.outdir,
	filename  = paste(experiment.outfile, "time", sep = "-")
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
	"cooked/microbenchmarks",
	paste(experiment.outfile, "profile.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile <- paste(
	"./results",
	"cooked",
	paste(experiment.outfile, "power.csv", sep = "-"),
	sep = "/"
)

# Generate power table
power.df <- experiment.generate.power.sbac(
	experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
	experiment.name = experiment.outfile,
	experiment.outfile = power.outfile
)

#===============================================================================
# Pre-Processing
#===============================================================================

print(power.df)

usage.df.total <- setNames(
	aggregate(
		x   = usage.df.cooked$mean * MILLI,
		by  = list(usage.df.cooked$version, usage.df.cooked$core),
		FUN = sum
	),
	c("version", "core", "time")
)

energy.usage.df <- merge(
	usage.df.total,
	power.df
)

energy.usage.df$energy <- energy.usage.df$power*energy.usage.df$time/MILLI
energy.usage.df <- energy.usage.df %>% filter(core == "user")

#===============================================================================
# Mean
#===============================================================================

variables.id <- c("version", "core")
variables <- c("energy")

energy.usage.df.melted <- melt(
	data = energy.usage.df,
	id.vars = variables.id,
	measure.vars = variables
)

energy.usage.df.cooked <- ddply(
	energy.usage.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print("Energy Mean and SD")
print(energy.usage.df.cooked)

if (FALSE) {
	energy.usage.df.cooked$min <- energy.usage.df.cooked$mean - energy.usage.df.cooked$sd
	energy.usage.df.cooked$max <- energy.usage.df.cooked$mean + energy.usage.df.cooked$sd

	energy.comp <- filter(energy.usage.df.cooked, version == "baseline")$mean[1]/filter(energy.usage.df.cooked, version == "daemon")$mean[1]
	energy.max  <- filter(energy.usage.df.cooked, version == "baseline")$min[1]/filter(energy.usage.df.cooked, version == "daemon")$min[1]
	energy.min  <- filter(energy.usage.df.cooked, version == "baseline")$max[1]/filter(energy.usage.df.cooked, version == "daemon")$max[1]
	energy.sd   <- max(energy.comp - energy.min, energy.max - energy.comp)
} else {
	energy.comp <- filter(energy.usage.df.cooked, version == "baseline")$mean[1]/filter(energy.usage.df.cooked, version == "daemon")$mean[1]
	energy.sd <- 0
}

print("Energy efficiency")
print(paste(energy.comp, " +-", energy.sd))

#===============================================================================
# Energy Plot
#===============================================================================

energy.usage.df$protocol <- "Heartbeat"
plot.df <- energy.usage.df

plot.x      <- "version"
plot.y      <- "energy"
plot.factor <- "version"
plot.facet  <- "protocol"

# Titles
plot.title    <- NULL#"Energy of Core Usage Benchmark"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Heartbeat Version"
plot.legend.labels <- c("Baseline", "Full")

# X Axis
plot.axis.x.title <- "Environment"
plot.axis.x.breaks <- c("Baseline", "Full")

# Y Axis
plot.axis.y.title <- "Energy (mJ)"

# Data Labels
plot.data.labels.digits <- 1

plot.axis.y.limits <- c(0, 5)
plot.axis.y.breaks <- seq(from = 0, to = 5, by = 1) # by = 10

plot <- plot.bars.facet.colour(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.save(
	plot = plot,
	width = 3.5,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"energy",
		sep = "-"
	)
)


