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

do_arrange <- TRUE

# R Libraries
library(plyr)
library(ggplot2)
library(reshape2)
library(scales)
library(dplyr, warn.conflicts = FALSE)
if (do_arrange)
{
	library(grid, warn.conflicts = FALSE)
	library(gridExtra, warn.conflicts = FALSE)
	#library(ggpubr)
}

# My Utilities
source(file = "rscripts/include/rplots/utils.R")
source(file = "rscripts/include/rplots/theme.R")
source(file = "rscripts/include/rplots/stacks.R")
source(file = "rscripts/include/rplots/bars.R")
source(file = "rscripts/include/rplots/lines.R")
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Experiment Information
#===============================================================================

experiment.name = "noise"
experiment.nanvix.version = "123456"

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
		paste(experiment.name, "csv", sep = "."),
		sep = "/"
	)
)

# Output Directory
outdir <- ifelse(
	length(args) >= 2,
	args[2],
	getwd()
)

experiment.df <- read.table(file = experiment.file, sep = ";", header = TRUE)

#===============================================================================
# Filter
#===============================================================================

# Separate dataframes
kernel.df <- experiment.df %>% filter(type == "k")

# Convert cycles to ms
kernel.df$cycles <- kernel.df$cycles/MPPA.FREQ/MILLI

#===============================================================================
# User
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

variables.id <- c("version", "operation", "amount")
variables <- c("cycles")

user.df.melted <- melt(
	data = user.df,
	id.vars = variables.id,
	measure.vars = variables
)

