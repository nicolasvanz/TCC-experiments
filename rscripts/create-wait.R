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

do_arrange <- FALSE
do_gray    <- TRUE #FALSE

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
	experiment.infile <- "./results/cooked/microbenckmarks/create-wait.csv"
	experiment.outdir <- "./results/plots/microbenchmarks"
	experiment.outfile <- "create-wait"
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

user.df.t.wait <- user.df.cooked %>% filter(operation == "j" & kernel == "thread")
user.df.d.wait <- user.df.cooked %>% filter(operation == "j" & kernel == "task")

user.df.end <- user.df.t.wait$mean/user.df.d.wait$mean
print(paste("max wait: ", max(user.df.end)))

user.df.join <- user.df.cooked %>% filter(operation == "f" & kernel == "thread")
user.df.disp <- user.df.cooked %>% filter(operation == "f" & kernel == "task")

user.df.start <- user.df.join$mean/user.df.disp$mean

thread.max <- max(user.df.join$mean)
thread.min <- max(user.df.join$mean)
task.max <- max(user.df.disp$mean)
task.min <- max(user.df.disp$mean)
thread.sd.max <- max(filter(user.df.cooked, kernel == "thread")$sd)
task.sd.max <- max(filter(user.df.cooked, kernel == "task")$sd)

print("Maximum Execution time SD")
print(filter(user.df.cooked, (kernel == "thread" & sd == thread.sd.max) | (kernel == "task" & sd == task.sd.max)))

user.df.join.min <- user.df.join
user.df.disp.min <- user.df.disp
user.df.join.min$mean <- user.df.join$mean - user.df.join$sd
user.df.disp.min$mean <- user.df.disp$mean - user.df.disp$sd
user.df.start.min <- user.df.join.min$mean/user.df.disp.min$mean
user.df.join.max <- user.df.join
user.df.disp.max <- user.df.disp
user.df.join.max$mean <- user.df.join$mean + user.df.join$sd
user.df.disp.max$mean <- user.df.disp$mean + user.df.disp$sd
user.df.start.max <- user.df.join.max$mean/user.df.disp.max$mean

print("Execution time SD")
print(paste("One flow:", min(user.df.start), " +-", max(min(user.df.start) - min(user.df.start.min), min(user.df.start.max) - min(user.df.start))))
print(paste("One flow:", max(user.df.start), " +-", max(max(user.df.start) - max(user.df.start.max), max(user.df.start.min) - max(user.df.start))))

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- user.df.cooked

plot.x      <- "amount"
plot.y      <- "mean"
plot.factor <- "operation"
plot.facet  <- "kernel"

# Titles
plot.title    <- NULL#"Latencies of Thread Module and Task Engine Operations"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operations"
plot.legend.labels <- c("Fork/Dispatch", "Join/Wait")

# X Axis
plot.axis.x.title <- "Number of Execution Flows"
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$amount), by = 2)
plot.axis.x.labels <- as.factor(seq(from = 1, to = max(plot.df$amount), by = 2))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 14, by = 1)
plot.axis.y.limits <- c(0, 14)

# Facets
plot.df$kernel <- factor(plot.df$kernel, levels=c("thread", "task"))
levels(plot.df$kernel) <- c("Threads", "Tasks")

#===============================================================================
# Plot
#===============================================================================

# Facets
levels(plot.df$kernel) <- c("thread", "task")

plot.colours <- split(plot.df, f = plot.df$kernel)

plot.thread.df <- plot.colours$thread
plot.thread.legend.labels <- c("Fork", "Join")

plot.task.df <- plot.colours$task
plot.task.legend.labels <- c("Dispatch", "Wait")

levels(plot.thread.df$kernel) <- c("Spawning/Waiting Threads", "Spawning/Waiting Tasks")
levels(plot.task.df$kernel)   <- c("Spawning/Waiting Threads", "Spawning/Waiting Tasks")

