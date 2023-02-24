# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")
library("RColorBrewer")
library("gcookbook")
library("ggsci")
library("ggh4x")

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
			fill = get(factor),
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
#	scale_fill_tron(
#	scale_fill_viridis_d(
#	scale_fill_brewer(palette = "Reds",
#	scale_fill_manual(values = c(brewer.pal(4, "Blues")[-1], brewer.pal(4, "Reds")[-1]),
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
			fill = get(factor),
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
#	scale_fill_viridis_d(option = "inferno"
#	scale_fill_tron(
#	scale_fill_brewer(palette = "Dark2",
	scale_fill_grey(
		labels = legend.labels,
		start = 0.8,
		end = 0.2,
		na.value = "red",
		aesthetics = "fill"
	)+
	facet_wrap(~ get(facet), scales = "free", nrow = 1) +
	theme_classic()
}

# Facet
plot.stacks.colour <- function(
	df,
	var.x, var.y, factor, facet = NULL,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL, axis.x.labels = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = "stack",
	colour = c("#fee0d2", "#de2d26"),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(
			x = factor(get(var.x)),
			y = get(var.y),
			fill = get(factor),
		)
	) +
	geom_bar(
		stat = "identity",
		width = 0.8,
		colour = "black",
		position = position,
		size = 0
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.labels,
		breaks = axis.x.breaks
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
#	scale_fill_tron(
#	scale_fill_viridis_d(
#	scale_fill_manual(values = c(brewer.pal(4, "Blues")[-1], brewer.pal(4, "Reds")[-1]),
#	scale_fill_brewer(palette = colour,
	scale_fill_manual(values = colour,
		labels = legend.labels
	) +
	facet_grid(~ get(facet), scales = "free_x", space = "free_x") +
	theme_classic()
}

# Facet
plot.stacks.grey <- function(
	df,
	var.x, var.y, factor,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL, axis.x.labels,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = "stack",
	colour = c("#fee0d2", "#de2d26"),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(
			x = factor(get(var.x)),
			y = get(var.y),
			fill = get(factor),
		)
	) +
	geom_bar(
		stat = "identity",
		width = 0.8,
		colour = "black",
		position = position,
		size = 0
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.labels,
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
		start = 0.9,
		end = 0.1,
		na.value = "red",
		aesthetics = "fill"
	) +
	theme_classic()
}
