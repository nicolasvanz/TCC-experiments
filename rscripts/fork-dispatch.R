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
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")
source(file = "rscripts/power.R")

#===============================================================================
# Experiment Information
#===============================================================================

experiment.name = "fork-join"
experiment.nanvix.version = "900b52c"

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
print(head(experiment.df))

#===============================================================================
# Filter
#===============================================================================

# Separate dataframes
user.df   <- experiment.df %>% filter(core == "u")
kernel.df <- experiment.df %>% filter(core == "k")

variables.id <- c("kernel", "operation", "amount")
variables <- c("cycles")

#===============================================================================
# User
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

# Convert cycles to ms
user.df$cycles <- user.df$cycles/MPPA.FREQ/MILLI

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

user.df.cooked.total <- aggregate(
	x   = user.df.cooked$mean,
	by  = list(user.df.cooked$kernel, user.df.cooked$amount),
	FUN = sum
)

#==============================================================================

user.df.cooked <- user.df.cooked %>%
	mutate(overhead = ifelse(amount == 1, 0, mean - lag(mean)))

user.df.cooked.overhead <- aggregate(
	x   = user.df.cooked$overhead,
	by  = list(user.df.cooked$kernel, user.df.cooked$operation),
	FUN = mean 
)

print("Fork/Dispatch Overhead:")
print(head(user.df.cooked.overhead))

#==============================================================================

user.df.t.wait <- user.df.cooked %>% filter(operation == "j" & kernel == "fork-join")
user.df.d.wait <- user.df.cooked %>% filter(operation == "j" & kernel == "dispatch-wait")

user.df.end <- user.df.t.wait$mean/user.df.d.wait$mean
print(paste("max wait: ", max(user.df.end)))

user.df.join <- user.df.cooked %>% filter(operation == "f" & kernel == "fork-join")
user.df.disp <- user.df.cooked %>% filter(operation == "f" & kernel == "dispatch-wait")

user.df.start <- user.df.join$mean/user.df.disp$mean
print(paste("min start: ", min(user.df.start)))
print(paste("max start: ", max(user.df.start)))

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- user.df.cooked

plot.x      <- "amount"
plot.y      <- "mean"
plot.factor <- "operation"
plot.facet  <- "kernel"

# Titles
plot.title    <- "Latencies of Thread Module and Task Engine Operations"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operations"
plot.legend.labels <- c("Fork/Dispatch", "Join/Wait")

# X Axis
plot.axis.x.title <- "Number of Execution Flows"
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$amount), by = 2)

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 14, by = 2)
plot.axis.y.limits <- c(0, 14)

# Facets
plot.df$kernel <- factor(plot.df$kernel, levels=c("fork-join", "dispatch-wait"))
levels(plot.df$kernel) <- c("Fork-Join", "Dispatch-Wait")

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

if (do_arrange)
{
	plot.time <- plot.stacks(
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
		title = "Latency",
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels
	) + plot.theme.title +
		plot.theme.legend.top.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor +
		plot.theme.facet.x

	force(plot.time)
}

if (FALSE) {

#===============================================================================
# Kernel
#===============================================================================

#===============================================================================
# Pre-Processing
#===============================================================================

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

# Convert cycles to ms
kernel.df.cooked$mean <- user.df.cooked$mean/MPPA.FREQ/MILLI

kernel.df.cooked.total <- aggregate(
	x   = kernel.df.cooked$mean,
	by  = list(kernel.df.cooked$kernel, kernel.df.cooked$amount),
	FUN = sum
)

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- kernel.df.cooked

plot.x      <- "amount"
plot.y      <- "mean"
plot.factor <- "operation"
plot.facet  <- "kernel"

# Titles
plot.title    <- "Latencies of Thread Module and Task Engine Operations"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operations"
plot.legend.labels <- c("Fork/Dispatch", "Join/Wait")

# X Axis
plot.axis.x.title <- "Number of Execution Flows"
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$amount), by = 4)

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 14, by = 2)
plot.axis.y.limits <- c(0, 14)

# Facets
plot.df$kernel <- factor(plot.df$kernel, levels=c("fork-join", "dispatch-wait"))
levels(plot.df$kernel) <- c("Fork-Join", "Dispatch-Wait")

#===============================================================================
# Plot
#===============================================================================

# join then fork
plot <- plot.stacks(
	df = plot.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	position = "stack",
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels
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
	width = 3.5,
	height = 5,
	directory = outdir,
	filename  = paste(experiment.name, "kernel-time", sep = "-")
)

}

#===============================================================================
# Power
#===============================================================================

#===============================================================================
# Input Reading
#===============================================================================

# Experiment File
power.infile <-	paste(
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
	experiment.outfile = power.outfile,
	experiment.iteration = 9
)

#===============================================================================
# Pre-Processing
#===============================================================================

user.df.cooked <- user.df.cooked %>% filter(amount == 21)
user.df.total <- setNames(
	aggregate(
		x   = user.df.cooked$mean,
		by  = list(user.df.cooked$kernel),
		FUN = sum
	),
	c("kernel", "time")
)

power.df <- power.df %>%
	mutate(kernel = ifelse(version == "baseline", "fork-join", "dispatch-wait"))

energy.user.df <- merge(
	user.df.total,
	power.df
)

energy.user.df$energy <- energy.user.df$power*energy.user.df$time

print("Energy efficiency")
print(energy.user.df)
print(filter(energy.user.df, version == "baseline")$energy[1]/filter(energy.user.df, version == "task")$energy[1])

#===============================================================================
# User
#===============================================================================

plot.df <- energy.user.df

plot.x      <- "kernel"
plot.y      <- "energy"
plot.factor <- "kernel"

# Titles
plot.title    <- "Energy of Thread Module and Task Engine Operations"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Execution Flow Mechanism"
plot.legend.labels <- c("Thread", "Task")

# X Axis
plot.axis.x.title <- "Flow type"
plot.df$kernel <- factor(plot.df$kernel, levels=c("fork-join", "dispatch-wait"))
plot.axis.x.breaks <- c("Thread", "Task")

# Y Axis
plot.axis.y.title <- "Energy (uJ)"
plot.axis.y.limits <- c(0, 100)

# Data Labels
plot.data.labels.digits <- 0

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

plot.save(
	plot = plot,
	width = 3.3,
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
		plot.theme.axis.x.30 +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major +
		plot.theme.grid.minor

	force(plot.energy)

	arrange <- grid.arrange(
		plot.time,
		plot.energy,
		nrow = 1,
		widths = c(2,1),
		top = textGrob("Comparation between Thread Module and Task Engine Operations", gp=gpar(fontsize=20,font=8))
	)

	plot.save(
		plot = arrange,
		width = 11,
		height = 5.0,
		directory = outdir,
		filename  = paste(
			experiment.name,
			"all",
			sep = "-"
		)
	)
}
