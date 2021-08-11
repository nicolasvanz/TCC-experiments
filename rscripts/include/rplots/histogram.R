#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")

# Plots a histogram.
plot.histogram <- function(
  df,
  var,
  title, subtitle = NULL,
  axis.x.title, axis.x.limits = NULL,
  axis.x.trans = "identity",
  axis.y.title, axis.y.limits = NULL,
  axis.y.trans = 'identity',
  axis.y.trans.fn = function(x) x,
  axis.y.trans.format = math_format()(1:10),
  axis.y.labels = function(x) sprintf("%.1f", x),
  vline.median = FALSE
) {
	p <- ggplot(
		df,
		aes(x = get(var))
	) +
	geom_density(alpha = 0.2, fill = "gray50", na.rm = TRUE) +
	labs(
		title = title,
		subtitle = subtitle,
		x = axis.x.title,
		y = axis.y.title
	) +
   scale_x_continuous(
		expand = c(0, 0),
		limits = axis.x.limits
   ) +
	scale_y_continuous(
		expand = c(0, 0),
		limits = axis.y.limits,
		breaks = scales::pretty_breaks(n = 5),
		labels = axis.y.labels
	) +
	theme_classic()

	if (vline.median == TRUE) {
		p <- p + geom_vline(
			aes(xintercept = median(get(var), na.rm = TRUE)),
				color="black",
				linetype="dashed",
				size=1
		) +
		 geom_text(
			aes(
				x = median(get(var), na.rm = TRUE),
				y = 0,
				label = paste(
					"Median = ",
					sprintf("%.2f", median(get(var), na.rm = TRUE))
				)
			),
			colour = "black",
			angle = 90,
			vjust = -0.5,
			hjust = -0.1
		)
	}

	return (p)
}
