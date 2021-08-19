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

experiment.name = "fork-join"
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
	length(args) >= 3,
	args[2],
	getwd()
)

experiment.df <- read.table(file = experiment.file, sep = ";", header = TRUE)

#===============================================================================
# Filter
#===============================================================================

# Separate dataframes
user.df   <- experiment.df %>% filter(type == "u")
kernel.df <- experiment.df %>% filter(type == "k")

variables.id <- c("version", "operation", "amount")
variables <- c("cycles")

#===============================================================================
# User
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

# Convert cycles to ms
user.df$cycles <- user.df$cycles/MPPA.FREQ/MICRO

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

# Convert cycles to ms
kernel.df$cycles <- kernel.df$cycles/MPPA.FREQ/MICRO

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

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- user.df.cooked

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
plot.axis.x.breaks <- as.factor(seq(from = 1, to = max(plot.df$amount), by = 1))

# Y Axis
plot.axis.y.title <- "Time (µs)"
plot.axis.y.breaks <- seq(from = 0, to = 4000, by = 1000)
plot.axis.y.limits <- c(0, 4000)

# Facets
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
	filename  = paste(experiment.name, "user-time", sep = "-")
)


#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- kernel.df.cooked

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
plot.axis.x.breaks <- as.factor(seq(from = 1, to = max(plot.df$amount), by = 1))

# Y Axis
plot.axis.y.title <- "Time (µs)"
plot.axis.y.breaks <- seq(from = 0, to = 4000, by = 1000)
plot.axis.y.limits <- c(0, 4000)

# Facets
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
	filename  = paste(experiment.name, "kernel-time", sep = "-")
)

#===============================================================================
# All colunms
#===============================================================================

#===============================================================================
# Filter
#===============================================================================

print(head(experiment.df))

# Separate dataframes
all.df   <- experiment.df %>% filter(amount == max(experiment.df$amount))

variables.id <- c("version", "type")
variables <- c("dtlb", "itlb", "reg", "branch", "dcache", "icache")

#===============================================================================
# User
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

all.df.melted <- melt(
	data = all.df,
	id.vars = variables.id,
	measure.vars = variables
)

all.df.cooked <- ddply(
	all.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- all.df.cooked

print(plot.df)

plot.x      <- "variable"
plot.y      <- "mean"
plot.factor <- "version"
plot.facet  <- "type"

# Titles
plot.title    <- NULL # "Latencies of Thread Module and Task Engine Operations"
plot.subtitle <- NULL # paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Version"
plot.legend.labels <- c("Without UArea (Original)", "With UArea")

# X Axis
plot.axis.x.title <- "Number of Threads"
plot.axis.x.breaks <- as.factor(unique(all.df.cooked$variable))

# Y Axis
plot.axis.y.title <- "Number of *"
plot.axis.y.breaks <- seq(from = 0, to = max(all.df.cooked$mean), by = 100000)
plot.axis.y.limits <- c(0, max(all.df.cooked$mean) + 10000)

# Facets
plot.df$type <- factor(plot.df$type, levels=c("k", "u"))
levels(plot.df$type) <- c("Kernel", "User")

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
	width = 10,
	height = 5,
	directory = outdir,
	filename  = paste(experiment.name, "counters", sep = "-")
)

#===============================================================================
# Power
#===============================================================================

