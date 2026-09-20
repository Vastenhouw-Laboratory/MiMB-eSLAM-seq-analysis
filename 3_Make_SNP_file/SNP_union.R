rm(list=ls())

library(data.table)
library("ggVennDiagram")
library("ggvenn")

print("NOTE: Some SNP locations occur multiple times, and the min-coverage is actually 5 and not 20. Manual filtering was therefore necessary.")
print("samtools uses 1-based coordinates, while the filtering script requires 0-based coordinates. Conversion performed.")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("Usage: SNP_union.R <control-filelist> <output-file> <minimum-coverage>")
}

input <- paste0(readLines(args[1], warn = FALSE), ".varscan.snp")
input <- input[nzchar(input)]
if (length(input) != 4) {
  stop("The control file list must contain exactly four sample names")
}
output <- args[2]
minimum_coverage <- as.numeric(args[3])
SNP_ID <- data.frame()

for (inp in input)
{
  print(paste0("load input file ", inp))
  TABLE<-fread(inp, sep="\t", header = TRUE)
  TABLE <- TABLE[which((TABLE$Reads1 + TABLE$Reads2) >= minimum_coverage),]
  print(paste0("number of rows in file 1: ", nrow(TABLE)))
  
  SNP <- paste0(TABLE$Chrom, ":" ,(TABLE$Position-1))
  SNP <- unique(SNP)
  print(length(SNP))
  SNP <- cbind(SNP, Sample = inp)
  SNP_ID <- rbind(SNP_ID, SNP)
}

print("Make Venn Diagrams")

x <- list(
  A = SNP_ID$SNP[which(SNP_ID$Sample == input[1])],
  B = SNP_ID$SNP[which(SNP_ID$Sample == input[2])],
  C = SNP_ID$SNP[which(SNP_ID$Sample == input[3])],
  D = SNP_ID$SNP[which(SNP_ID$Sample == input[4])]
)
pdf("venn_diagrams_SNP.pdf", width = 7, height = 7)
ggVennDiagram(x, label_alpha = 0, category.names = c("Stage A","Stage B","Stage C", "Stage D"))
ggVennDiagram(x[1:3], label_alpha = 0, category.names = c("Stage A","Stage B","Stage C"))
names(x) <- c("Stage A","Stage B","Stage C", "Stage D")
ggvenn(x, fill_color = c("#0073C2FF", "#EFC000FF", "#868686FF", "#CD534CFF"), stroke_size = 0.5, set_name_size = 4)
ggvenn(x, columns = c("Stage A", "Stage B", "Stage C"),stroke_size = 0.5)
dev.off()

print("Selecting only the unique SNPs")
SNP <- unique(SNP_ID$SNP)
SNP <- as.data.frame(SNP)
colnames(SNP) <- "Location"
nrow(SNP)

print(paste0("write output file: ", output))
write.table(SNP, output, quote=FALSE, sep="\t", row.names=FALSE, col.names=TRUE)
print("R script finished succesfully!")
