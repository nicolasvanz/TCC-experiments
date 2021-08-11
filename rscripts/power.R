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
library(stringr)

# My Utilities
source(file = "rscripts/include/utils.R")
source(file = "rscripts/include/consts.R")

#===============================================================================
# Spline
#===============================================================================

smooth.spline.integrate <- function(model, x0, xN, length = 100) {
	area <- 0
	
	for (x in seq(from = x0, to = xN, length.out = length)) {
		area <- area + predict(model, x)$y
	}

	return (area/length)
}

#===============================================================================
# Create power table
#===============================================================================

experiment.generate.power <- function(
	experiment.df,
	experiment.name,
	experiment.outfile,
	experiment.version.baseline = "baseline",
	experiment.version.nanvix   = "task",
	experiment.iteration = 0,
	experiment.force.generation = TRUE 
)
{
	if (file.exists(experiment.outfile) & !experiment.force.generation)
		return (read.delim(file = experiment.outfile, sep = ";", header = TRUE))

	#===============================================================================
	# Pre-Processing
	#===============================================================================

	experiment.df.mppa <- filter(experiment.df, component == "power" & it == experiment.iteration)
	experiment.df.ddr0 <- filter(experiment.df, component == "ddr0"  & it == experiment.iteration)
	experiment.df.ddr1 <- filter(experiment.df, component == "ddr1"  & it == experiment.iteration)

	# Baseline
	baseline.df <- filter(experiment.df.mppa, version == experiment.version.baseline)
	baseline.x.max <- as.numeric(range(experiment.df.mppa$time)[2])
	baseline.fit <- smooth.spline(baseline.df$time, baseline.df$power)
	t0 = baseline.x.max - 1
	tN = baseline.x.max
	baseline.power.avg <- smooth.spline.integrate(
		model = baseline.fit,
		x0 = t0,
		xN = tN
	)/(tN - t0)

	# Nanvix
	nanvix.df <- filter(experiment.df.mppa, version == experiment.version.nanvix)
	nanvix.x.max <- as.numeric(range(experiment.df.mppa$time)[2])
	nanvix.fit <- smooth.spline(nanvix.df$time, nanvix.df$power)
	t0 = nanvix.x.max - 1
	tN = nanvix.x.max
	nanvix.power.avg <- smooth.spline.integrate(
		model = nanvix.fit,
		x0 = t0,
		xN = tN
	)/(tN - t0)

	power.df <- data.frame(
		version = c(experiment.version.baseline, experiment.version.nanvix),
		kernel  = c(experiment.name, experiment.name),
		power   = c(baseline.power.avg, nanvix.power.avg)
	)

	write.table(
		x = power.df,
		file = experiment.outfile,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	return(power.df)

	if (FALSE)
	{
		#===============================================================================
		# Plot
		#===============================================================================

		plot <- ggplot(
				data = experiment.df.mppa,
				aes(x = time, y = power, color = ikc.solution),
			) +
			labs(
				title = element_blank(),
				x = "Time (s)",
				y = " Power (W)",
				color = "IKC Solution" 
			) +
			geom_point()+
			scale_x_continuous(
				expand = c(0, 0),
				limits = c(0, 130),
				breaks = breaks_pretty()
			) +
			scale_y_continuous(
				expand = c(0, 0),
				limits = c(0, 8),
				breaks = breaks_pretty()
			) +
			scale_color_grey(
				labels = c("Baseline", "Nanvix")
			) +
			geom_vline(xintercept = 65) +
			geom_text(aes(x = 65, label="OS Startup", y = 5),  angle=90, vjust = -1.0) +
			geom_vline(xintercept = 118) +
			geom_text(aes(x = 118, label="OS Shutdown", y = 5),  angle=90, vjust = -1.0) +
			theme_classic() +
			plot.theme.title +
			plot.theme.legend.top.left +
			plot.theme.axis.x +
			plot.theme.axis.y +
			plot.theme.grid.wall +
			plot.theme.grid.major +
			plot.theme.grid.minor

		plot.save(
			plot = plot,
			width = 12.0,
			height = 5.0,
			directory = ".",
			filename  = paste(
				experiment.name,
				experiment.metric,
				sep = "-"
			)
		)
	}
}