plot.thread <- plot.stacks.colour(
	df = plot.thread.df,
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
	legend.labels = plot.thread.legend.labels,
	colour = c("#fddbc7", "#ca0020")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot.task <- plot.stacks.colour(
	df = plot.task.df,
	var.x = plot.x,
	var.y = plot.y,
	factor = plot.factor,
	facet = plot.facet,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.labels = plot.axis.x.labels,
	axis.y.title = " ",
	axis.y.breaks = plot.axis.y.breaks,
	axis.y.limits = plot.axis.y.limits,
	legend.title = plot.legend.title,
	legend.labels = plot.task.legend.labels,
	colour = c("#92c5de", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor +
	plot.theme.facet.x

plot <- grid.arrange(plot.thread, plot.task, nrow = 1)

plot.save(
	plot = plot,
	height = 5,
	width = 9,
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
power.infile <-	paste(
	"./results",
	"cooked/microbenchmarks",
	paste(experiment.outfile, "profile.csv", sep = "-"),
	sep = "/"
)

# Experiment File
power.outfile <- paste(
	"./results",
	"cooked/microbenchmarks",
	paste(experiment.outfile, "power.csv", sep = "-"),
	sep = "/"
)

# Generate power table
power.df <- experiment.generate.power.sbac(
	experiment.df = read.delim(file = power.infile, sep = ";", header = TRUE),
	experiment.name = experiment.outfile,
	experiment.version.baseline = "thread",
	experiment.version.nanvix = "task",
	experiment.outfile = power.outfile,
	experiment.iteration = 9
)

#===============================================================================
# Pre-Processing
#===============================================================================

user.df.cooked <- user.df.cooked %>% filter(amount == 21)
user.df.total <- setNames(
	aggregate(
		x   = user.df.cooked$mean * MILLI,
		by  = list(user.df.cooked$kernel),
		FUN = sum
	),
	c("version", "time")
)

power.df <- power.df %>%
	mutate(kernel = ifelse(version == "thread", "fork-join", "dispatch-wait"))

energy.user.df <- merge(
	user.df.total,
	power.df
)

energy.user.df$energy <- energy.user.df$power*energy.user.df$time/MILLI
energy.user.df$flow   <- "21 Flows"

#===============================================================================
# Mean
#===============================================================================

variables.id <- c("kernel", "flow")
variables <- c("energy")

energy.user.df.melted <- melt(
	data = energy.user.df,
	id.vars = variables.id,
	measure.vars = variables
)

energy.user.df.cooked <- ddply(
	energy.user.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print("Energy Mean and SD")
print(energy.user.df.cooked)

energy.user.df.cooked$min <- energy.user.df.cooked$mean - energy.user.df.cooked$sd
energy.user.df.cooked$max <- energy.user.df.cooked$mean + energy.user.df.cooked$sd

energy.comp <- filter(energy.user.df.cooked, kernel == "fork-join")$mean[1]/filter(energy.user.df.cooked, kernel == "dispatch-wait")$mean[1]
energy.max  <- filter(energy.user.df.cooked, kernel == "fork-join")$min[1]/filter(energy.user.df.cooked, kernel == "dispatch-wait")$min[1]
energy.min  <- filter(energy.user.df.cooked, kernel == "fork-join")$max[1]/filter(energy.user.df.cooked, kernel == "dispatch-wait")$max[1]
energy.sd   <- max(energy.comp - energy.min, energy.max - energy.comp)

print("Energy efficiency")
print(paste(energy.comp, " +-", energy.sd))

#===============================================================================
# User
#===============================================================================

plot.df <- energy.user.df.cooked

plot.x      <- "kernel"
plot.y      <- "mean"
plot.factor <- "kernel"
plot.facet  <- "flow"

# Titles
plot.title    <- NULL#"Energy of Thread Module and Task Engine Operations"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Execution Flow Mechanism"
plot.legend.labels <- c("Thread", "Task")

# X Axis
plot.axis.x.title <- "Flow type"
plot.df$kernel <- factor(plot.df$kernel, levels=c("fork-join", "dispatch-wait"))
plot.axis.x.breaks <- c("Thread", "Task")

# Y Axis
plot.axis.y.title <- "Energy (mJ)"
plot.axis.y.limits <- c(0, 95)
plot.axis.y.breaks <- seq(from = 0, to = 100, by = 10) # by = 10

# Data Labels
plot.data.labels.digits <- 0

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
	width = 3,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"energy",
		sep = "-"
	)
)

