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

# My Utilities
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
	experiment.infile <- "./results/cooked/microbenchmarks/syscalls.csv"
	experiment.outdir <- "./results/plots/microbenchmarks"
	experiment.outfile <- "syscalls"
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

# Convert cycles to ms
experiment.df$cycles <- experiment.df$cycles/experiment.df$noperations
experiment.df$time <- experiment.df$cycles/MPPA.FREQ/MILLI
experiment.df$amount <- experiment.df$nusers
experiment.df <- experiment.df %>%
	mutate(amount = ifelse(ndispatchers == 1 & nusers == 0, 0, nusers + ndispatchers))

#===============================================================================
# Pre-Processing
#===============================================================================

variables.id <- c("type", "nusers", "ndispatchers", "amount")
variables <- c("time")

experiment.df.melted <- melt(
	data = experiment.df,
	id.vars = variables.id,
	measure.vars = variables
)

experiment.df.cooked <- ddply(
	experiment.df.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

individual.df <- experiment.df.cooked %>% filter((nusers == 0 & ndispatchers == 1) | (nusers == 1 & ndispatchers == 0))

#==============================================================================
# Statistics
#==============================================================================

individual.df$min <- individual.df$mean - individual.df$sd
individual.df$max <- individual.df$mean - individual.df$sd

ind.comp <- individual.df$mean[individual.df$nusers == 1] / individual.df$mean[individual.df$nusers == 0]
ind.max  <- individual.df$min[individual.df$nusers == 1] / individual.df$min[individual.df$nusers == 0] - ind.comp
ind.min  <- ind.comp - individual.df$max[individual.df$nusers == 1] / individual.df$max[individual.df$nusers == 0]

print("Comparing")
print(paste(ind.comp, " +-", max(ind.max, ind.min)))

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- individual.df

plot.x = "type"
plot.y = "mean"
plot.factor = "type"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- ""
plot.legend.labels <- ""

# X Axis
plot.axis.x.title <- "Flow type"
plot.df$type <- factor(plot.df$type, levels=c("user", "dispatcher"))
levels(plot.df$type) <- c("Thread", "Task")
plot.axis.x.breaks <- levels(as.factor(plot.df$type))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 0.25, by = 0.05) # by = 10
plot.axis.y.limits <- c(0, 0.275)

# Data Labels
plot.data.labels.digits <- 2

#===============================================================================
# Plot
#===============================================================================

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
	axis.y.breaks = plot.axis.y.breaks,
	data.labels.digits = plot.data.labels.digits,
	colour = c("#ca0020", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.none +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major +
	plot.theme.grid.minor

plot.save(
	plot = plot,
	width = 3.5,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"time",
		sep = "-"
	)
)

#==============================================================================
# Plot Configuration
#==============================================================================

types.df <- experiment.df.cooked %>% filter(nusers > 0)
types.df <- types.df %>%
	mutate(type = ifelse(ndispatchers == 0, "baseline", type))

plot.df <- types.df

plot.x      <- "nusers"
plot.y      <- "mean"
plot.factor <- "type"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Execution Flow"
plot.df$type <- factor(plot.df$type, levels=c("baseline", "user", "dispatcher"))
levels(plot.df$type) <- c("Threads Only", "Threads+Dispatcher", "Dispatcher+Threads")
plot.legend.labels <- levels(as.factor(plot.df$type))

# X Axis
plot.axis.x.title <- "Number of User Cores"
plot.axis.x.breaks <- as.numeric(levels(as.factor(plot.df$amount)))
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$amount), by = 1)
plot.axis.x.minor.breaks <- seq(from = 1, to = max(plot.df$amount))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 2.5, by = 0.25) # by = 10
plot.axis.y.limits <- c(0, 2.5)

plot <- plot.linespoint.colour(
	df = plot.df,
	factor = plot.x,
	respvar = plot.y,
	param = plot.factor,
	legend.title = plot.legend.title,
	legend.labels = plot.legend.labels,
	axis.x.title = plot.axis.x.title,
	axis.x.breaks = plot.axis.x.breaks,
	axis.x.minor.breaks = plot.axis.x.minor.breaks,
	axis.y.title = plot.axis.y.title,
	axis.y.limits = plot.axis.y.limits,
	axis.y.breaks = plot.axis.y.breaks,
	colour = c("#ca0020", "#fddbc7", "#0571b0")
) + plot.theme.title +
	plot.theme.legend.top.left +
	plot.theme.axis.x +
	plot.theme.axis.y +
	plot.theme.grid.wall +
	plot.theme.grid.major

#axis.y.trans = "log10",
#axis.y.trans.format = math_format(expr = 10^.x)

plot.save(
	plot = plot,
	width = 8,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"time-all",
		sep = "-"
	)
)

#==============================================================================

user       <- types.df %>% filter(type == "user")
baseline   <- types.df %>% filter(type == "baseline")
dispatcher <- types.df %>% filter(type == "dispatcher")

overhead <- data.frame(diff = user$mean-baseline$mean)
overhead$test <- "test"

variables.id <- c("test")
variables    <- c("diff")

overhead.melted <- melt(
	data = overhead,
	id.vars = variables.id,
	measure.vars = variables
)

overhead.cooked <- ddply(
	overhead.melted,
	c(variables.id, "variable"),
	summarise,
	mean = mean(value),
	sd = sd(value),
	cv = sd(value)/mean(value)
)

print("User overhead")
print(overhead.cooked)
