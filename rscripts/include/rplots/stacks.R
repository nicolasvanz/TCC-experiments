# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")

# Plots a bar chart.
plot.stacks <- function(
	df,
	var.x, var.y, factor, facet = NULL,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = "stack",
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(
			x = factor(get(var.x)),
			y = get(var.y),
			fill = get(factor)
		)
	) +
	geom_bar(
		stat = "identity",
		width = 0.8,
		colour = "black",
		position = position
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.breaks,
		breaks = axis.x.breaks
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	scale_fill_grey(
		labels = legend.labels,
		start = 0.8,
		end = 0.2,
		na.value = "red",
		aesthetics = "fill"
	) +
	facet_grid(~ get(facet)) +
	theme_classic()
}

# Plots a bar chart.
plot.stacks2 <- function(
	df,
	var.x, var.y, factor, facet = NULL,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = "stack",
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(
			x = factor(get(var.x)),
			y = get(var.y),
			fill = get(factor)
		)
	) +
	geom_bar(
		stat = "identity",
		width = 0.8,
		colour = "black",
		position = position
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.breaks,
		breaks = axis.x.breaks
	) +
	scale_fill_grey(
		labels = legend.labels,
		start = 0.8,
		end = 0.2,
		na.value = "red",
		aesthetics = "fill"
	) +
	facet_wrap(~ get(facet), scales = "free", nrow = 1) +
	theme_classic()
}
