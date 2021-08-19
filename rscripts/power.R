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
library(mgcv)

# My Utilities
source(file = "rscripts/include/rplots/utils.R")
source(file = "rscripts/include/consts.R")

#===============================================================================
# Spline
#===============================================================================

# We use Left Riemann Sum -> https://en.wikipedia.org/wiki/Riemann_sum
smooth.spline.integrate <- function(model, a, b, n = 1000)
{
	h    <- (b - a) / n
	area <- 0

	for (x in seq(from = a, to = b, length.out = n))
		area <- area + (predict(model, x)$y * h)

	return (area)
}

#===============================================================================
# GAM
#===============================================================================

# We use Left Riemann Sum -> https://en.wikipedia.org/wiki/Riemann_sum
gam.integrate <- function(model, a, b, n = 1000)
{
	h    <- (b - a) / n
	area <- 0

	xs <- data.frame(time  = seq(from = a, to = b, length.out = n))
	ys <- data.frame(power = predict.gam(model, xs))

	for (y in ys$power)
		area <- area + (y * h)

	return (area)
}

#===============================================================================
# Create power table
#===============================================================================

experiment.generate.power <- function(
	experiment.df,
	experiment.name,
	experiment.outfile.total,
	experiment.outfile.predict,
	experiment.outfile.means,
	experiment.outfile.all,
	experiment.versions,
	experiment.iteration = 0,
	experiment.return = "total",
	experiment.force.generation = TRUE
)
{
	if (!experiment.force.generation)
	{
		if (experiment.return == "total" & file.exists(experiment.outfile.total))
			return (read.delim(file = experiment.outfile.total, sep = ";", header = TRUE))

		if (experiment.return == "predict" & file.exists(experiment.outfile.predict))
			return (read.delim(file = experiment.outfile.predict, sep = ";", header = TRUE))

		if (experiment.return == "means" & file.exists(experiment.outfile.means))
			return (read.delim(file = experiment.outfile.means, sep = ";", header = TRUE))

		if (experiment.return == "all")
			return (filter(experiment.df, component == "power" & it == experiment.iteration & time >= 103))
	}

	#===============================================================================
	# Pre-Processing
	#===============================================================================

	experiment.df.cmp <- filter(experiment.df,
		component == "power" & it == experiment.iteration & time >= 103
	)

	power.total.df <- data.frame(
		version = character(0), total = double(0), avg = double(0)
	)
	power.predict.df <- data.frame(
		version = character(0), time = double(0), power = double(0)
	)
	power.means.df <- data.frame(
		version = character(0), group = integer(0), time = double(0), power = double(0)
	)
	interval <- 300

	# Compute means of intervals
	for (v in unique(experiment.df.cmp$version))
	{
		#================================================================
		# Total
		#================================================================

		vi.df <- filter(experiment.df.cmp, version == v)

		# Minimum
		vi.x.min <- as.numeric(range(vi.df$time)[1])

		# Decrement boot time.
		vi.df <- vi.df %>% mutate(time = (time - vi.x.min))

		# Regresion
		vi.fit <- gam(power ~ s(time, bs = "cs"), data = vi.df)

		# Integral
		vi.x.min <- as.numeric(range(vi.df$time)[1])
		vi.x.max <- as.numeric(range(vi.df$time)[2])
		ta = vi.x.min
		tb = vi.x.max

		vi.total <- gam.integrate(
			model = vi.fit,
			a = ta,
			b = tb,
			n = 1000
		)
		vi.avg <- vi.total / (tb - ta)

		power.total.df <- rbind(
			power.total.df,
			data.frame(version = v, nprocs = p, total = vi.total, avg = vi.avg)
		)

		#================================================================
		# Predict
		#================================================================

		# Generate regression data
		vi.predict.df <- data.frame(
			version = vi.df$version,
			time = vi.df$time,
			power = predict.gam(vi.fit, data = vi.df)
		)
		power.predict.df <- rbind(power.predict.df, vi.predict.df)

		#================================================================
		# Mean
		#================================================================

		vi.means.df <- vi.df

		# Drop uncomplete interval
		len    <- length(vi.df$time)
		remain <- len %% interval
		vi.means.df <- vi.means.df[1:(len-remain),]

		vi.means.df <- vi.means.df %>%
			group_by(group = gl(length(power) / interval, interval)) %>%
			summarise(power = mean(power))

		# Redefine group
		vi.means.df$version <- v
		vi.means.df$time    <- seq(from = 0, to = length(vi.means.df$power) - 1, by = 1)

		# Concatenate data frame
		power.means.df <- rbind(power.means.df, vi.means.df)
	}

	write.table(
		x = power.total.df,
		file = experiment.outfile.total,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	write.table(
		x = power.predict.df,
		file = experiment.outfile.predict,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	write.table(
		x = power.means.df,
		file = experiment.outfile.means,
		sep = ";",
		append = FALSE,
		quote = FALSE,
		row.names = FALSE
	)

	if (experiment.return == "predict")
		return(power.predict.df)
	else if (experiment.return == "means")
		return(power.means.df)
	else if (experiment.return == "all")
		return (experiment.df.cmp)

	return(power.total.df)
}

