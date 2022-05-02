# This is the main entry point of the workflow.  This common workflow step generate the common next gen sequencing file types (.bam, .bam.bai).
# # After configuring, running snakemake -n in a clone of this repository should successfully execute a dry-run of the workflow.
# taken from https://github.com/snakemake-workflows

# The configfile allows for customization of snakemake run, directive given at the top of the file
configfile: "config/config.yaml"

import pandas as import pd
import os

# imports the "Run" column from the SraRunTable.csv
samples = pd.read_csv(config["samples"], sep=",", dtype = str).set_index("Run", drop=False)

# import the "comparisons" from the comparison.csv
groups=pd.read_csv(config["comparisons"], sep=",", drop=False)

rule STAR_align:
    input:
        genome=config["star_index"]
        files=lambda wildcards: expand("reads/{sample}_{num}.fastq.gz}", sample=samples.sample_name == wildcards.sample, num=[1,2])
        "reads/{sample}_1.fastq.gz" , "reads/{sample}_2.fastq.gz"
    params:
        path="reads/bam_files/{sample}_"
    resources:
        cpu=10,
        mem=lambda wildcard, attempt: attempt *120
    output:
        "results/bam_files/{sample}_Aligned.sortedByCoord.out.bam"
    shell:
        "STAR --twopassMode Basic --genomeDir {input.genome} --outTmpKeep None "
		"--readFilesIn {input.files} --readFilesCommand zcat "
		"--runThreadN {resources.cpu} --outSAMtype BAM SortedByCoordinate "
		"--outFileNamePrefix {params.path} --alignSJoverhangMin 8 "
		"--limitBAMsortRAM {resources.mem}000000000 --outSAMattributes All "
		"--quantMode GeneCounts""
