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
	experiment.infile <- "./results/cooked/services/pgfetch.csv"
	experiment.outdir <- "./results/plots/services"
	experiment.outfile <- "pgfetch"
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
experiment.df$time <- experiment.df$time/MPPA.FREQ/MILLI
experiment.df <- experiment.df %>% filter(nprocs == 1)

#===============================================================================
# Pre-Processing
#===============================================================================

variables.id <- c("version", "nprocs")
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

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- experiment.df.cooked

plot.x = "version"
plot.y = "mean"
plot.factor = "version"

# Titles
plot.title <- NULL#"Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- NULL#paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- NULL#"Version"
plot.legend.labels <- NULL#levels(as.factor(plot.df$version))

# X Axis
plot.axis.x.title <- "Number of Processes (Compute Clusters)"
plot.axis.x.breaks <- levels(as.factor(plot.df$version))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 1.4, by = 0.2) # by = 10
plot.axis.y.limits <- c(0, 1.5)

# Data Labels
plot.data.labels.digits <- 2

#===============================================================================
# Plot
#===============================================================================

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
	width = 7,
	height = 5,
	directory = experiment.outdir,
	filename  = paste(
		experiment.outfile,
		"time",
		sep = "-"
	)
)

