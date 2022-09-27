# PitcherPlantViruses
Metadata, Bash and R scripts used for analyses in Holdridge et al. 2022

# Meta-analysis: environmental sampling of bacteriophage
To examine findings from independent studies involving environmental sampling of bacteriophage (or phage), 
a meta-analysis was performed that included metadata from the sampling environment type, the phage type and taxa identified, 
and the sequence analysis pipeline utilized to identify phage. 

# Methods
A “naïve search” was done through the literature database Web of Science using the following search terms: 
bacteriophage, phage, ecology, “environmental sample”, “nutrient cycle”, and metabolism; the search excluded the term medicine. 
The naïve search yielded 117 article results. The literature search terms and results were refined using the packages 
litsearchr and revtools  (Metaverse) in Rstudio (R version 4.1.0). Refined search terms input to Web of Science include: 
“bacteriophage OR phage OR virus” AND “environment OR aquatic OR marine OR soil” AND “genomics OR isolated OR isolation” AND 
“ecology OR "microbial ecology"”, NOT medicine. The refined search from litsearchr yielded 404 article results. Topic group exclusion 
through the R package revtools was used to filter irrelevant articles. In revtools the LDA model was set at 20,000 iterations 
within 30 topics; variables selected were title, abstract, keywords, research_areas, and keywords_plus. The following topic groups 
were excluded: “wild, bird, subtype, influenza, surveillance”, “viruses, chicken, poultry, influenza_viruses, evolution”, 
“sample, environment, isolate, salmonella, show”, and “human, nature, pandemic, ecology, suggest”. Revtools filtering process 
resulted in 242 articles. All resulting articles were manually filtered to exclude review or method articles, articles published prior to 
2010, articles with no viral identification or environmental sampling, articles regarding avian viruses, and articles that were not able to 
be accessed through Boise State University's institutional access. After all curation, 99 articles met the criteria for the meta-analysis.
Metadata for the topic “phage type” was recorded as “mixed” if more than one DNA type was identified. Metadata for the topic 
“sequence analysis pipeline” was recorded as “manual” if no known analysis pipeline was used. Metadata for the topic “phage taxa” was recorded 
as “mixed” if more than two taxa of viruses were identified. 
