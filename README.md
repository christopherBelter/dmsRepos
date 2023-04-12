# dmsRepos
This repository presents R code to identify data repositories mentioned in a set of NIH data management and sharing (DMS) plans. The code takes a .zip file of PDF DMS plans created through the QVR PDFMERGE Standard Report and identifies whether or not a set of known repositories are mentioned in each plan. It also creates a summary table of how many plans mention each repo. 

## Setting up
This code uses the following packages: ``tabulizer``, ``tm``, ``stringr``, and ``plyr``. Make sure you have them installed for the code to work. 

This code makes a number of assumptions about the structure of the PDFMERGE output, so that output needs to be formatted accordingly for the code to work. It expects that the DMS plan is the only document exported in the output, it expects that the output is a zip file of PDFs with one DMS plan per PDF, and that the individual PDFs follow the naming convention ``[applID].pdf``. These are all available options in the PDFMERGE report, so make sure they're selected before you run the report. 

## The code
First, unzip the PDFMERGE output zip file to a folder called "DMS 2023" in your current working directory. You can change the filepaths in either argument if you want to put the plans somewhere else. 
```r
unzip("pdfmerge_export.zip", exdir = "DMS 2023")
```
Then create a list of the pdf file names in the "DMS 2023" folder so we can use it to read the files in. If you changed the ``exdir`` argument above, be sure to use the same file path as the first argument to the ``list.files()`` function. Also make sure that there aren't any other files in that folder to avoid reading errors. 
```r
fnames <- list.files("DMS 2023", full.names = TRUE)
```
Then read in the text of each pdf and remove any extra whitespace from the pdf formatting. Note that you'll get a lot of INFO messages about embedded fonts and other fomatting after running the ``extract_text()`` function. Don't worry about them; they're normal.
```r
plans <- lapply(fnames, tabulizer::extract_text)
plans <- lapply(plans, tm::stripWhitespace)
```
Then read in the list of regular expressions that we'll use to find mentions to known repositories. Having them in a .csv file like this helps us stay organized and to easily add additional repositories to the list that we're searching for. Note that the .csv also has an "Other" category, which attempts to identify if a plan mentions that data will be available, regardless of the actual repo named. This is to try and identify plans that mention repositories not on the current search list. And be sure to set the ``allowEscapes`` argument to TRUE, as below, to make sure the regular expression escape characters are read in properly.
```r
dbsearch <- read.csv("database_regex.csv", stringsAsFactors = FALSE, allowEscapes = TRUE)
```
Now that we have everything set up and in memory, we'll create a data frame to identify the repos mentioned in each plan. First, we'll create a list of true/false vectors to see if each repo in the ``dbsearch`` data frame is mentioned anywhere in each plan. 
```r
pln_repo <- lapply(plans, function(x) stringr::str_detect(x, dbsearch$regex))
```
We'll then subset the vectors to keep the index number(s) at which the value(s) is(are) TRUE
```r
pln_repo <- lapply(pln_repo, which)
```
We'll then replace these index numbers with the corresponding repo names and, if the plan doesn't match any of the repos in the ``dbsearch`` data frame, put "None" instead.
```r
pln_repo <- lapply(1:length(pln_repo), function(x) dbsearch$database[pln_repo[[x]]])
pln_repo[sapply(pln_repo, length) == 0] <- "None"
```
Then we'll put all of this information together into a data frame with three columns: the plan number, the filename of the plan, and a semicolon-delimited list of the repositories mentioned in the plan. 
```r
pln_repo <- data.frame(pln_num = 1:length(pln_repo), filename = gsub(".+\\/", "", fnames), repositories = sapply(pln_repo, paste, collapse = ";"))
```
Then, assuming that you're following the file naming convention mentioned above, create a new column for the plan's appl_id that you can use to merge the results back into other project data you might have gotten from other places. 
```r
pln_repo$appl_id <- gsub("\\.pdf", "", pln_repo$filename)
pln_repo <- pln_repo[,c("appl_id", "pln_num", "filename", "repositories")]
```
Then, count the number of plans in which each repo is mentioned.
```r
repo_counts <- plyr::count(unlist(strsplit(pln_repo$repositories, ";")))
colnames(repo_counts) <- c("repository", "count_of_plans")
```
Finally, write the resulting data frames out to .csv files for future use. 
```r
write.csv(pln_repo, file = "repos_by_appl_id.csv", row.names = FALSE)
write.csv(repo_counts, file = "repo_counts.csv", row.names = FALSE)
```