for (it in 0:9)
{
	#===============================================================================
	# Input Reading
	#===============================================================================

	# Experiment File
	power.infile <-	paste(
		"./results",
		"cooked",
		paste(experiment.name, "profile.csv", sep = "-"),
		sep = "/"
	)

	# Experiment File
	power.outfile.total <- paste(
		"./results",
		"cooked",
		paste(experiment.name, it, "power-total.csv", sep = "-"),
		sep = "/"
	)

	# Experiment File
	power.outfile.predict <- paste(
		"./results",
		"cooked",
		paste(experiment.name, it, "power-predict.csv", sep = "-"),
		sep = "/"
	)

	# Experiment File
	power.outfile.means <- paste(
		"./results",
		"cooked",
		paste(experiment.name, it, "power-means.csv", sep = "-"),
		sep = "/"
	)

	#===============================================================================
	# Total
	#===============================================================================

	print(paste("Ploting Total Consumption", it, sep = " "))

	# Generate power table
	power.df <- experiment.generate.power(
		experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
		experiment.name = experiment.name,
		experiment.outfile.total = power.outfile.total,
		experiment.outfile.predict = power.outfile.predict,
		experiment.outfile.means = power.outfile.means,
		experiment.versions = c("new", "old"),
		experiment.iteration = it,
		experiment.return = "total"
	)

	print(power.df)

	#===============================================================================
	# Predict
	#===============================================================================

	print(paste("Ploting Predict Consumption", it, sep = " "))

	predict.df <- experiment.generate.power(
		experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
		experiment.name = experiment.name,
		experiment.outfile.total = power.outfile.total,
		experiment.outfile.predict = power.outfile.predict,
		experiment.outfile.means = power.outfile.means,
		experiment.versions = c("new", "old"),
		experiment.iteration = it,
		experiment.return = "predict",
		experiment.force.generation = FALSE
	)

	plot.df    <- predict.df

	plot.var.x  <- "time"
	plot.var.y  <- "power"
	plot.factor <- "version"
	plot.facet  <- "nprocs"

	# Titles
	plot.title    <- NULL
	plot.subtitle <- NULL

	# Legend
	plot.legend.title  <- "API Solution"
	plot.legend.labels <- c("Nanvix IPC", "LWMPI-unopt", "LWMPI-opt")

	# X Axis
	plot.axis.x.title  <- "Time (s)"
	plot.axis.x.breaks <- seq(from = 0, to = 1000, length.out = 9)

	# Y Axis
	plot.axis.y.title <- "Power (W)"
	plot.axis.y.limits <- c(7.25, 8.75)
	plot.axis.y.breaks <- seq(from = 7.25, to = 8.75, length.out = 7)

	# Facets
	plot.df$nprocs <- factor(plot.df$nprocs, levels=c(12, 48, 192))
	levels(plot.df$nprocs) <- c("1 Cluster (12 MPI Processes)", "4 Clusters (48 MPI Processes)", "16 Clusters (192 MPI Processes)")

	plot <- plot.lines.facet2(
		df = plot.df,
		factor = plot.var.x,
		respvar = plot.var.y,
		param = plot.factor,
		facet = plot.facet,
		title = plot.title,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.breaks = plot.axis.y.breaks,
		axis.y.limits = plot.axis.y.limits
	) + plot.theme.title +
		plot.theme.legend.bottom.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.facet.x

	plot.save(
		plot = plot,
		width = 15,
		directory = outdir,
		filename  = paste(
			experiment.name,
			"energy-predict",
			it,
			sep = "-"
		)
	)

	#===============================================================================
	# Predict
	#===============================================================================

	print(paste("Ploting Mean Consumption", it, sep = " "))

	means.df <- experiment.generate.power(
		experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
		experiment.name = experiment.name,
		experiment.outfile.total = power.outfile.total,
		experiment.outfile.predict = power.outfile.predict,
		experiment.outfile.means = power.outfile.means,
		experiment.versions = c("new", "old"),
		experiment.iteration = it,
		experiment.return = "means",
		experiment.force.generation = FALSE
	)

	plot.df <- means.df

	plot.var.x  <- "time"
	plot.var.y  <- "power"
	plot.factor <- "version"
	plot.facet  <- "nprocs"

	# Titles
	plot.title    <- NULL
	plot.subtitle <- NULL

	# Legend
	plot.legend.title  <- "API Solution"
	plot.legend.labels <- c("Nanvix IPC", "LWMPI-unopt", "LWMPI-opt")

	# X Axis
	plot.axis.x.title  <- "Interval (200 dots per mean)"
	plot.axis.x.breaks <- seq(from = 0, to = max(means.df$group), length.out = 10)

	plot.axis.y.title <- "Power (W)"

	plot <- plot.lines.facet(
		df = plot.df,
		factor = plot.var.x,
		respvar = plot.var.y,
		param = plot.factor,
		facet = plot.facet,
		title = plot.title,
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title
	) + plot.theme.title +
		plot.theme.legend.top.left +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major

	plot.save(
		plot = plot,
		width = 15,
		height = 6,
		directory = utdir,
		filename  = paste(
			experiment.name,
			"energy-means",
			it,
			sep = "-"
		)
	)
}

