#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

library("ggplot2")

# Saves a plot into a file.
plot.save <- function(
	directory = getwd(),
	filename = "plot",
	plot, width = 7, height = 4,
	output.format = "pdf"
) {
	if (output.format == "pdf") {
		output.device = pdf()
	} else {
		output.format = "png"
		output.device = png()
	}

	filename <- paste(directory, filename, sep = "/")
	filename <- paste(filename, output.format, sep = ".")

	ggsave(
		filename = filename,
		plot = plot,
		width = width,
		height = height,
		dpi = "retina",
		device = output.device
	)
}
