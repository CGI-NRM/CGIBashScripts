# For dardel:
chooseCRANmirror(ind = 1) # select first CRAN mirror
if("BiocManager" %in% installed.packages()) {
  library(BiocManager)
} else {
  install.packages("BiocManager")
  library(BiocManager)
}
if("dada2" %in% installed.packages()) {
  library(dada2)
} else {
  BiocManager::install("dada2")
  library(dada2)
}
if("edgeR" %in% installed.packages()) {
  library(edgeR)
} else {
  BiocManager::install("edgeR")
  library(edgeR)
}
if("Biostrings" %in% installed.packages()) {
  library(Biostrings)
} else {
  BiocManager::install("Biostrings")
  library(Biostrings)
}

# Functions:
CollectData <- function(directory = "../Filtered_data", prefix = "") {
  forward <- list.files(directory, pattern = "_1.fastq.gz", full.names = TRUE)
  reverse <- list.files(directory, pattern = "_2.fastq.gz", full.names = TRUE)
  forwardC <- list.files(directory, pattern = "_1.fastq.gz", full.names = FALSE)
  reverseC <- list.files(directory, pattern = "_2.fastq.gz", full.names = FALSE)
  forward <- forward[grepl(prefix, forward)]
  reverse <- reverse[grepl(prefix, reverse)]
  forwardC <- forwardC[grepl(prefix, forwardC)]
  reverseC <- reverseC[grepl(prefix, reverseC)]
  filtFs <- file.path(directory, "filtered", forwardC)
  filtRs <- file.path(directory, "filtered", reverseC)
  allSamples <- unique(gsub("_outFwd_1.fastq.gz|_outRev_1.fastq.gz", "", forwardC))
  output <- list(Forward = forward, Reverse = reverse, ForwardC = forwardC, ReverseC = reverseC, FiltFs = filtFs, FiltRs = filtRs, Samples = allSamples, Prefix = prefix)
  return(output)
} 

FiltTrimWrap <- function(primerData) {
  if (length(primerData$Reverse) > 0) { # if paired-ended
    out <- dada2::filterAndTrim(primerData$Forward, primerData$FiltFs, primerData$Reverse, primerData$FiltRs, maxN=0, truncQ=2, rm.phix=TRUE, compress=TRUE, multithread=TRUE)
  } else {
    out <- dada2::filterAndTrim(primerData$Forward, primerData$FiltFs, maxN=0, truncQ=2, rm.phix=TRUE, compress=TRUE, multithread=TRUE)
  }
  return(out)
}

DadaAnalysis <- function(primerData, muThread = TRUE, justConcatenate = FALSE, minOverlap = 5) {
  forward <- primerData$FiltFs
  reverse <- primerData$FiltRs
  errF <- dada2::learnErrors(forward, multithread = muThread)
  derepsF <- dada2::derepFastq(forward)
  dadaF <- dada2::dada(derepsF, err = errF, multithread = muThread)
  if (length(reverse) > 0) { # if there are paired ends
    errR <- dada2::learnErrors(reverse, multithread = muThread)
    derepsR <- dada2::derepFastq(reverse)
    dadaR <- dada2::dada(derepsR, err = errR, multithread = muThread)
    mergers <- dada2::mergePairs(dadaF, derepsF, dadaR,
				 derepsR, verbose = TRUE,
				 justConcatenate = justConcatenate,
				 minOverlap = minOverlap)
    seqTab <- dada2::makeSequenceTable(mergers)
  } else {
    seqTab <- dada2::makeSequenceTable(dadaF)
  }
  seqtabNochim <- dada2::removeBimeraDenovo(seqTab,
					    method = "consensus",
					    multithread = muThread,
					    verbose = TRUE)
  return(seqtabNochim)
}

DFCombine <- function(dataset, samples) {
  counter <- 0
  for(i in samples) {
    if (counter == 0) {
      output <- data.frame(S2 = rowSums(dataset[, grepl(x = names(dataset), pattern = i)]))
      counter <- counter + 1
      names(output)[names(output) == "S2"] <- i
      next
  }
    output <- cbind(output, S2 = rowSums(dataset[, grepl(x = names(dataset), pattern = i)]))
    names(output)[names(output) == "S2"] <- i   }
  return(output)
}

MakeDGEList <- function(dataset, primerData) {
  samples <- primerData$Samples
  forwardSamples <- primerData$ForwardC
  datasetDF <- as.data.frame(t(dataset))
  if (any(grepl("outRev", forwardSamples))) {
    dfAll <- DFCombine(datasetDF, samples)
    yAll <- edgeR::DGEList(dfAll)
  }   else {
    yAll <- edgeR::DGEList(datasetDF)
  }
  return(yAll)
}

ExportFasta <- function(countData, fileName, minLength = 50, maxLength = 1000) {
  seqs <- row.names(countData)
  names(seqs) <- paste("Seq", 1:length(seqs), sep = "_")
  seqs <- seqs[nchar(seqs) >= minLength]
  seqs <- seqs[nchar(seqs) <= maxLength]
  Biostrings::writeXStringSet(DNAStringSet(seqs, use.names = TRUE), fileName)
  sprintf("Wrote %s sequences to %s", length(seqs), fileName)
}

# Collect sample paths and names. Duplicate line once per primer:
projId <- "XYZ"
primer1 <- CollectData("./Filtered_data", prefix = "mifish")
saveRDS(primer1, file = "primer1.rds")
#primer2 <- CollectData("./Filtered_data", prefix = "v16s")
#saveRDS(primer2, file = "primer2.rds")

# Filter reads and generate out object for later use:
out <- FiltTrimWrap(primer1)
saveRDS(out, file = "out.rds")
#out2 <- FiltTrimWrap(primer2)
#saveRDS(out2, file = "out2.rds")

# Dereplicate and merge pairs with dada2:
dada2Counts <- DadaAnalysis(primer1, justConcatenate = FALSE, minOverlap = 5)
saveRDS(dada2Counts, file = "dada2Counts.rds")
#dada2Counts2 <- DadaAnalysis(primer2, justConcatenate = FALSE, minOverlap = 5)
#saveRDS(dada2Counts2, file = "dada2Counts2.rds")

# Convert and modify matrix "dada2Counts" to DGEList "yAll":
yAll <- MakeDGEList(dada2Counts, primer1)
saveRDS(yAll, file = "yAll.rds")
#yAll2 <- MakeDGEList(dada2Counts2, primer2)
#saveRDS(yAll2, file = "yAll2.rds")

# Export fasta-file:
ExportFasta(yAll, paste0("y_", projId, primer1$Prefix, ".fa"), minLength = 30, maxLength = 1000)
#ExportFasta(yAll2, paste0("y_", projId, primer2$Prefix, ".fa"), minLength = 30, maxLength = 1000)
