### Using Metaverse for Meta-Analyses ###
## Authors: Erica M. Holdridge and Marcus Emmen ##
## Last updated: September 27, 2022 ##

#install packages
install.packages(c("remotes","dplyr","ggplot2","ggraph","igraph","readr","devtools"))
library(remotes)
install_github("elizagrames/litsearchr", ref="main")
remotes::install_github("rmetaverse/metaverse")

#synthesisr
#import, assemble and de-duplicate bibliography
library(synthesisr)

#litsearchr
#search strategy development

#load necessary packages
library(dplyr)
library(ggplot2)
library(ggraph)
library(igraph)
library(readr)
library(devtools)
library(litsearchr)

#import naive results generated using Web of Science 
# search terms: bacteriophage, phage, ecology, "environmental sample", 
# "nutrient cycle", metabolism, -medicine
naive_results<-litsearchr::import_results(file="/R/metaverse/savedrecs.txt")
View(naive_results)
colnames(naive_results)

# nonexhaustive list of general ecology terms 
micro_eco_stopwords<-readLines("/R/metaverse/microbial_ecology_stopwords.txt")

#combines that list with commonly used words in English
all_stopwords <- c(get_stopwords("English"), micro_eco_stopwords)
key_terms<-extract_terms(keywords=naive_results[, "keywords"], method="tagged", min_n=1, min_freq=3,
                         language = "English", stopwords=all_stopwords)
title_terms<-extract_terms(text=naive_results[, "title"], method="fakerake", min_n=1, min_freq=3,
                           language = "English", stopwords=all_stopwords)
terms<-unique(c(key_terms,title_terms))

# Visualize how often these search terms are used together with
# network analysis.

docs <- paste(naive_results[, "title"], naive_results[, "abstract"])
df <- create_dfm(elements=docs, features=terms)
g <- create_network(df, min_studies=3)

ggraph(g, layout="stress") +
  coord_fixed() +
  expand_limits(x=c(-3, 3)) +
  geom_edge_link(aes(alpha=weight)) +
  geom_node_point(shape="circle filled", fill="white") +
  geom_node_text(aes(label=name), hjust="outward", check_overlap=TRUE) +
  guides(edge_alpha=FALSE)

# notice outliers like "antibiotic resistance" and "coliophages".
# won't be very useful for our purposes so we can eliminate them.
# look at which terms are most weakly linked (weakest to strongest)
strengths <- strength(g)
data.frame(term=names(strengths), strength=strengths, row.names=NULL) %>%
  mutate(rank=rank(strength, ties.method="min")) %>%
  arrange(strength) ->
  term_strengths

term_strengths

# use strengths to create a cutoff, below which we will remove
# terms with weak associations. We will let litsearchr find cutoff 3 points where
# there are big "jumps" in strength
cutoff<-find_cutoff(g, method="changepoint", knot_num=3)

ggplot(term_strengths, aes(x=rank, y=strength, label=term)) +
  geom_line() +
  geom_point() +
  geom_text(data=filter(term_strengths, rank>5), hjust="right", nudge_y=20, check_overlap=TRUE) +
  geom_hline(yintercept=cutoff, linetype="dashed")

g_redux <- reduce_graph(g, cutoff[1])
selected_terms <- get_keywords(g_redux)
selected_terms

# manually group our new search terms into subtopics, which will
# help us create a new search query.

grouped_terms <- list(organismal=selected_terms[c(1,2,3,11,12,13,20,21)],
                      environment=selected_terms[c(6,9,14,15,16,19,22)],
                      technique=selected_terms[c(8,17,18)],
                      general=selected_terms[c(4,5,7,10)])

# use these new grouping to create a new search that will return more articles of interest. 

write_search(
  grouped_terms,
  languages="English",
  exactphrase=TRUE,
  stemming=FALSE,
  closure="left",
  writesearch=TRUE
)

# I manually curated this a bit and ended up with:
# bacteriophage OR phage OR virus AND environment OR aquatic OR marine OR soil
# AND genomics OR isolated OR isolation AND ecology OR "microbial ecology" 
# NOT medicine.
# This increased results on WoS from 117 to 325.
# We can check to make sure all the results from our first search are included
# in the new one and add in any ones that aren't. 

new_results <- import_results(file="/R/metaverse/savedrecs_new.txt")

naive_results %>%
  mutate(in_new_results=title %in% new_results[, "title"]) ->
  naive_results

not_included<- naive_results %>%
  filter(!in_new_results)
View(not_included)

# make sure the column names line up
cols_to_keep <- intersect(colnames(not_included),colnames(new_results))
not_included2 <- not_included[,cols_to_keep,drop=FALSE]
new_results2 <- new_results[,cols_to_keep,drop=FALSE]

all_results <- rbind(not_included2,new_results2)

# get rid of any duplicates 
library(synthesisr)
dedup_results<- deduplicate(
  all_results,
  match_by = "title",
  method = "exact"
)

#Now we have a little over 400 papers that match our search criteria

#revtools
#article screening for evidence synthesis
library(revtools)

# We can double check to make sure we removed all the duplicates.
screen_duplicates(all_results)

# manually screen paper titles and exclude any that don't seem relevant. 
# Upon saving and exiting the app, it will write these new 
# results back to 'new_all_results'.

new_all_results <- screen_titles(all_results)

# Screen our results in revtools. This will generate a 
# model that clusters similar papers together and ranks the terms that produce
# these similarities.

# selected under LDA model: 20,000 iterations, 30 topics
# selected under variables: title, abstract, keywords, research_areas, keywords_plus
# topics groups excluded:
## "wild, bird, subtype, influenza, surveillance"
### "viruses, chicken, poultry, influenza_viruses, evolution"
#### "sample, environment, isolate, salmonella, show"
##### "human, nature, pandemic, ecology, suggest"

results_screened_topics <- screen_topics(all_results)

# if errors occur for pipes or revtools load the packages again
library(dplyr)
library(revtools)

# assign data frame from revtools to object
new_results_screened_topics <- new_results_screened_topics[["raw"]]

# filter out excluded topics
selected_results <- new_results_screened_topics %>% 
  filter(screened_topics=="selected")

# filter out only articles that are open access and published after 2000
## show only the title, author, source, abstract, keywords, research_areas, year
articles_only_results <- selected_results %>% 
  filter(document_type=="Article") %>% 
  filter(!is.na(open_access)) %>% 
  filter(year>2000) %>% 
  select(title,author,source,abstract,keywords,research_areas,year)
  
# create a version that includes all articles, not just open access
articles_only_results2 <- selected_results %>% 
  filter(document_type=="Article") %>% 
  filter(year>2000) %>% 
  select(title,author,source,abstract,keywords,research_areas,year)

# write CSV from articles_only_results with only open access
write.csv(articles_only_results,"D:/R/metaverse/final_results_open_access.csv")

# write CSV from articles_only_results with all access types
write.csv(articles_only_results2,"D:/R/metaverse/final_results.csv")