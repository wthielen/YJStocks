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
            from.m <- as.numeric(strsplit(as.character(as.Date(from,origin='1970-01-01')),'-',)[[1]][2])-1
            from.d <- as.numeric(strsplit(as.character(as.Date(from,origin='1970-01-01')),'-',)[[1]][3])
            to.y <- as.numeric(strsplit(as.character(as.Date(to,origin='1970-01-01')),'-',)[[1]][1])
            to.m <- as.numeric(strsplit(as.character(as.Date(to,origin='1970-01-01')),'-',)[[1]][2])-1
            to.d <- as.numeric(strsplit(as.character(as.Date(to,origin='1970-01-01')),'-',)[[1]][3])
            
            Symbols.name <- getSymbolLookup()[[Symbols[[i]]]]$name
            Symbols.name <- ifelse(is.null(Symbols.name),Symbols[[i]],Symbols.name)
            if(verbose) cat("downloading ",Symbols.name,".....\n\n")
            
            cols <- c('Open','High','Low','Close','Volume','Adjusted')
            
            mat <- matrix(0, ncol=7, nrow=0, byrow=TRUE)
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
                
                for(row in rows) {
                    cells <- getNodeSet(row, "td")
                    if (length(cells) == 0) next
                    
                    date <- as.Date(xmlValue(cells[[1]]), format="%Y年%m月%d日")
                    entry <- c(date)
                    for(n in 2:length(cells)) {
                        entry <- cbind(entry, as.numeric(gsub(",", "", xmlValue(cells[[n]]))))
                    }
                    
                    mat <- rbind(mat, entry)
                }
                
                page <- page + 1
            }
            
            if(verbose) cat("done.\n")
            
            fr <- xts(mat[-1, -1], as.Date(mat[-1, 1]), src="yahooj", updated=Sys.time())
            colnames(fr) <- paste('YJ', toupper(Symbols.name),
                                  c('Open','High','Low','Close','Volume','Adjusted'),
                                  sep='.')
            
            fr <- convert.time.series(fr=fr,return.class=return.class)
            if(is.xts(fr))
                indexClass(fr) <- index.class
            
            Symbols[[i]] <- paste('YJ', toupper(Symbols[[i]])) 
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