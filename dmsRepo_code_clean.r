unzip("pdfmerge_export.zip", exdir = "DMS 2023")
fnames <- list.files("DMS 2023", full.names = TRUE)
plans <- lapply(fnames, tabulizer::extract_text)
plans <- lapply(plans, tm::stripWhitespace)
dbsearch <- read.csv("database_regex.csv", stringsAsFactors = FALSE, allowEscapes = TRUE)
pln_repo <- lapply(plans, function(x) stringr::str_detect(x, dbsearch$regex))
pln_repo <- lapply(pln_repo, which)
pln_repo <- lapply(1:length(pln_repo), function(x) dbsearch$database[pln_repo[[x]]])
pln_repo[sapply(pln_repo, length) == 0] <- "None"
pln_repo <- data.frame(pln_num = 1:length(pln_repo), filename = gsub(".+\\/", "", fnames), repositories = sapply(pln_repo, paste, collapse = ";"))
repo_counts <- plyr::count(unlist(strsplit(pln_repo$repositories, ";")))
pln_repo$appl_id <- gsub("\\.pdf", "", pln_repo$filename)
pln_repo <- pln_repo[,c("appl_id", "pln_num", "filename", "repositories")]
colnames(repo_counts) <- c("repository", "count_of_plans")
write.csv(pln_repo, file = "repos_by_appl_id.csv", row.names = FALSE)
write.csv(repo_counts, file = "repo_counts.csv", row.names = FALSE)