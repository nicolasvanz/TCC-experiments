#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")

# Plots a bubbles chart.
plot.bubbles <- function(
  df,
  var.x, var.y, var.z, factor,
  title, subtitle = NULL,
  legend.title = NULL, legend.labels = NULL,
  axis.x.title, axis.y.title, axis.z.title
) {
	ggplot(
		df,
		aes(
			x = get(var.x),
			y = get(var.y)
		)
	) +
	geom_point(
		aes(
			color = get(factor),
			size = get(var.z)
		),
		alpha = 0.5
	) +
	scale_size(
		name = axis.z.title,
		range = c(05, 14)
	) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title,
		color = legend.labels
	) +
	theme_classic()
}
