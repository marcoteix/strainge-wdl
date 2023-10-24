version 1.0

task StrainGE_PE {
  input {
    String sample_name
    File reads_1
    File reads_2
    Int kmer_size
    File straingst_reference_db
    File straingst_reference_similarities
    File straingst_reference_fastas
    Array[File] straingst_reference_fastas_files
    # This forces cromwell to mount the FASTA files inside the directory,
    # but the variable is not used in the workflow
    String docker = "marcoteix/strainge:0.0.2"
    Int disk_size = 100
    Int cpus = 4
    Int memory = 16
  }
  parameter_meta {
    sample_name: "Sample ID."
    reads_1: "Input file containing clean reads."
    reads_2: "Input file containing clean reads."
    kmer_size: "K-mer sizes used to k-merize the input reads. Should match the value used in the construction of the reference database."
    straingst_reference_db: "HDF5 file containing the StrainGST reference database."
    straingst_reference_fastas: "Path to the directory containing all the FASTA files used to build the StrainGST database."
    straingst_kmerized_reads: "HDF5 file containing the k-merized input reads."
    straingst_reference_db_used: "HDF5 file containing the StrainGST reference database used."
    straingst_strains: "TSV file with the strains detected by StrainGST."
    straingst_statistics: "TSV file with StrainGST sample statistics."
    straingr_concat_fasta: "Concatenated FASTA file of all representative sequences in the StrainGST reference database."
    straingr_read_alignment: "BAM file with reads aligned to the closest reference."
    straingr_variants: "HDF5 file with variants detected by StrainGR."
    straingr_report: "Human readable TSV file with a summary of StrainGR results."
    strainge_docker: "StrainGE docker image."
    strainge_version: "StrainGE version."
    straingst_reference_similarities: "TSV with similarities between the sequences in the StrainGST reference database."
  }
  command <<<
    /opt/conda/envs/strainge/bin/strainge --version > VERSION.txt
    /opt/conda/envs/strainge/bin/straingst kmerize -k ~{kmer_size} -o ~{sample_name}_kmerized_reads.hdf5 ~{reads_1} ~{reads_2}
    /opt/conda/envs/strainge/bin/straingst run -O -o ~{sample_name}_straingst_results ~{straingst_reference_db} ~{sample_name}_kmerized_reads.hdf5
    /opt/conda/envs/strainge/bin/straingr prepare-ref -s ~{sample_name}_straingst_results.strains.tsv -p "~{straingst_reference_fastas}/{ref}" \
        -S ~{straingst_reference_similarities} -o ~{sample_name}_refs_concat.fasta
    /opt/conda/envs/strainge/bin/bwa index ~{sample_name}_refs_concat.fasta
    /opt/conda/envs/strainge/bin/bwa mem -I 300 -t 2 ~{sample_name}_refs_concat.fasta ~{reads_1} ~{reads_2} | /opt/conda/envs/strainge/bin/samtools sort -@ 2 -O BAM -o ~{sample_name}_straingr_alignment.bam
    /opt/conda/envs/strainge/bin/samtools index ~{sample_name}_straingr_alignment.bam
    /opt/conda/envs/strainge/bin/straingr call ~{sample_name}_refs_concat.fasta ~{sample_name}_straingr_alignment.bam --hdf5-out \
        ~{sample_name}_straingr_variants.hdf5 --summary ~{sample_name}_straingr.tsv --tracks all
  >>>
  output {
    File straingst_kmerized_reads = "~{sample_name}_kmerized_reads.hdf5"
    File straingst_reference_db_used ="~{straingst_reference_db}"
    File straingst_strains = "~{sample_name}_straingst_results.strains.tsv"
    File straingst_statistics = "~{sample_name}_straingst_results.stats.tsv"
    File straingr_concat_fasta = "~{sample_name}_refs_concat.fasta"
    File straingr_read_alignment = "~{sample_name}_straingr_alignment.bam"
    File straingr_variants = "~{sample_name}_straingr_variants.hdf5"
    File straingr_report = "~{sample_name}_straingr.tsv"
    String strainge_docker = "~{docker}"
    String strainge_version = read_string("VERSION.txt")
  }
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpus
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    maxRetries: 1
    preemptible: 0
  }
}