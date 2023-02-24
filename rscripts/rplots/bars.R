#
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
plot.bars <- function(
	df,
	var.x, var.y, factor,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.angle = 45,
	data.labels.dodge = 0.8,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(
			x = get(var.x),
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
	geom_text(
		aes(
			label = round(get(var.y), data.labels.digits),
			group = get(factor)
		),
		hjust = data.labels.hjust,
		vjust = data.labels.vjust,
		position = position_dodge(width = data.labels.dodge),
		angle = data.labels.angle,
		size = 5
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.breaks
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	scale_fill_grey(
		labels = legend.labels
	) +
	theme_classic()
}

# Plots a bar chart.
plot.bars.facet <- function(
	df,
	var.x, var.y, factor, facet,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.angle = 45,
	data.labels.dodge = 0.8,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10)
) {
	ggplot(
		data = df,
		aes(
			x = get(var.x),
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
	geom_text(
		aes(
			label = round(get(var.y), data.labels.digits),
			group = get(factor)
		),
		hjust = data.labels.hjust,
		vjust = data.labels.vjust,
		position = position_dodge(width = data.labels.dodge),
		angle = data.labels.angle,
		size = 5
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.breaks
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	scale_fill_grey(
		labels = legend.labels
	) +
	facet_grid(~ get(facet)) +
	theme_classic()
#	facet_nested(facet) +
}

# Plots a bar chart.
plot.bars.colour <- function(
	df,
	var.x, var.y, factor,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL,
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.angle = 45,
	data.labels.dodge = 0.8,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10),
	colour = c("#fee0d2", "#de2d26")
) {
	ggplot(
		data = df,
		aes(
			x = get(var.x),
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
	geom_text(
		aes(
			label = round(get(var.y), data.labels.digits),
			group = get(factor)
		),
		hjust = data.labels.hjust,
		vjust = data.labels.vjust,
		position = position_dodge(width = data.labels.dodge),
		angle = data.labels.angle,
		size = 5
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_discrete(
		labels = axis.x.breaks
	) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		trans = axis.y.trans,
		breaks = axis.y.breaks,
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	scale_fill_manual(values = colour,
		labels = legend.labels
	) +
	theme_classic()
}

# Plots a bar chart.
plot.bars.facet.colour.default <- function(
	df,
	var.x, var.y, factor, facet,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL, axis.x.labels = NULL,
  axis.x.trans = "identity",
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.angle = 45,
	data.labels.dodge = 0.8,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10),
	colour = c("#fee0d2", "#de2d26")
) {
	ggplot(
		data = df,
		aes(
			x = get(var.x),
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
	geom_errorbar(
		aes(ymin=mean-sd, ymax=mean+sd),
		width=.2,
		position=position_dodge(.9)
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		fill = legend.title
	) +
	scale_x_continuous(
		breaks = axis.x.breaks,
		labels = axis.x.labels,
		trans = axis.x.trans
	) +
	scale_y_continuous(
		trans = axis.y.trans,
		breaks = seq(0, 2500, 25),
		labels = trans_format(axis.y.trans, axis.y.trans.format)
	) +
	scale_fill_manual(values = colour,
		labels = legend.labels
	) +
	facet_wrap(~ get(facet), scales = "free") +
	theme_classic()
#	facet_nested(facet) +
}

# Plots a bar chart.
plot.bars.facet.colour <- function(
	df,
	var.x, var.y, factor, facet,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL, axis.x.labels = NULL,
  axis.x.trans = "identity",
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.angle = 45,
	data.labels.dodge = 0.8,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10),
	colour = c("#fee0d2", "#de2d26")
) {
	ggplot(
		data = df,
		aes(
			x = get(var.x),
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
	scale_x_continuous(
		breaks = axis.x.breaks,
		labels = axis.x.labels,
		trans = axis.x.trans
	) +
  scale_y_continuous(
    expand = c(0, 0),
    limits = c(0, 100),
    trans = scales::pseudo_log_trans(sigma = 0.0001), 
    breaks = c(0, 10^(-3:2)),
	minor_breaks = c(
		100/2/2, 100/2, 100/2 + 100/2/2, 100/2 + 100/2/2 + 100/2/2/2, 100/2 + 100/2/2 + 100/2/2/2 + 100/2/2/2/2,
		10/2/2, 10/2, 10/2 + 10/2/2, 10/2 + 10/2/2 + 10/2/2/2, 10/2 + 10/2/2 + 10/2/2/2 + 10/2/2/2/2,
		1/2/2, 1/2, 1/2 + 1/2/2, 1/2 + 1/2/2 + 1/2/2/2, 1/2 + 1/2/2 + 1/2/2/2 + 1/2/2/2/2,
		0.1/2/2, 0.1/2, 0.1/2 + 0.1/2/2, 0.1/2 + 0.1/2/2 + 0.1/2/2/2, 0.1/2 + 0.1/2/2 + 0.1/2/2/2 + 0.1/2/2/2/2,
		0.01/2/2, 0.01/2, 0.01/2 + 0.01/2/2, 0.01/2 + 0.01/2/2 + 0.01/2/2/2, 0.01/2 + 0.01/2/2 + 0.01/2/2/2 + 0.01/2/2/2/2,
		0.001/2/2, 0.001/2, 0.001/2 + 0.001/2/2, 0.001/2 + 0.001/2/2 + 0.001/2/2/2, 0.001/2 + 0.001/2/2 + 0.001/2/2/2 + 0.001/2/2/2/2
	),
	labels = c("0", "0.001", "0.01", "0.1", "1", "10", "100"),
  ) +
	scale_fill_manual(values = colour,
		labels = legend.labels
	) +
  coord_cartesian(ylim=c(0.000,100)) +
	facet_wrap(~ get(facet), scales = "free_x") +
	theme_classic()
#	facet_nested(facet) +
}


# Plots a bar chart.
plot.bars.colour.bottleneck <- function(
	df,
	var.x, var.y, factor,
	title = NULL, subtitle = NULL,
	axis.x.title, axis.x.breaks = NULL, axis.x.labels = NULL,
  axis.x.trans = "identity",
	axis.y.title, axis.y.limits = NULL,
	legend.labels = NULL, legend.title = NULL,
	data.labels.hjust = 0.0,
	data.labels.vjust = -0.5,
	data.labels.angle = 45,
	data.labels.dodge = 0.8,
	data.labels.digits,
	axis.y.trans = 'identity',
	axis.y.trans.fn = function(x) x,
	position = position_dodge(),
	axis.y.breaks = trans_breaks(axis.y.trans,  axis.y.trans.fn),
	axis.y.trans.format = math_format()(1:10),
	colour = c("#fee0d2", "#de2d26")
) {
	ggplot(
		data = df,
		aes(
			x = get(var.x),
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
	scale_x_continuous(
		breaks = axis.x.breaks,
		labels = axis.x.labels,
		trans = axis.x.trans
	) +
  scale_y_continuous(
    expand = c(0, 0),
    limits = c(0, 100),
    trans = scales::pseudo_log_trans(sigma = 0.0001), 
    breaks = c(0, 10^(-3:2)),
	minor_breaks = c(
		100/2/2, 100/2, 100/2 + 100/2/2, 100/2 + 100/2/2 + 100/2/2/2, 100/2 + 100/2/2 + 100/2/2/2 + 100/2/2/2/2,
		10/2/2, 10/2, 10/2 + 10/2/2, 10/2 + 10/2/2 + 10/2/2/2, 10/2 + 10/2/2 + 10/2/2/2 + 10/2/2/2/2,
		1/2/2, 1/2, 1/2 + 1/2/2, 1/2 + 1/2/2 + 1/2/2/2, 1/2 + 1/2/2 + 1/2/2/2 + 1/2/2/2/2,
		0.1/2/2, 0.1/2, 0.1/2 + 0.1/2/2, 0.1/2 + 0.1/2/2 + 0.1/2/2/2, 0.1/2 + 0.1/2/2 + 0.1/2/2/2 + 0.1/2/2/2/2,
		0.01/2/2, 0.01/2, 0.01/2 + 0.01/2/2, 0.01/2 + 0.01/2/2 + 0.01/2/2/2, 0.01/2 + 0.01/2/2 + 0.01/2/2/2 + 0.01/2/2/2/2,
		0.001/2/2, 0.001/2, 0.001/2 + 0.001/2/2, 0.001/2 + 0.001/2/2 + 0.001/2/2/2, 0.001/2 + 0.001/2/2 + 0.001/2/2/2 + 0.001/2/2/2/2
	),
	labels = c("0", "0.001", "0.01", "0.1", "1", "10", "100"),
  ) +
	scale_fill_manual(values = colour,
		labels = legend.labels
	) +
  coord_cartesian(ylim=c(0.000,100)) +
	theme_classic()

#	facet_nested(facet) +
}

