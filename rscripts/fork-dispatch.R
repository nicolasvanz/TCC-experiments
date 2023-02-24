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
	experiment.infile <- "./results/cooked/fork-dispatch/fork-dispatch.csv"
	experiment.outdir <- "./results/plots/microbenchmarks"
	experiment.outfile <- "fork-dispatch"
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

user.df.t.wait <- user.df.cooked %>% filter(operation == "j" & kernel == "thread")
user.df.d.wait <- user.df.cooked %>% filter(operation == "j" & kernel == "task")

user.df.end <- user.df.t.wait$mean/user.df.d.wait$mean
print(paste("max wait: ", max(user.df.end)))

user.df.join <- user.df.cooked %>% filter(operation == "f" & kernel == "thread")
user.df.disp <- user.df.cooked %>% filter(operation == "f" & kernel == "task")

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
plot.title    <- NULL#"Latencies of Thread Module and Task Engine Operations"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Operations"
plot.legend.labels <- c("Fork/Dispatch", "Join/Wait")

# X Axis
plot.axis.x.title <- "Number of Execution Flows"
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$amount), by = 2)
plot.axis.x.labels <- as.factor(seq(from = 1, to = max(plot.df$amount), by = 2))
print(plot.axis.x.labels)

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 14, by = 2)
plot.axis.y.limits <- c(0, 14)

# Facets
plot.df$kernel <- factor(plot.df$kernel, levels=c("thread", "task"))
levels(plot.df$kernel) <- c("Threads", "Tasks")

#===============================================================================
# Plot
#===============================================================================

# Facets
levels(plot.df$kernel) <- c("thread", "task")

print(head(plot.df))
plot.colours <- split(plot.df, f = plot.df$kernel)
print(head(plot.colours))

plot.thread.df <- plot.colours$thread
plot.thread.legend.labels <- c("Fork", "Join")

plot.task.df <- plot.colours$task
plot.task.legend.labels <- c("Dispatch", "Wait")

print(levels(plot.thread.df$kernel))

levels(plot.thread.df$kernel) <- c("Spawning Threads", "Spawning Tasks")
levels(plot.task.df$kernel)   <- c("Spawning Threads", "Spawning Tasks")

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
	legend.labels = plot.thread.legend.labels
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
	palette_colour = c("#deebf7", "#3182bd")
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
	width = 12,
	directory = experiment.outdir,
	filename  = paste(experiment.outfile, "user-time", sep = "-")
)

