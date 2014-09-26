# getSymbols.yahooj {{{
"getSymbols.yahooj" <-
    function(Symbols, env, return.class='xts', index.class="Date",
             from='2007-01-01',
             to=Sys.Date(),
             ...)
    {
        importDefaults("getSymbols.yahooj")
        this.env <- environment()
        for(var in names(list(...))) {
            # import all named elements that are NON formals
            assign(var, list(...)[[var]], this.env)
        }
        if(!exists("adjust", environment(), inherits=FALSE))
            adjust <- FALSE

        default.return.class <- return.class
        default.from <- from
        default.to <- to

        if(missing(verbose)) verbose <- FALSE
        if(missing(auto.assign)) auto.assign <- TRUE
        yahoo.URL <- "http://info.finance.yahoo.co.jp/history/"
        for(i in 1:length(Symbols)) {
            return.class <- getSymbolLookup()[[Symbols[[i]]]]$return.class
            return.class <- ifelse(is.null(return.class),default.return.class,
                                   return.class)
            from <- getSymbolLookup()[[Symbols[[i]]]]$from
            from <- if(is.null(from)) default.from else from
            to <- getSymbolLookup()[[Symbols[[i]]]]$to
            to <- if(is.null(to)) default.to else to

            from.y <- as.numeric(strsplit(as.character(as.Date(from,origin='1970-01-01')),'-',)[[1]][1])
            from.m <- as.numeric(strsplit(as.character(as.Date(from,origin='1970-01-01')),'-',)[[1]][2])
            from.d <- as.numeric(strsplit(as.character(as.Date(from,origin='1970-01-01')),'-',)[[1]][3])
            to.y <- as.numeric(strsplit(as.character(as.Date(to,origin='1970-01-01')),'-',)[[1]][1])
            to.m <- as.numeric(strsplit(as.character(as.Date(to,origin='1970-01-01')),'-',)[[1]][2])
            to.d <- as.numeric(strsplit(as.character(as.Date(to,origin='1970-01-01')),'-',)[[1]][3])

            Symbols.name <- getSymbolLookup()[[Symbols[[i]]]]$name
            Symbols.name <- ifelse(is.null(Symbols.name),Symbols[[i]],Symbols.name)
            if(verbose) cat("downloading ",Symbols.name,".....\n\n")

            page <- 1
            totalrows <- c()
            while (TRUE) {
                tmp <- tempfile()
                download.file(paste(yahoo.URL,
                                    "?code=",Symbols.name,
                                    "&sm=",from.m,
                                    "&sd=",sprintf('%.2d',from.d),
                                    "&sy=",from.y,
                                    "&em=",to.m,
                                    "&ed=",sprintf('%.2d',to.d),
                                    "&ey=",to.y,
                                    "&tm=d",
                                    "&p=",page,
                                    sep=''),destfile=tmp,quiet=!verbose)

                fdoc <- htmlParse(tmp)
                unlink(tmp)

                rows <- xpathApply(fdoc, "//table[@class='boardFin yjSt marB6']//tr")
                if (length(rows) == 1) break

                totalrows <- c(totalrows, rows)
                page <- page + 1
            }
            if(verbose) cat("done.\n")

            # Process from the start, for easier stocksplit management
            totalrows <- rev(totalrows)
            mat <- matrix(0, ncol=7, nrow=0, byrow=TRUE)
            for(row in totalrows) {
                cells <- getNodeSet(row, "td")

                # 2 cells means it is a stocksplit row
                # So extract stocksplit data and recalculate the matrix we have so far
                if (length(cells) == 2) {
                    ss.data <- as.numeric(na.omit(as.numeric(unlist(strsplit(xmlValue(cells[[2]]), "[^0-9]+")))))
                    factor <- ss.data[2] / ss.data[1]

                    mat <- rbind(t(apply(mat[-nrow(mat),], 1, function(x) {
                        x * c(1, rep(1/factor, 4), factor, 1)
                    })), mat[nrow(mat),])
                }

                if (length(cells) != 7) next

                date <- as.Date(xmlValue(cells[[1]]), format="%Y年%m月%d日")
                entry <- c(date)
                for(n in 2:length(cells)) {
                    entry <- cbind(entry, as.numeric(gsub(",", "", xmlValue(cells[[n]]))))
                }

                mat <- rbind(mat, entry)
            }

            fr <- xts(mat[, -1], as.Date(mat[, 1]), src="yahooj", updated=Sys.time())
            symname <- paste('YJ', toupper(Symbols.name), sep="")
            colnames(fr) <- paste(symname,
                                  c('Open','High','Low','Close','Volume','Adjusted'),
                                  sep='.')

            fr <- convert.time.series(fr=fr,return.class=return.class)
            if(is.xts(fr))
                indexClass(fr) <- index.class

            Symbols[[i]] <- symname
            if(auto.assign)
                assign(Symbols[[i]],fr,env)
            if(i >= 5 && length(Symbols) > 5) {
                message("pausing 1 second between requests for more than 5 symbols")
                Sys.sleep(1)
            }

        }
        if(auto.assign)
            return(Symbols)
        return(fr)
    }
# }}}
