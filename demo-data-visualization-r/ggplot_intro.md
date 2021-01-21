---
title: "Plotting and data visualization in R"
author: "DataFest 2021 Team"
date: "Tuesday, January 19, 2021"
---

Approximate time: 40 minutes

## Learning Objectives 

* Explain the syntax to utilize the "ggplot2" package to visualize data.

## Data Visualization with `ggplot2`

When we are working with large sets of numbers it can be useful to display that information graphically to gain more insight. Here we will be plotting with the popular Bioconductor package [`ggplot2`](http://docs.ggplot2.org/).

The `ggplot2` syntax takes some getting used to, but once you get it, you will find it's extremely powerful and flexible. We will start with drawing a simple boxplot of case rates in each state (and DC) for the aggregated weekly data (53 data points). Please note that `ggplot2` will only accept a "data frame" or "tibble" as input.

### Basic boxplot

Let's start by loading the `ggplot2` library:

```r
library(ggplot2)

# You should have this already loaded as part of tidyverse, but we are reloading it to be certain
```

The `ggplot()` function is used to **initialize the basic graph structure**. The idea is that you specify different elements of the plot using additional functions one after the other and combine them into a "code chunk" using the `+` operator; the functions in the resulting code chunk are called layers.

Let's start: 

```r
ggplot(US_cases_long_week) # what happens? 
```

You get an blank plot, because you need to **specify additional layers** with pertinent information like *"what kind of plot you want"*, *"which columns are your x- and y- axes"* etc. Each new layer is added after the `+` operator.

**Mandatory layer**: The **geom (geometric) object** is the layer that specifies what kind of plot we want to draw. A plot **must have at least one `geom`**; there is no upper limit to the number of `geom` layers. Only caveat is that they have to be compatible with one another. 

Examples of `geom` layers for various types of plots are listed below:

* points => `geom_point`, `geom_jitter` for scatter plots, dot plots, etc.
* lines => `geom_line`, for time series, trend lines, etc.
* boxplot => `geom_boxplot`, for, well, boxplots!

Let's add a "geom" layer to our plot using the `+` operator, and since we want a boxplot so we will use `geom_boxplot()`.

```r
ggplot(US_cases_long_week) +
  geom_boxplot() # note what happens here
```

Why do we get an error? Is the error message easy to decipher?

```r
Error: stat_boxplot() requires an x or y aesthetic.
```

We get an error because each type of `geom` usually has a **required set of aesthetics** to be set. "Aesthetics" are set with the aes() function and can be set either nested within `geom_point()` (applies only to that layer) or within `ggplot()` (applies to the whole plot).

The `aes()` function has many different arguments, and all of those arguments take columns (from the original data frame) as input. It can be used to specify many plot elements including the following:

* position (i.e., on the x and y axes)
* color ("outside" color)
* fill ("inside" color) 
* shape (of points)
* linetype
* size (based on a numeric column)

To start, we will specify x- and y-axis i.e. what you want to plot on the x and y axes. All of the other plot elements mentioned above are optional.

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K))
```

Now that we have the required aesthetics, let's add some extras like color to the plot. We can add a color for each state.

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K, color = state))
```

Did that work as you expected? 

The `color` argument only colors the boxplot lines, but does not fill the boxes with color. We want to have the boxes filled with color, and to do that we need to use the `fill` argument instead of the color argument.

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K, fill = state))
```

You can use the arrow keys above the plot to go back and forth between the 2 plots to understand the difference between `fill` and `color`.

### Adding theme layers

Let's say we want to change the background of the plot from grey to white, so it makes it easier to see the plot. The X-axis labels are also impossible to read given that they are all overlapping with each other. We can make these changes using an additional layer type, something called a **theme layer**. The ggplot2 `theme` system handles non-data plot elements including:

* Axis label aesthetics
* Plot background
* Facet label backround
* Legend appearance

There are built-in themes we can use (e.g. `theme_bw()` or theme_classic()) that mostly change the background/foreground colours, by adding it as additional layer. Or we can adjust specific elements of the current default theme by adding the `theme()` layer and passing in arguments for the things we wish to change. Or we can use both.

Let's first add a layer `theme_bw()`. 

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K, fill = state)) +
  theme_bw()
```

Does this fix our issue with the x-axis labels? No, but it does change the background color to white.

Conveniently, ggplot allows us to add multiple theme layers.

> NOTE: If you add a `theme()` layer "on top of" (or after) any other `theme()` layer, and both layers are changing the same non-data element of the plot, the most recent `theme()` layer wins, i.e. it overrides the setting from the previous theme layer.

Next, let's work on the issue of the x-axis labels using `theme()`. Since we are only changing the test of the x axis, we can use the argument `axis.text.x` and as input we can provide a function that is used to modify text in ggplot2, `element_text()`; and within it we can use the `angle` argument to angle the names of states to prevent overlapping.

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K, fill = state)) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 40))
```

This helps, but the names are still aligned in the middle and it looks odd. Let's adjust the alignment to be right aligned using the `hjust` argument within `element_text()`.

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K, fill = state)) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 40, hjust = 1))
```

Great, that is looking a lot better!

### Changing the color scheme

Let's say we don't like the colors as they are and want to change them. There are many packages available with color palettes that you can use, e.g. [RColorBrewer](https://www.r-graph-gallery.com/38-rcolorbrewers-palettes.html), [viridis](https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html) among others. Today we will be using the viridis package with its color-blind-friendly color palette. You should have loaded the viridis library during setup.

The viridis package has functions that work with ggplot, like `scale_color_viridis()` and `scale_fill_viridis()`. Which of these do you think we should use?

Since we are using the aesthetic argument `fill`, the appropriate function for us to change our boxplot colors is `scale_fill_viridis()`. We have to let the function know that our colors are not on a continuous scale and we need 51 discrete colors (default is discrete=F). 

```r
ggplot(US_cases_long_week) +
  geom_boxplot(aes(x= state, y = cases_rate_100K, fill = state)) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 40, hjust = 1)) +
  scale_fill_viridis(discrete = T)
```

Now we have a more reasonable looking plot compared to where we started out and we have colored it with more accesible colors too!

This lesson is just a very high level introduction to layers and themes in ggplot2. There is so much more you can do with it, to help we have added some resources below.

## Resources:
* You can use the `example("geom_boxplot")` to explore a multitude of different aesthetics and layers that can be added to your plot. As you scroll through the different plots, take note of how the code is modified. You can use this with any of the different geometric object layers available in ggplot2 to learn how you can easily modify your plots! 
* RStudio provide this very [useful cheatsheet](https://www.rstudio.com/wp-content/uploads/2016/11/ggplot2-cheatsheet-2.1.pdf) for plotting using `ggplot2`. Different example plots are provided and the associated code (i.e which `geom` or `theme` to use in the appropriate situation.) 
* We also encourage you to persuse through this useful [online reference](https://ggplot2.tidyverse.org/reference/) for working with ggplot2.
