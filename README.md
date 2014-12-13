Download stock data from Yahoo! Japan
=====================================

This has been a little project to be able to download stock data from Yahoo! Japan Finance quickly for analysis in R. The code has been accepted into the [quantmod](http://www.quantmod.com) library. You can find it included, starting in version 0.4-3, which can be [installed from R-Forge](https://r-forge.r-project.org/R/?group_id=125).

Installation
------------

As it has not been updated on CRAN yet, you can install `quantmod` from R-Forge with the following command in your R console:

    install.packages("quantmod", repos="http://R-Forge.R-project.org")

Usage
-----

First, load the `quantmod` library:

    library(quantmod)

To choose the Yahoo! Japan source, specify the `src="yahooj"` parameter when you use `getSymbols`.

To download for example Sony (6758) stock data starting from January 2013, use the following code:

    getSymbols("6758.T", src="yahooj", from="2013-01-01")

Since Japanese stock tickers often start with a number, it is not possible to keep the stock symbol as the name of the variable, so I have had to prepend it with "YJ". If auto-assigning into the environment is enabled, which it is by default, then you will find a new variable called `YJ6758.T` in your environment.

For more information on how to use the `getSymbols` function, or more specifically the `getSymbols.yahooj` function, please refer to the R Help system.
