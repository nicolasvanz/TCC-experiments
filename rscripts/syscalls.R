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
source(file = "rscripts/include/rplots/bars.R")
source(file = "rscripts/include/rplots/lines.R")
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")

#===============================================================================
# Experiment Information
#===============================================================================

experiment.name = "syscalls"
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
# Filter
#===============================================================================

# Convert cycles to ms
experiment.df$cycles <- experiment.df$cycles/experiment.df$noperations
experiment.df$time <- experiment.df$cycles/MPPA.FREQ/MILLI
experiment.df$amount <- experiment.df$nusers
experiment.df <- experiment.df %>%
	mutate(amount = ifelse(ntaskers == 1 & nusers == 0, 0, nusers + ntaskers))

#===============================================================================
# Pre-Processing
#===============================================================================

variables.id <- c("type", "nusers", "ntaskers", "amount")
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

individual.df <- experiment.df.cooked %>% filter((nusers == 0 & ntaskers == 1) | (nusers == 1 & ntaskers == 0))

#==============================================================================
# Plot Configuration
#==============================================================================

plot.df <- individual.df

plot.x = "type"
plot.y = "mean"
plot.factor = "type"

# Titles
plot.title <- "Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

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
plot.axis.y.breaks <- seq(from = 0, to = 0.275, 0.55) # by = 10
plot.axis.y.limits <- c(0, 0.275)

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
	width = 3.5,
	height = 5,
	directory = outdir,
	filename  = paste(
		experiment.name,
		"time",
		sep = "-"
	)
)

if (do_arrange)
{
	plot.individual <- plot.bars(
		df = plot.df,
		var.x = plot.x,
		var.y = plot.y,
		factor = plot.factor,
		title = "Base Time",
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

	force(plot.individual)
}

#==============================================================================
# Plot Configuration
#==============================================================================

types.df <- experiment.df.cooked %>% filter(nusers > 0)
types.df <- types.df %>%
	mutate(type = ifelse(ntaskers == 0, "baseline", type))

plot.df <- types.df

plot.x <- "nusers"
plot.y <- "mean"
plot.factor <- "type"

# Titles
plot.title <- "Response Time of User/Dispatcher Kernel Calls"
plot.subtitle <- paste("Nanvix Version", experiment.nanvix.version, sep = " ")

# Legend
plot.legend.title <- "Execution Flow"
plot.df$type <- factor(plot.df$type, levels=c("baseline", "dispatcher", "user"))
levels(plot.df$type) <- c("Thread Only", "Dispatcher+Threads", "Threads+Dispatcher")
plot.legend.labels <- levels(as.factor(plot.df$type))

# X Axis
plot.axis.x.title <- "Number of User Cores"
plot.axis.x.breaks <- as.numeric(levels(as.factor(plot.df$amount)))
plot.axis.x.breaks <- seq(from = 1, to = max(plot.df$amount), by = 1)
plot.axis.x.minor.breaks <- seq(from = 1, to = max(plot.df$amount))

# Y Axis
plot.axis.y.title <- "Time (ms)"
plot.axis.y.breaks <- seq(from = 0, to = 1.63, by = 0.3) # by = 10
plot.axis.y.limits <- c(0, 1.63)

plot <- plot.linespoint(
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
) + plot.theme.title +
	plot.theme.legend.bottom.right +
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
	directory = outdir,
	filename  = paste(
		experiment.name,
		"time-all",
		sep = "-"
	)
)

#==============================================================================

user <- types.df %>% filter(type == "user")
baseline <- types.df %>% filter(type == "baseline")
dispatcher <- types.df %>% filter(type == "dispatcher")

overhead <- user$mean-baseline$mean

print("User overhead")
print(mean(overhead))

#==============================================================================

if (do_arrange)
{
	plot.time <- plot.linespoint(
		df = plot.df,
		factor = plot.x,
		respvar = plot.y,
		param = plot.factor,
		title = "Response Time",
		legend.title = plot.legend.title,
		legend.labels = plot.legend.labels,
		axis.x.title = plot.axis.x.title,
		axis.x.breaks = plot.axis.x.breaks,
		axis.y.title = plot.axis.y.title,
		axis.y.limits = plot.axis.y.limits,
		axis.y.breaks = plot.axis.y.breaks,
	) + plot.theme.title +
		plot.theme.legend.bottom.right +
		plot.theme.axis.x +
		plot.theme.axis.y +
		plot.theme.grid.wall +
		plot.theme.grid.major

	force(plot.time)

	arrange <- grid.arrange(
		plot.individual,
		plot.time,
		nrow = 1,
		widths = c(1,2),
		top = textGrob("Response Time of User/Dispatcher Kernel Calls", gp=gpar(fontsize=20,font=8))
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