user.df.cooked <- ddply(
	user.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

kernel.df.melted <- melt(
	data = kernel.df,
	id.vars = variables.id,
	measure.vars = variables
)

kernel.df.cooked <- ddply(
	kernel.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

variables.all.id <- c("version")
variables.all    <- c("dtlb", "itlb", "reg", "branch", "dcache", "icache")

user.all.df.melted <- melt(
	data = user.df,
	id.vars = variables.all.id,
	measure.vars = variables.all
)

user.all.df.cooked <- ddply(
	user.all.df.melted,
	c(variables.all.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

kernel.all.df.melted <- melt(
	data = kernel.df,
	id.vars = variables.all.id,
	measure.vars = variables.all
)

kernel.all.df.cooked <- ddply(
	kernel.all.df.melted,
	c(variables.all.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

#==============================================================================
# Plots
#==============================================================================

for (curr.name in c("kernel")) # "user"
{
	if(curr.name == "user") {
		curr.df     <- user.df.cooked
		curr.all.df <- user.all.df.cooked
		curr.limit  <- 50
		curr.length <- 6
	}
	else {
		curr.df     <- kernel.df.cooked
		curr.all.df <- kernel.all.df.cooked
		curr.limit  <- 14
		curr.length <- 5
	}

	#==============================================================================
	# Plot Configuration (Version has facet)
	#==============================================================================

	print(paste("[", curr.name, "][time][stacks]", sep = ""))

	plot.df <- curr.df

	plot.x      <- "amount"
	plot.y      <- "mean"
	plot.factor <- "operation"
	plot.facet  <- "version"

	# Titles
	plot.title    <- NULL # "Latencies of Thread Module and Task Engine Operations"
	plot.subtitle <- NULL # paste("Nanvix Version", experiment.nanvix.version, sep = " ")

	# Legend
	plot.legend.title <- "Operation"
	plot.legend.labels <- c("Fork", "Join")

	# X Axis
	plot.axis.x.title <- "Number of Threads"
	plot.axis.x.breaks <- as.factor(seq(from = 1, to = max(plot.df$amount), by = 2))

	# Y Axis
	plot.axis.y.title <- "Time (ms)"
	plot.axis.y.breaks <- seq(from = 0, to = curr.limit, length.out = curr.length)
	plot.axis.y.limits <- c(0, curr.limit)

	# Facets names
	plot.df$version <- factor(plot.df$version, levels=c("old", "new"))
	levels(plot.df$version) <- c("Without UArea (Original)", "With UArea")

	# Factor names
	plot.df$operation <- factor(plot.df$operation, levels=c("f", "j"))
	levels(plot.df$operation) <- c("Fork", "Join")

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
		plot.theme.legend.top.left +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor +
		plot.theme.facet.x

	plot.save(
		plot = plot,
		width = 8,
		height = 5,
		directory = outdir,
		filename  = paste(experiment.name, curr.name, "time-stack", sep = "-")
	)

	#==============================================================================
	# Plot Configuration (Operation has facet)
	#==============================================================================

	print(paste("[", curr.name, "][time][bars]", sep = ""))

	plot.df <- curr.df

	plot.x      <- "amount"
	plot.y      <- "mean"
	plot.factor <- "version"
	plot.facet  <- "operation"

	# Titles
	plot.title    <- NULL # "Latencies of Thread Module and Task Engine Operations"
	plot.subtitle <- NULL # paste("Nanvix Version", experiment.nanvix.version, sep = " ")

	# Legend
	plot.legend.title <- "Version"
	plot.legend.labels <- c("Without UArea (Original)", "With UArea")

	# X Axis
	plot.axis.x.title <- "Number of Threads"
	plot.axis.x.breaks <- as.factor(seq(from = 1, to = max(plot.df$amount), by = 2))

	# Y Axis
	plot.axis.y.title <- "Time (ms)" # µs
	plot.axis.y.breaks <- seq(from = 0, to = curr.limit, length.out = curr.length)
	plot.axis.y.limits <- c(0, curr.limit)

	# Facets names
	plot.df$version <- factor(plot.df$version, levels=c("old", "new"))
	levels(plot.df$version) <- c("Without UArea (Original)", "With UArea")

	# Factor names
	plot.df$operation <- factor(plot.df$operation, levels=c("f", "j"))
	levels(plot.df$operation) <- c("Fork", "Join")

	#===============================================================================
	# Plot
	#===============================================================================

	plot <- plot.bars.facet(
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
		data.labels.digits = 0
	) + plot.theme.title +
		plot.theme.legend.top.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor +
		plot.theme.facet.x

	plot.save(
		plot = plot,
		width = 8,
		height = 5,
		directory = outdir,
		filename  = paste(experiment.name, curr.name, "time-bars", sep = "-")
	)

	#===============================================================================
	# All colunms
	#===============================================================================

	print(paste("[", curr.name, "][all][bars]", sep = ""))

	plot.df <- curr.all.df

	plot.x      <- "variable"
	plot.y      <- "mean"
	plot.factor <- "version"

	# Titles
	plot.title    <- NULL # "Latencies of Thread Module and Task Engine Operations"
	plot.subtitle <- NULL # paste("Nanvix Version", experiment.nanvix.version, sep = " ")

	# Legend
	plot.legend.title <- "Version"
	plot.legend.labels <- c("Without UArea (Original)", "With UArea")

	# X Axis
	plot.axis.x.title <- "Number of Threads"
	plot.axis.x.breaks <- as.factor(unique(plot.df$variable))

	# Y Axis
	plot.axis.y.title <- "Number of Occurrences"
	plot.axis.y.breaks <- seq(from = 0, to = 260000, length.out = curr.length)
	plot.axis.y.limits <- c(0, 260000)

	plot.df$version <- factor(plot.df$version, levels=c("old", "new"))
	levels(plot.df$version) <- c("Without UArea (Original)", "With UArea")

	#===============================================================================
	# Plot
	#===============================================================================

	plot <- plot.bars(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.breaks = plot.axis.y.breaks,
		axis.y.limits = plot.axis.y.limits,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		data.labels.digits = 0
	) + plot.theme.title +
		plot.theme.legend.top.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor +
		plot.theme.facet.x

	plot.save(
		plot = plot,
		width = 10,
		height = 5,
		directory = outdir,
		filename  = paste(experiment.name, curr.name, "counters", sep = "-")
	)
}

