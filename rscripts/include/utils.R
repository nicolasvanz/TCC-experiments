#
# Copyright(C) 2020 Pedro Henrique Penna <pedrohenriquepenna@gmail.com>
#
# All rights reserved.
#

#
# Cooks an experiment data frame.
#
experiment.cook <- function(
	df,
	variables.id,
	variables
) {

	oldw <- getOption("warn")
	options(warn = -1)
	df.filtered <- subset(
		aggregate(df, by = list(id.var = df[[variables.id]]), FUN = mean),
		select = append("id.var", variables)
	)
	options(warn = oldw)

	return (df.filtered)
}
