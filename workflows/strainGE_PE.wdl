version 1.0

import "../tasks/strainGE.wdl" as strainge

workflow strainge_pe {

    meta {
        description: "Strain-level detection and variant calling with StrainGE for paired-end reads."
    }
    input {
        String sample_id
        File clean_reads_1
        File clean_reads_2
        Int db_kmer_size
        File straingst_reference
        File straingst_similarities
        File straingst_ref_fastas_dir
        Array[File] straingst_ref_fastas_files 
        # This forces cromwell to mount the FASTA files inside the directory,
        # but the variable is not used in the workflow
    }
    call strainge.StrainGE_PE {
        input:
            sample_name = sample_id,
            reads_1 = clean_reads_1,
            reads_2 = clean_reads_2,
            kmer_size = db_kmer_size,
            straingst_reference_db = straingst_reference,
            straingst_reference_fastas = straingst_ref_fastas_dir,
            straingst_reference_similarities = straingst_similarities,
            straingst_reference_fastas_files = straingst_ref_fastas_files
    }
    output {
        File straingst_kmerized_reads = StrainGE_PE.straingst_kmerized_reads
        File straingst_reference_db_used = StrainGE_PE.straingst_reference_db_used
        File straingst_strains = StrainGE_PE.straingst_strains
        File straingst_statistics = StrainGE_PE.straingst_statistics
        File straingr_concat_fasta = StrainGE_PE.straingr_concat_fasta
        File straingr_read_alignment = StrainGE_PE.straingr_read_alignment
        File straingr_variants = StrainGE_PE.straingr_variants
        File straingr_report = StrainGE_PE.straingr_report
        String strainge_docker = StrainGE_PE.strainge_docker
        String strainge_version = StrainGE_PE.strainge_version
    }
}