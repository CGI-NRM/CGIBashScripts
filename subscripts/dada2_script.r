library(dada2)
library(edgeR)

CollectData <- function(directory = "./Filtered_data") {
  forward <- list.files(directory, pattern = "_1.fastq.gz", full.names = TRUE)
  reverse <- list.files(directory, pattern = "_2.fastq.gz", full.names = TRUE)
  forwardC <- list.files(directory, pattern = "_1.fastq.gz", full.names = FALSE)
  reverseC <- list.files(directory, pattern = "_2.fastq.gz", full.names = FALSE)
  filtFs <- file.path(directory, "filtered", forwardC)
  filtRs <- file.path(directory, "filtered", reverseC)
  allSamples <- unique(gsub("_outFwd_1.fastq.gz|_outRev_1.fastq.gz", "", forwardC))
  output <- list(Forward = forward,
		 Reverse = reverse,
		 ForwardC = forwardC,
		 ReverseC = reverseC,
		 FiltFs = filtFs,
		 FiltRs = filtRs,
		 Samples = allSamples)
  return(output)
}

# Collect sample paths and names. Duplicate line once per primer:
primer1 <- CollectData("./Filtered_data")

# Filter reads and generate out object for later use:
out <- dada2::filterAndTrim(primer1$Forward, primer1$FiltFs,
			    primer1$Reverse, primer1$FiltRs,
			    maxN=0, truncQ=2, rm.phix=TRUE,
			    compress=TRUE, multithread=TRUE)
saveRDS(out, file = "out.rds")

# Dereplicate and merge pairs with dada2:
DadaAnalysis <- function(forward, reverse, muThread = TRUE,  justConcatenate = FALSE, minOverlap = 5,  paired = TRUE) {
  errF <- dada2::learnErrors(forward, multithread = muThread)
  derepsF <- dada2::derepFastq(forward)
  dadaF <- dada2::dada(derepsF, err = errF, multithread = muThread)
  if(paired == TRUE) {
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

dada2Counts <- MetaBAnalysis::DadaAnalysis(primer1$FiltFs, primer1$FiltRs, justConcatenate = FALSE, minOverlap = 5, paired = TRUE)
saveRDS(dada2Counts, file = "dada2Counts.rds")

